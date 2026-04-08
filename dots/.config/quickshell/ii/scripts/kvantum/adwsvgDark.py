import os
import re

from material_colors import load_material_colors

def update_svg_colors(svg_path, old_to_new_colors, output_path):
    """
    Updates the colors in an SVG file based on the provided color map.

    :param svg_path: Path to the SVG file.
    :param old_to_new_colors: Dictionary mapping old colors to new colors.
    :param output_path: Path to save the updated SVG file.
    """
    # Read the SVG content
    with open(svg_path, 'r') as file:
        svg_content = file.read()

    # Replace old colors with new colors
    for old_color, new_color in old_to_new_colors.items():
        svg_content = re.sub(old_color, new_color, svg_content, flags=re.IGNORECASE)

    # Write the updated SVG content to the output file
    with open(output_path, 'w') as file:
        file.write(svg_content)
    
    print(f"SVG colors have been updated and saved to {output_path}!")

def main():
    xdg_config_home = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    xdg_state_home = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))

    svg_path = os.path.join(xdg_config_home, "Kvantum", "Colloid", "ColloidDark.svg")
    output_path = os.path.join(xdg_config_home, "Kvantum", "MaterialAdw", "MaterialAdw.svg")

    color_data = load_material_colors(xdg_state_home)

    # Specify the old colors and map them to new colors from the SCSS file
    old_to_new_colors = {
        #'#525252': color_data['surfaceDim'],  # Map old SVG color to new SCSS color
        #'#666666': color_data['surfaceDim'],
        '#31363b': color_data['background'],
        #'#eff0f1': color_data['neutral_paletteKeyColor'],
        '#000000': color_data['shadow'],
        '#5b9bf8': color_data['primary'],
        '#93cee9': color_data['onSecondaryContainer'],
        '#3daee9': color_data['secondary'],
        #'#fff': color_data['term10'],
        #'#5a5a5a': color_data['surfaceVariant'],
        #'#acb1bc': color_data['onPrimaryFixed'],
        '#ffffff': color_data['term11'],
        '#5a616e': color_data['surfaceVariant'],
        '#f04a50': color_data['error'],
        '#4285f4': color_data['secondary'],
        '#242424': color_data['background'],
        '#2c2c2c': color_data['background'],
        #'#dfdfdf': color_data['onSurfaceVariant'],
        #'#646464': color_data['surfaceContainerHighest'],
        #'#989898': color_data['surfaceContainerHigh'],
        #'#c1c1c1': color_data['primaryFixedDim'],
        '#1e1e1e': color_data['background'],
        '#3c3c3c': color_data['background'],
        '#26272a': color_data['surfaceBright'],
        '#000000': color_data['shadow'],
        '#b74aff': color_data['tertiary'],
        #'#b6b6b6': color_data['onSurfaceVariant'],
        '#1a1a1a': color_data['background'],
        '#333': color_data['term0'],
        '#212121': color_data['background'],
    }

    # Update the SVG colors
    update_svg_colors(svg_path, old_to_new_colors, output_path)

if __name__ == "__main__":
    main()
