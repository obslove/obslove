#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERMINAL_DIR="$STATE_DIR/user/generated/terminal"
APPLY_LOCK_DIR="$TERMINAL_DIR/.applycolor.lock"

term_alpha=100 #Set this to < 100 make all your terminals transparent
# sleep 0 # idk i wanted some delay or colors dont get applied properly
if [ ! -d "$STATE_DIR"/user/generated ]; then
  mkdir -p "$STATE_DIR"/user/generated
fi
cd "$CONFIG_DIR" || exit

colorlist=()
colorvalues=()
CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"

use_json_preferred() {
  [ -f "$CONFIG_FILE" ] || return 1
  local palette_type
  palette_type=$(jq -r '.appearance.palette.type // ""' "$CONFIG_FILE" 2>/dev/null)
  [[ -n "$palette_type" && "$palette_type" != "auto" && ! "$palette_type" =~ ^scheme- ]]
}

snake_to_camel() {
  local input="$1"
  local output=""
  local segment
  IFS='_' read -ra parts <<< "$input"
  output="${parts[0]}"
  for segment in "${parts[@]:1}"; do
    output+="${segment^}"
  done
  printf '%s\n' "$output"
}

is_hex_color() {
  [[ "$1" =~ ^#[A-Fa-f0-9]{6}$ ]]
}

add_color() {
  local name="$1"
  local value="$2"
  is_hex_color "$value" || return 0
  colorlist+=("\$$name")
  colorvalues+=("$value")
}

load_colors_from_scss() {
  local scss_file="$STATE_DIR/user/generated/material_colors.scss"
  [ -s "$scss_file" ] || return 1

  while IFS= read -r line; do
    [[ "$line" =~ ^\$[A-Za-z0-9_]+:\ #[A-Fa-f0-9]{6}\;$ ]] || continue
    local name="${line%%:*}"
    local value="${line##*: }"
    value="${value%;}"
    add_color "${name#\$}" "$value"
  done < "$scss_file"

  return 0
}

get_color_value() {
  local name="$1"
  local i
  for i in "${!colorlist[@]}"; do
    if [ "${colorlist[$i]}" = "\$$name" ]; then
      printf '%s\n' "${colorvalues[$i]}"
      return 0
    fi
  done
  return 1
}

first_color_value() {
  local name
  local value
  for name in "$@"; do
    value=$(get_color_value "$name" 2>/dev/null) || continue
    if is_hex_color "$value"; then
      printf '%s\n' "$value"
      return 0
    fi
  done
  return 1
}

set_color_value() {
  local name="$1"
  local value="$2"
  is_hex_color "$value" || return 1
  local i
  for i in "${!colorlist[@]}"; do
    if [ "${colorlist[$i]}" = "\$$name" ]; then
      colorvalues[$i]="$value"
      return 0
    fi
  done
  add_color "$name" "$value"
}

derive_term_colors_from_material() {
  set_color_value "term0"  "$(first_color_value background)"
  set_color_value "term1"  "$(first_color_value error)"
  set_color_value "term2"  "$(first_color_value primary)"
  set_color_value "term3"  "$(first_color_value secondary)"
  set_color_value "term4"  "$(first_color_value tertiary)"
  set_color_value "term5"  "$(first_color_value primaryContainer)"
  set_color_value "term6"  "$(first_color_value secondaryContainer)"
  set_color_value "term7"  "$(first_color_value onSurface)"
  set_color_value "term8"  "$(first_color_value outlineVariant)"
  set_color_value "term9"  "$(first_color_value errorContainer)"
  set_color_value "term10" "$(first_color_value primaryFixedDim primary)"
  set_color_value "term11" "$(first_color_value secondaryFixedDim secondary)"
  set_color_value "term12" "$(first_color_value tertiaryFixedDim tertiary)"
  set_color_value "term13" "$(first_color_value primaryFixed primaryContainer)"
  set_color_value "term14" "$(first_color_value secondaryFixed secondaryContainer)"
  set_color_value "term15" "$(first_color_value inverseSurface onBackground onSurface)"
}

load_colors_from_json() {
  local json_file="$STATE_DIR/user/generated/colors.json"
  local scheme_file="$SCRIPT_DIR/terminal/scheme-base.json"
  local mode="light"

  [ -s "$json_file" ] || return 1

  if gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | grep -q "prefer-dark"; then
    mode="dark"
  fi

  while IFS='=' read -r key value; do
    [ -n "$key" ] || continue
    add_color "$(snake_to_camel "$key")" "$value"
  done < <(jq -r 'to_entries[] | "\(.key)=\(.value)"' "$json_file")

  if use_json_preferred; then
    derive_term_colors_from_material
  elif [ -f "$scheme_file" ]; then
    while IFS='=' read -r key value; do
      [ -n "$key" ] || continue
      add_color "$key" "$value"
    done < <(jq -r --arg mode "$mode" '.[$mode] | to_entries[] | "\(.key)=\(.value)"' "$scheme_file")
  fi

  return 0
}

if use_json_preferred; then
  load_colors_from_json || load_colors_from_scss
else
  load_colors_from_scss || load_colors_from_json
fi

acquire_apply_lock() {
  local attempts=0
  mkdir -p "$TERMINAL_DIR"
  while ! mkdir "$APPLY_LOCK_DIR" 2>/dev/null; do
    sleep 0.05
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 200 ]; then
      echo "Timed out waiting for terminal color pipeline lock" >&2
      return 1
    fi
  done
  trap 'rmdir "$APPLY_LOCK_DIR" 2>/dev/null || true' EXIT
}

validate_rendered_template() {
  local rendered_file="$1"
  if grep -Eq '\$[A-Za-z][A-Za-z0-9_]*' "$rendered_file"; then
    echo "Refusing to publish terminal theme with unresolved placeholders" >&2
    return 1
  fi
}

apply_kitty() {  
  # Check if terminal escape sequence template exists
  if [ ! -f "$SCRIPT_DIR/terminal/kitty-theme.conf" ]; then
    echo "Template file not found for Kitty theme. Skipping that."
    return
  fi
  local target_file="$TERMINAL_DIR/kitty-theme.conf"
  local temp_file
  # Copy template
  mkdir -p "$TERMINAL_DIR"
  temp_file=$(mktemp "$target_file.XXXXXX")
  cp "$SCRIPT_DIR/terminal/kitty-theme.conf" "$temp_file"
  # Apply colors
  local escaped_name
  for i in "${!colorlist[@]}"; do
    escaped_name="${colorlist[$i]//\$/\\$}"
    sed -i "s/${escaped_name} #/${colorvalues[$i]#\#}/g" "$temp_file"
  done
  validate_rendered_template "$temp_file" || {
    rm -f "$temp_file"
    return 1
  }
  mv "$temp_file" "$target_file"

  # Reload
  if pidof kitty >/dev/null 2>&1; then
    kill -SIGUSR1 $(pidof kitty)
  fi
}

apply_anyterm() {
  # Check if terminal escape sequence template exists
  if [ ! -f "$SCRIPT_DIR/terminal/sequences.txt" ]; then
    echo "Template file not found for Terminal. Skipping that."
    return
  fi
  local target_file="$TERMINAL_DIR/sequences.txt"
  local temp_file
  # Copy template
  mkdir -p "$TERMINAL_DIR"
  temp_file=$(mktemp "$target_file.XXXXXX")
  cp "$SCRIPT_DIR/terminal/sequences.txt" "$temp_file"
  # Apply colors
  local escaped_name
  for i in "${!colorlist[@]}"; do
    escaped_name="${colorlist[$i]//\$/\\$}"
    sed -i "s/${escaped_name} #/${colorvalues[$i]#\#}/g" "$temp_file"
  done

  sed -i "s/\$alpha/$term_alpha/g" "$temp_file"
  validate_rendered_template "$temp_file" || {
    rm -f "$temp_file"
    return 1
  }
  mv "$temp_file" "$target_file"

  for file in /dev/pts/*; do
    if [[ $file =~ ^/dev/pts/[0-9]+$ ]]; then
      {
      cat "$target_file" >"$file"
      } & disown || true
    fi
  done
}

apply_term() {
  apply_kitty
  apply_anyterm
}

apply_qt() {
  sh "$CONFIG_DIR/scripts/kvantum/materialQT.sh"          # generate kvantum theme
  python "$CONFIG_DIR/scripts/kvantum/changeAdwColors.py" # apply config colors
}

if [ -f "$CONFIG_FILE" ]; then
  enable_terminal=$(jq -r '.appearance.wallpaperTheming.enableTerminal' "$CONFIG_FILE")
  if [ "$enable_terminal" = "true" ]; then
    acquire_apply_lock && apply_term
  fi
else
  echo "Config file not found at $CONFIG_FILE. Applying terminal theming by default."
  acquire_apply_lock && apply_term
fi

# apply_qt & # Qt theming is already handled by kde-material-colors
