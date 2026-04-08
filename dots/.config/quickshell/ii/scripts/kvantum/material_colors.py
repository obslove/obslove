import json
import os
import re


def snake_to_camel(name):
    parts = name.split("_")
    return parts[0] + "".join(part[:1].upper() + part[1:] for part in parts[1:])


def camel_to_snake(name):
    return re.sub(r"(?<!^)([A-Z])", r"_\1", name).lower()


def _add_aliases(colors, key, value):
    colors[key] = value
    if "_" in key:
        colors[snake_to_camel(key)] = value
    else:
        colors[camel_to_snake(key)] = value


def _set_term_color(colors, term_name, *candidates):
    for candidate in candidates:
        value = colors.get(candidate)
        if isinstance(value, str) and re.fullmatch(r"#[0-9A-Fa-f]{6}", value):
            _add_aliases(colors, term_name, value)
            return


def _derive_term_colors_from_material(colors):
    _set_term_color(colors, "term0", "background")
    _set_term_color(colors, "term1", "error")
    _set_term_color(colors, "term2", "primary")
    _set_term_color(colors, "term3", "secondary")
    _set_term_color(colors, "term4", "tertiary")
    _set_term_color(colors, "term5", "primaryContainer")
    _set_term_color(colors, "term6", "secondaryContainer")
    _set_term_color(colors, "term7", "onSurface")
    _set_term_color(colors, "term8", "outlineVariant")
    _set_term_color(colors, "term9", "errorContainer")
    _set_term_color(colors, "term10", "primaryFixedDim", "primary")
    _set_term_color(colors, "term11", "secondaryFixedDim", "secondary")
    _set_term_color(colors, "term12", "tertiaryFixedDim", "tertiary")
    _set_term_color(colors, "term13", "primaryFixed", "primaryContainer")
    _set_term_color(colors, "term14", "secondaryFixed", "secondaryContainer")
    _set_term_color(colors, "term15", "inverseSurface", "onBackground", "onSurface")


def load_material_colors(xdg_state_home=None):
    xdg_state_home = xdg_state_home or os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
    xdg_config_home = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    generated_dir = os.path.join(xdg_state_home, "quickshell", "user", "generated")
    scss_file = os.path.join(generated_dir, "material_colors.scss")
    json_file = os.path.join(generated_dir, "colors.json")
    config_file = os.path.join(xdg_config_home, "illogical-impulse", "config.json")
    colors = {}
    prefer_json = False

    if os.path.exists(config_file):
        try:
            with open(config_file, "r") as file:
                palette_type = json.load(file).get("appearance", {}).get("palette", {}).get("type", "")
            prefer_json = bool(palette_type) and str(palette_type) != "auto" and not str(palette_type).startswith("scheme-")
        except Exception:
            prefer_json = False

    def load_scss():
        if os.path.exists(scss_file) and os.path.getsize(scss_file) > 0:
            with open(scss_file, "r") as file:
                for line in file:
                    match = re.match(r"\$(\w+):\s*(#[0-9A-Fa-f]{6});", line.strip())
                    if match:
                        variable_name, color = match.groups()
                        _add_aliases(colors, variable_name, color)
            return True
        return False

    def load_json_colors():
        if os.path.exists(json_file) and os.path.getsize(json_file) > 0:
            with open(json_file, "r") as file:
                json_colors = json.load(file)
            for key, value in json_colors.items():
                if isinstance(value, str) and re.fullmatch(r"#[0-9A-Fa-f]{6}", value):
                    _add_aliases(colors, key, value)
            return True
        return False

    if prefer_json:
        load_json_colors() or load_scss()
    else:
        load_scss() or load_json_colors()

    scheme_base_file = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "colors", "terminal", "scheme-base.json"))
    if prefer_json:
        _derive_term_colors_from_material(colors)
    elif os.path.exists(scheme_base_file):
        mode = "light"
        current_mode = os.popen("gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null").read()
        if "prefer-dark" in current_mode:
            mode = "dark"
        with open(scheme_base_file, "r") as file:
            scheme_base = json.load(file)
        for key, value in scheme_base.get(mode, {}).items():
            if isinstance(value, str) and re.fullmatch(r"#[0-9A-Fa-f]{6}", value):
                _add_aliases(colors, key, value)

    if not colors:
        raise FileNotFoundError("No generated material colors found in material_colors.scss or colors.json")

    return colors
