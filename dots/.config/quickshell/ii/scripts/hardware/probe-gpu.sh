#!/usr/bin/env bash

set -u

read_first() {
    local path="$1"
    tr -d '[:space:]' < "$path" 2>/dev/null
}

read_temp_input() {
    local dev_path="$1"
    local temp_file

    for temp_file in \
        "$dev_path"/hwmon/hwmon*/temp1_input \
        "$dev_path"/hwmon/hwmon*/device/temp1_input
    do
        if [ -r "$temp_file" ]; then
            cat "$temp_file" 2>/dev/null
            return 0
        fi
    done

    printf '%s\n' ""
}

to_celsius() {
    local raw_value="${1:-}"

    if [[ "$raw_value" =~ ^[0-9]+$ ]]; then
        printf '%s\n' "$((raw_value / 1000))"
    else
        printf '%s\n' "-1"
    fi
}

emit_metrics() {
    local usage="$1"
    local temperature="$2"
    local memory_used_mb="$3"
    local memory_total_mb="$4"
    local model="${5:-}"

    printf '%s,%s,%s,%s,%s\n' "$usage" "$temperature" "$memory_used_mb" "$memory_total_mb" "$model"
}

fallback_gpu_name() {
    local vendor="${1:-}"

    case "$vendor" in
        0x1002)
            printf '%s\n' "AMD Radeon"
            ;;
        0x8086)
            printf '%s\n' "Intel Graphics"
            ;;
        0x10de)
            printf '%s\n' "NVIDIA GPU"
            ;;
        *)
            printf '%s\n' "Unknown GPU"
            ;;
    esac
}

resolve_gpu_name() {
    local dev_path="$1"
    local vendor="$2"
    local slot line name=""

    slot=$(basename "$(readlink -f "$dev_path")")

    if command -v lspci >/dev/null 2>&1 && [ -n "$slot" ]; then
        line=$(lspci -s "$slot" 2>/dev/null | head -n1)
        if [ -n "$line" ]; then
            name=$(printf '%s\n' "$line" | sed -E 's/^[0-9A-Fa-f:.]+[[:space:]]+[^:]+:[[:space:]]+//; s/[[:space:]]+\(rev .*$//')

            if [[ "$name" =~ \[([^\]]+)\][[:space:]]*$ ]]; then
                name="${BASH_REMATCH[1]}"
            else
                name=$(printf '%s\n' "$name" | sed -E 's/^(NVIDIA Corporation|Intel Corporation|Advanced Micro Devices, Inc\. \[AMD\/ATI\]|AMD\/ATI|Advanced Micro Devices, Inc\.)[[:space:]]+//')
            fi
        fi
    fi

    if [ -n "$name" ]; then
        printf '%s\n' "$name"
        return 0
    fi

    fallback_gpu_name "$vendor"
}

probe_amd() {
    local card_path="$1"
    local dev_path="$2"
    local vendor="$3"
    local usage temp_raw temperature memory_used memory_total model

    [ -r "$dev_path/gpu_busy_percent" ] || return 1

    usage=$(read_first "$dev_path/gpu_busy_percent")
    temp_raw=$(read_temp_input "$dev_path")
    temperature=$(to_celsius "$temp_raw")

    if [ -r "$dev_path/mem_info_vram_used" ] && [ -r "$dev_path/mem_info_vram_total" ]; then
        memory_used=$(read_first "$dev_path/mem_info_vram_used")
        memory_total=$(read_first "$dev_path/mem_info_vram_total")
        memory_used=$((memory_used / 1024 / 1024))
        memory_total=$((memory_total / 1024 / 1024))
    else
        memory_used=0
        memory_total=1
    fi

    model=$(resolve_gpu_name "$dev_path" "$vendor")

    emit_metrics "$usage" "$temperature" "$memory_used" "$memory_total" "$model"
    return 0
}

probe_intel() {
    local card_path="$1"
    local dev_path="$2"
    local vendor="$3"
    local busy_file="" usage temp_raw temperature model
    local candidate

    for candidate in \
        "$dev_path/gt_busy_percent" \
        "$card_path/gt_busy_percent" \
        "$card_path/gt/gt0/busy"
    do
        if [ -r "$candidate" ]; then
            busy_file="$candidate"
            break
        fi
    done

    [ -n "$busy_file" ] || return 1

    usage=$(read_first "$busy_file")
    temp_raw=$(read_temp_input "$dev_path")
    temperature=$(to_celsius "$temp_raw")
    model=$(resolve_gpu_name "$dev_path" "$vendor")

    emit_metrics "$usage" "$temperature" "0" "1" "$model"
    return 0
}

probe_card() {
    local card_path="$1"
    local dev_path="$card_path/device"
    local vendor

    [ -d "$dev_path" ] || return 1
    vendor=$(read_first "$dev_path/vendor")

    case "$vendor" in
        0x1002)
            probe_amd "$card_path" "$dev_path" "$vendor"
            ;;
        0x8086)
            probe_intel "$card_path" "$dev_path" "$vendor"
            ;;
    esac

    return 1
}

score_card() {
    local card_path="$1"
    local dev_path="$card_path/device"
    local vendor="$2"
    local score=0
    local vram_total=""

    case "$vendor" in
        0x1002)
            score=200
            if [ -r "$dev_path/mem_info_vram_total" ]; then
                vram_total=$(read_first "$dev_path/mem_info_vram_total")
                if [[ "$vram_total" =~ ^[0-9]+$ ]] && [ "$vram_total" -gt 0 ]; then
                    score=300
                fi
            fi
            ;;
        0x8086)
            score=100
            ;;
        *)
            score=50
            ;;
    esac

    if [ -r "$dev_path/boot_vga" ] && [ "$(read_first "$dev_path/boot_vga")" = "1" ]; then
        score=$((score + 10))
    fi

    printf '%s\n' "$score"
}

probe_nvidia() {
    local line name

    command -v nvidia-smi >/dev/null 2>&1 || return 1
    line=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1)
    [[ "$line" =~ ^[0-9]+[[:space:]]*,[[:space:]]*[0-9]+[[:space:]]*,[[:space:]]*[0-9]+[[:space:]]*,[[:space:]]*[0-9]+$ ]] || return 1

    name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n1)
    emit_metrics "${line%%,*}" "$(printf '%s' "$line" | cut -d',' -f2 | xargs)" "$(printf '%s' "$line" | cut -d',' -f3 | xargs)" "$(printf '%s' "$line" | cut -d',' -f4 | xargs)" "$name"
    return 0
}

main() {
    local card_path vendor
    local best_metrics="" best_score=-1
    local metrics score

    metrics=$(probe_nvidia 2>/dev/null || true)
    if [ -n "$metrics" ]; then
        best_metrics="$metrics"
        best_score=400
    fi

    for card_path in /sys/class/drm/card[0-9]*; do
        [ -r "$card_path/device/vendor" ] || continue
        vendor=$(read_first "$card_path/device/vendor")
        metrics=$(probe_card "$card_path" 2>/dev/null || true)
        [ -n "$metrics" ] || continue
        score=$(score_card "$card_path" "$vendor")
        if [ "$score" -gt "$best_score" ]; then
            best_metrics="$metrics"
            best_score="$score"
        fi
    done

    [ -n "$best_metrics" ] && printf '%s\n' "$best_metrics"
}

main
