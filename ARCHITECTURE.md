# Architecture Guide

> This document is designed to help AI coding assistants and new contributors understand this codebase quickly. For user-facing documentation, see [README.md](README.md).

## What This Is

A **modular component library** for [ESPHome](https://esphome.io/) + [LVGL](https://lvgl.io/) that lets you build touchscreen smart home control panels on cheap ESP32 displays. Components are composed via ESPHome's YAML package system — users pick a hardware file, add buttons/pages, and deploy to a device connected to Home Assistant.

This is **not** a Python/JavaScript project. Everything is ESPHome YAML with occasional inline C++ lambdas.

## Directory Structure

```
esphome-modular-lvgl-buttons/
├── buttons/              # Reusable button components (9 types)
├── common/               # Shared infrastructure (WiFi, OTA, fonts, colors, theme, time)
├── pages/                # Full-page UI components (info, color picker, boot screen)
├── widgets/              # Composable UI widgets (swipe nav, flip clock)
├── hardware/             # Device-specific configs (display driver, touch, backlight, pinout)
├── sensors/              # Base sensor packages (WiFi signal, CPU temp, device info)
├── example_code/         # Ready-to-use example configs for each supported device
├── example_code_advanced/# Complex examples (weather, tides, solar, flip clock)
├── weather_homeassistant/# Weather forecast integration (direct HA action calls)
├── tides/                # NOAA tide data display
├── solar/                # Enphase solar monitoring integration
├── custom_components/    # Custom ESPHome components (NOAA tides)
├── homeassistant_config/ # HA-side scripts/templates needed by some features
├── testing/              # Config validation script
└── assets/               # Fonts and images
    ├── fonts/            # Nunito font files
    └── images/           # SVG/PNG assets
```

## Core Concepts

### The Package/Include System

The entire library is built on ESPHome's `packages:` and `!include` mechanism. A user's main YAML file composes a complete device by including packages:

```yaml
packages:
  hardware: !include esphome-modular-lvgl-buttons/hardware/guition-esp32-s3-4848s040.yaml
  colors:   !include esphome-modular-lvgl-buttons/common/color.yaml
  fonts:    !include esphome-modular-lvgl-buttons/common/fonts.yaml
  glyphs:   !include esphome-modular-lvgl-buttons/common/mdi_glyph_substitutions.yaml
  theme:    !include esphome-modular-lvgl-buttons/common/theme_style.yaml
  wifi:     !include esphome-modular-lvgl-buttons/common/wifi.yaml

  button_1: !include
    file: esphome-modular-lvgl-buttons/buttons/switch_button.yaml
    vars:
      uid: button_1
      row: 0
      column: 0
      text: Kitchen Light
      icon: $mdi_lightbulb
      entity_id: "switch.kitchen_light"
```

### The `uid` System

Every button instance requires a unique `uid` variable. This `uid` is used to generate unique LVGL widget IDs through string interpolation:

- `${uid}` — container widget ID
- `button_${uid}` — the button widget
- `icon_${uid}` — the icon label
- `label_${uid}` — the text label
- `widget_sensor_${uid}` — the HA binary sensor
- `slider_${uid}` — slider (dimmer/cover buttons)
- `brightness_${uid}` — brightness sensor (dimmer)

**Never reuse a `uid`** — it will cause LVGL ID conflicts and compilation errors.

### Page Extension with `!extend`

Buttons don't create their own pages. They extend an existing page using `!extend`:

```yaml
lvgl:
  pages:
    - id: !extend ${page_id | default("main_page")}
      widgets:
        - container:
            id: ${uid}
            grid_cell_row_pos: ${row}
            grid_cell_column_pos: ${column}
            # ... button content
```

This means the main YAML must define the base page first (typically in the `lvgl:` section at the bottom), and button packages append their widgets to it.

### Grid Layout

Pages use LVGL's grid layout system. The shorthand `layout: 4x4` creates a 4-column × 4-row grid. Buttons are placed using:

- `grid_cell_row_pos` / `grid_cell_column_pos` — 0-based position
- `grid_cell_row_span` / `grid_cell_column_span` — optional, defaults to 1
- `grid_cell_x_align: stretch` / `grid_cell_y_align: stretch` — fill the cell

### Variable Defaults

Variables use ESPHome's Jinja-like default syntax:

```yaml
${page_id | default("main_page")}   # Use "main_page" if page_id not provided
${row_span | default(1)}            # Use 1 if row_span not provided
${icon_color | default("$label_on_color")}  # Can reference substitution vars
```

## Button Component Anatomy

Every button file follows this pattern:

### 1. YAML Comment Header

Documents required and optional variables:

```yaml
---
# Switch (or light) toggle button
# vars:
#    uid:
#    page_id:
#    row:
#    column:
#    row_span:
#    column_span:
#    text:
#    icon:
#    entity_id:
```

### 2. LVGL Page Extension

Adds a container (with the button inside) to the target page's grid:

```yaml
lvgl:
  pages:
    - id: !extend ${page_id | default("main_page")}
      widgets:
        - container:
            id: ${uid}
            grid_cell_row_pos: ${row}
            grid_cell_column_pos: ${column}
            grid_cell_row_span: ${row_span | default(1)}
            grid_cell_column_span: ${column_span | default(1)}
            grid_cell_x_align: stretch
            grid_cell_y_align: stretch
            widgets:
              - button:
                  id: button_${uid}
                  widgets:
                    - label:
                        text_font: $icon_font
                        align: top_left
                        id: icon_${uid}
                        text: ${icon}
                    - label:
                        align: bottom_left
                        id: label_${uid}
                        text: ${text}
                  on_short_click:
                    # ... action
```

### 3. State Tracking (for HA-connected buttons)

Uses `binary_sensor` (for on/off entities) or `text_sensor` (for multi-state like covers) to track Home Assistant entity state and update button colors:

```yaml
binary_sensor:
  - id: widget_sensor_${uid}
    platform: homeassistant
    entity_id: ${entity_id}
    trigger_on_initial_state: true
    on_state:
      - if:
          condition:
            binary_sensor.is_on: widget_sensor_${uid}
          then:
            - lvgl.widget.update:
                id: button_${uid}
                bg_color: $button_on_color
            # ... update icon and label colors
          else:
            - lvgl.widget.update:
                id: button_${uid}
                bg_color: $button_off_color
            # ... update icon and label colors
```

## Available Button Types

| Button | File | HA Integration | Key Feature |
|--------|------|----------------|-------------|
| **Switch** | `buttons/switch_button.yaml` | `binary_sensor` + `homeassistant.toggle` | Simple on/off toggle |
| **Dimmer Light** | `buttons/dimmer_light_button.yaml` | `binary_sensor` + `light.turn_on` | Brightness slider, long-press opens color page |
| **Scene** | `buttons/scene_button.yaml` | `scene.turn_on` | Fire-and-forget, no state tracking |
| **Page** | `buttons/page_button.yaml` | None | Navigates to another LVGL page |
| **Time** | `buttons/time_button.yaml` | None | Displays current time, transparent button |
| **Local Relay** | `buttons/local_relay_button.yaml` | `light` platform (binary output) | Controls GPIO directly, no HA needed |
| **Cover** | `buttons/cover_button.yaml` | `text_sensor` + `cover.toggle/stop` | Position slider (auto-hidden for binary covers, shown when position data arrives), 4 visual states (open/opening/closing/closed) |
| **Sensor** | `buttons/sensor_button.yaml` | `sensor` (extends existing) | 2-column grid: icon + label + live data value |
| **Color Picker** | `buttons/color_picker.yaml` | HA script call | Color swatch, sends hex color to HA |

### Special Cases

- **`color_picker.yaml`** is structured differently — it provides raw LVGL widget properties meant to be inlined, not a complete `lvgl: pages:` package.
- **`sensor_button.yaml`** uses `!extend` on the sensor ID rather than creating a new one — the sensor must already exist.
- **`time_button.yaml`** uses `!extend time_update` to update its label automatically — the example file only needs a base `time_update` script with a NOOP lambda placeholder.
- **`local_relay_button.yaml`** uses an additional `ha_name` variable and `$entity_id` refers to an output pin ID, not an HA entity.

## Theme & Styling System

### Color Rule: Always Use Named Colors

**Always reference colors by name, never by hex value.** Two pools of named colors are available:

1. **Library colors** defined in `common/color.yaml` — custom colors specific to this project:
   - `burnt_sienna`, `very_dark_gray`, `ep_orange`, `ep_blue`, `ep_green`
   - Gray scale: `gray50` through `gray900` (Material-style, `gray50` is lightest)
   - Blues: `sky_blue`, `slate_blue_gray`, `steel_blue`, `misty_blue`, `dark_blue`
   - Core: `black`, `dark_gray`, `gray`, `light_gray`, `white`
   - Reds/pinks: `red`, `crimson`
   - Blues: `light_blue`, `blue`
   - Yellows: `yellow`, `light_yellow`, `amber`
   - Greens: `mint`, `light_mint`, `light_green`, `green`
   - Oranges: `orange`, `deep_orange`
   - Purples: `violet`, `deep_purple`

2. **ESPHome built-in CSS colors** — the standard RGB color table is available by default in ESPHome (no import needed). Examples: `aliceblue`, `coral`, `darkslategray`, `dodgerblue`, `forestgreen`, `gold`, `hotpink`, `indigo`, `khaki`, `limegreen`, `navy`, `orchid`, `salmon`, `teal`, `tomato`, `turquoise`, etc. The full list is commented out in `common/color.yaml` for reference.

Use these names directly in YAML — e.g., `bg_color: ep_orange`, `text_color: misty_blue`. Avoid raw hex like `bg_color: 0xFF6600`.

If you need a color that doesn't exist in either list, **define it as a substitution** in the file you're working on rather than using a raw hex value:

```yaml
substitutions:
  my_custom_teal: "0x1ABC9C"
```

Then reference it as `$my_custom_teal` throughout that file.

### Substitution Variables

The visual appearance is controlled entirely through ESPHome substitution variables defined in the user's main YAML:

```yaml
substitutions:
  # Fonts
  icon_font: mdi_icons_40        # Font ID for icons
  text_font: nunito_20           # Font ID for text labels

  # Button colors (on state)
  button_on_color: "ep_orange"
  icon_on_color: "yellow"
  label_on_color: "white"

  # Button colors (off state)
  button_off_color: "very_dark_gray"
  icon_off_color: "gray"
  label_off_color: "gray"
```

Color names refer to IDs defined in `common/color.yaml` (~50 named colors).

### Theme File (`common/theme_style.yaml`)

Sets LVGL-wide defaults:
- All widgets: scrollbars off, no borders, no padding
- Buttons: `radius: 25`, `shadow_width: 0`, `bg_color: $button_off_color`
- Defines `page_style` and `time_style` style definitions
- Includes a Dark/Light theme switcher via HA `select` entity

### Debug Theme (`common/theme_style_debug.yaml`)

Same as `theme_style.yaml` but with red outlines on all widgets for debugging layout issues.

## Icon System

Icons use Material Design Icons via substitution variables. The file `common/mdi_glyph_substitutions.yaml` defines ~6000+ substitutions:

```yaml
substitutions:
  mdi_lightbulb: "\U000F0335"
  mdi_home: "\U000F02DC"
  mdi_ceiling_light: "\U000F0769"
  # ... thousands more
```

Usage in button configs: `icon: $mdi_lightbulb`

The actual icon font must be included in the user's main YAML with the specific glyphs needed:

```yaml
font:
  - file: 'https://github.com/Templarian/MaterialDesign-Webfont/raw/v7.4.47/fonts/materialdesignicons-webfont.ttf'
    id: mdi_icons_40
    size: 40
    bpp: 8
    glyphs: [$mdi_lightbulb, $mdi_home, ...]
```

## Font System

`common/fonts.yaml` defines the Nunito font family at 9 sizes:
- IDs: `nunito_12`, `nunito_14`, `nunito_18`, `nunito_20`, `nunito_24`, `nunito_36`, `nunito_42`, `nunito_48`, `nunito_72`
- Source: `assets/fonts/Nunito-SemiBold.ttf`
- All at 8bpp color depth

## Hardware Layer

Each file in `hardware/` is a self-contained device config providing:
- `substitutions:` for `screen_width` and `screen_height`
- ESP-IDF framework config and PSRAM settings
- Display driver (st7701s, rpi_dpi_rgb, mipi_dsi, ili9xxx, etc.)
- Touch controller (gt911, cst816s, ft5x06, etc.)
- Backlight PWM (`display_backlight` light entity)
- I2C bus configuration
- Optional: audio/speaker/microphone pipelines

The main YAML includes this as a single package: `hardware: !include esphome-modular-lvgl-buttons/hardware/<device>.yaml`

## Pages

| Page | File | Purpose |
|------|------|---------|
| **Loading** | `pages/loading.yaml` | Boot screen with HA/ESPHome logos, spinner, connection status, auto-dismisses |
| **Info** | `pages/info.yaml` | System info: ESPHome version, build date, MAC, IP, SSID, WiFi strength, QR codes |
| **Light Color** | `pages/light_color.yaml` | Advanced light control: HSV arc, brightness/saturation sliders, color temp, auto-detects capabilities |

## Sensors

- `sensors/sensors_base.yaml` — Full sensor package: WiFi signal, CPU temp, device info, restart/factory-reset buttons, LVGL label updates
- `sensors/sensors_base-SDL.yaml` — Minimal version for SDL desktop testing (no WiFi/hardware sensors)

Both provide: `esphome_version`, `device_last_restart`, `device_name` text sensors, and update LVGL labels (`esphome_version_label`, `device_name_label`, `cp_login` QR code).

## Swipe Navigation

Add swipe gestures to any page using a YAML anchor merge:

```yaml
lvgl:
  pages:
    - id: my_page
      <<: !include esphome-modular-lvgl-buttons/widgets/swipe_navigation.yaml
```

## Time System

Two options (include one, not both):
- `common/time_homeassistant.yaml` — Syncs time from Home Assistant
- `common/time_sntp.yaml` — Uses NTP (for non-HA setups), also includes `sun:` and brightness mode scheduling

Both define `system_time` and invoke the `time_update` script every minute. The user's main YAML must define the `time_update` script.

**Note:** `common/backlight_time.yaml` is the recommended option — it bundles `time: homeassistant`, `sun:`, and the 3-mode brightness system (Day/Evening/Night) in one package. Use `time_sntp.yaml` only for standalone devices without Home Assistant. **Never combine `time_sntp.yaml` with `backlight_time.yaml`** — they both define `sun:` and `brightness_mode` scheduling and will conflict.

### Variable Naming Convention

All display/brightness substitution variables use the `display_*` prefix:
- `display_daytime_brightness`, `display_nighttime_brightness`
- `display_night_hour`, `display_night_minute`
- `display_day_hour`, `display_day_minute` (SNTP only)
- `display_backlight_timeout_initial`, `display_backlight_timeout_always_enabled`

## Backlight System (`common/backlight_time.yaml`)

3-mode brightness based on sun position:
- **Day**: Full brightness (after sunrise)
- **Evening**: Reduced brightness (after sunset)
- **Night**: Screen off when idle (after configurable hour)

Key substitution variables:
- `display_daytime_brightness`, `display_nighttime_brightness`
- `display_night_hour`, `display_night_minute`
- `display_backlight_timeout_initial` (minutes, -1 to disable)

## Advanced Feature Modules

### Weather (`weather_homeassistant/`)
Uses `weather.get_forecasts` HA action — no template sensors needed. Displays 4-day forecast with SVG weather icons.

### Tides (`tides/`)
NOAA tide data with gauge indicator, high/low tide times. Uses custom component in `custom_components/noaa_tides/`.

### Solar (`solar/`)
Enphase Envoy integration: production/consumption/import/export, battery SOC, 24h history charts via `recorder.get_statistics`.

## OTA System (`common/ota.yaml`)

Includes a full-screen OTA overlay with progress bar. References `lvgl_component` for forcing LVGL redraws during upload. Uses `$screen_width` and `$screen_height` from hardware substitutions.

## Testing

Run config validation:
```bash
cd /path/to/parent/directory  # directory containing esphome-modular-lvgl-buttons/
bash esphome-modular-lvgl-buttons/testing/test_configs.sh
```

This runs `esphome config` on every file in `example_code/` to verify YAML compilation.

## Known Issues & TODOs

1. **`shadow_width: 0`** in `theme_style.yaml` is explicitly set despite LVGL default being 0 — removing it causes visual issues.

## Creating a New Button Component

Follow this checklist:

1. Create a new file in `buttons/` with a descriptive name (e.g., `fan_button.yaml`)
2. Add the YAML comment header documenting all `vars:`
3. Use `!extend ${page_id | default("main_page")}` to add to the target page
4. Wrap in a `container` with `grid_cell_*` positioning using `${row}`, `${column}`, `${row_span | default(1)}`, `${column_span | default(1)}`
5. Use `${uid}` to generate all widget IDs: `button_${uid}`, `icon_${uid}`, `label_${uid}`, etc.
6. Add state tracking (`binary_sensor` or `text_sensor` from HA) that updates colors using `$button_on_color`/`$button_off_color` etc.
7. Use `$icon_font` for icon labels, `$text_font` for text labels
8. Test with SDL first: add the button to `example_code/SDL-lvgl-display_modular_480px.yaml` and run `esphome config`
