# Theme Bundle

Include `index.yaml` once in your device config to pull in the complete theme — colors, fonts, MDI icons, and LVGL styles.

```yaml
packages:
  theme: !include esphome-modular-lvgl-buttons/common/theme/index.yaml
```

For layout debugging (red outlines on all widgets), swap to `index_debug.yaml`.

---

## Customization

All appearance settings are substitution variables. All of them have defaults — only override what you need.

```yaml
substitutions:
  button_on_color:   ep_orange      # tile background when entity is ON
  button_off_color:  very_dark_gray # tile background when entity is OFF
  icon_on_color:     yellow         # icon color when ON
  icon_off_color:    gray           # icon color when OFF
  label_on_color:    white          # label text color when ON
  label_off_color:   gray           # label text color when OFF
  button_text_color: white          # secondary text (status line, values)
  icon_font:         mdi_icons_40   # font ID used for MDI icons
  text_font:         nunito_20      # font ID used for tile labels
```

The values must be color/font IDs — see the sections below.

---

## Available Colors

### Library colors (defined in `color.yaml`)

| ID | Hex | Preview |
|---|---|---|
| `ep_orange` | `#F37320` | primary brand orange |
| `ep_blue` | `#01B4DE` | brand blue |
| `ep_green` | `#7ACF38` | brand green |
| `very_dark_gray` | `#313131` | default OFF background |
| `burnt_sienna` | `#CC5E14` | dark orange |
| `sky_blue` | `#3FA7F3` | |
| `slate_blue_gray` | `#343645` | dark UI background |
| `steel_blue` | `#606682` | |
| `misty_blue` | `#9BA2BC` | |
| `black` | `#0D0D0D` | near-black |
| `dark_gray` | `#333333` | |
| `gray` | `#666666` | |
| `light_gray` | `#999999` | |
| `white` | `#F2F0EB` | warm white |
| `red` | `#FF0000` | |
| `crimson` | `#F5075C` | |
| `light_blue` | `#2FC0FF` | |
| `blue` | `#4C9FFF` | |
| `yellow` | `#E7C12C` | default icon ON color |
| `light_yellow` | `#F0D45C` | |
| `amber` | `#F4A900` | |
| `mint` | `#39D19C` | |
| `light_mint` | `#66DCB3` | |
| `green` | `#5CA848` | |
| `light_green` | `#00FF00` | |
| `orange` | `#F07C40` | |
| `deep_orange` | `#FF6600` | |
| `violet` | `#926BC7` | |
| `dark_blue` | `#4867AA` | |
| `deep_purple` | `#543D72` | |

Gray scale: `gray50` → `gray900` (lightest to darkest, matching Material Design scale)

### ESPHome built-in CSS colors

All standard CSS color names are available without declaration — `aliceblue`, `coral`, `dodgerblue`, `forestgreen`, `teal`, `salmon`, etc.
See [MDN color names](https://developer.mozilla.org/en-US/docs/Web/CSS/named-color) for the full list.

---

## Available Fonts

Defined in `fonts.yaml` (Nunito, loaded from `assets/fonts/`):

| ID | Size |
|---|---|
| `nunito_12` | 12 px |
| `nunito_14` | 14 px |
| `nunito_18` | 18 px |
| `nunito_20` | 20 px ← default |
| `nunito_24` | 24 px |
| `nunito_36` | 36 px |
| `nunito_42` | 42 px |
| `nunito_48` | 48 px |
| `nunito_72` | 72 px |

Set `text_font` to any of these IDs.

---

## MDI Icons

`mdi_glyph_substitutions.yaml` provides 6000+ substitution variables like `$mdi_lightbulb`, `$mdi_ceiling_light`, `$mdi_thermostat`, etc.

Icons are referenced by substitution in component files and your device YAML:

```yaml
icon: $mdi_ceiling_light
```

The **font must declare the glyphs** your config uses. In your device YAML:

```yaml
font:
- file: 'https://github.com/Templarian/MaterialDesign-Webfont/raw/v7.4.47/fonts/materialdesignicons-webfont.ttf'
  id: mdi_icons_40
  size: 40
  bpp: 8
  glyphs:
  # detail pages (always required)
  - $mdi_brightness_6
  - $mdi_chevron_up
  - $mdi_circle_opacity
  - $mdi_eyedropper
  - $mdi_lightbulb
  - $mdi_arrow_oscillating
  - $mdi_chevron_left
  - $mdi_thermostat
  - $mdi_water_percent
  - $mdi_information_box
  # your tile icons
  - $mdi_ceiling_light
  - $mdi_fan
  - $mdi_thermometer
```

Omitting a glyph that gets rendered causes a compile error. Add every icon used by your tiles and any detail pages you include.

---

## Example — Custom Dark Blue Theme

```yaml
substitutions:
  screen_width:  "480"
  screen_height: "480"
  button_on_color:   steel_blue
  button_off_color:  slate_blue_gray
  icon_on_color:     light_blue
  icon_off_color:    misty_blue
  label_on_color:    white
  label_off_color:   misty_blue

packages:
  theme: !include esphome-modular-lvgl-buttons/common/theme/index.yaml
  # ... rest of your config
```
