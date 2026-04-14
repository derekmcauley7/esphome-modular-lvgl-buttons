# ARCHITECTURE.md — esphome-modular-lvgl-buttons (fork)

> For AI assistant rules and coding conventions, see [CLAUDE.md](CLAUDE.md). For end-user setup, see [README.md](README.md).

## What This Is

A **modular component library** for [ESPHome](https://esphome.io/) + [LVGL](https://lvgl.io/) that lets you build touchscreen smart home control panels on cheap ESP32 displays. Components are composed via ESPHome's YAML package system — users pick a hardware file, add UI components, and deploy to a device connected to Home Assistant.

This is **not** a Python or JavaScript project. Everything is ESPHome YAML with occasional inline C++ lambdas.

---

## Directory Structure

```
esphome-modular-lvgl-buttons/
├── ui/                       # All UI components
│   ├── light/                #   local.yaml, remote.yaml, detail.yaml
│   ├── switch/               #   local.yaml, remote.yaml
│   ├── sensor/               #   local.yaml, remote.yaml
│   ├── binary_sensor/        #   local.yaml, remote.yaml
│   ├── text_sensor/          #   local.yaml, remote.yaml
│   ├── button/               #   local.yaml, remote.yaml
│   ├── climate/              #   local.yaml, remote.yaml, detail.yaml
│   ├── clock/                #   flip_clock.yaml
│   ├── weather/              #   today.yaml, forecast.yaml, assets/
│   ├── solar/                #   solar monitoring integration
│   └── tides/                #   NOAA tide clock (tide_update.yaml, NOAA_tide_update.yaml)
├── pages/                    # Global UI pages (upstream, untouched)
│   ├── loading.yaml          #   Boot screen with HA connection status
│   └── info.yaml             #   System info: IP, MAC, WiFi, ESPHome version
├── common/                   # Shared infrastructure
│   ├── wifi.yaml             #   WiFi configuration
│   ├── ota.yaml              #   OTA update overlay
│   ├── color.yaml            #   Named color palette
│   ├── fonts.yaml            #   Nunito font declarations
│   ├── mdi_glyph_substitutions.yaml  # MDI icon aliases
│   ├── theme_style.yaml      #   LVGL theme and page_style
│   ├── backlight_time.yaml   #   Day/night brightness control
│   ├── sensors_base.yaml     #   WiFi signal, CPU temp, restart buttons
│   ├── sensors_base_sdl.yaml #   Minimal SDL variant
│   ├── swipe_navigation.yaml #   Swipe gesture handler
│   ├── time_homeassistant.yaml
│   └── time_sntp.yaml
├── hardware/                 # Device-specific configs (display, touch, backlight)
├── example_code/             # Ready-to-use example configs per supported device
│   └── advanced/             #   Advanced integrations (solar, tides, weather, flip clock)
├── assets/                   # Fonts and images
│   ├── fonts/                #   Nunito, Roboto, Gluqlo font files
│   └── images/               #   SVG/PNG assets
└── testing/                  # Config validation script
```

---

## Core Concepts

### The Package / Include System

The entire library is built on ESPHome's `packages:` and `!include` mechanism. A user's main YAML composes a complete device by including packages:

```yaml
packages:
  wifi:     !include esphome-modular-lvgl-buttons/common/wifi.yaml
  theme:    !include esphome-modular-lvgl-buttons/common/theme/index.yaml
  hardware: !include esphome-modular-lvgl-buttons/hardware/guition-esp32-s3-4848s040.yaml

  kitchen_light: !include
    file: esphome-modular-lvgl-buttons/ui/light/remote.yaml
    vars:
      uid: kitchen_light
      entity_id: "light.kitchen"
      row: 0
      column: 0
      text: Kitchen
      icon: $mdi_ceiling_light
```

One `!include` per entity. All internal wiring (globals, scripts, detail page) is handled inside the component files.

### The `uid` System

Every button instance requires a unique `uid`. It is used as a prefix to generate all LVGL widget IDs, globals, and script names through string interpolation:

```
button_${uid}       — the LVGL button widget
icon_${uid}         — the icon label
label_${uid}        — the text label
slider_${uid}       — inline control (where applicable)
${uid}_is_on        — global tracking on/off state
${uid}_light_toggle — abstract action script
```

**Never reuse a `uid`** across button instances — it causes LVGL ID conflicts and compilation errors.

### Page Extension with `!extend`

Buttons don't create their own pages. They extend an existing page:

```yaml
lvgl:
  pages:
    - id: !extend ${page_id | default("main_page")}
      widgets:
        - container:
            grid_cell_row_pos: ${row}
            grid_cell_column_pos: ${column}
```

The main YAML must define the base page first. Button packages append their widgets to it.

### Grid Layout

Pages use LVGL's grid layout. The shorthand `layout: 3x3` creates a 3-column × 3-row grid. Buttons are placed with `grid_cell_row_pos`, `grid_cell_column_pos`, and optional span properties. All sizing within tiles uses LVGL alignment and percentage-based dimensions — never hardcoded pixel coordinates — so components work across all supported display sizes.

---

## The Component Architecture (New System)

This fork replaces the upstream flat button files with a structured, scalable system. Each entity type lives entirely within its own subfolder under `ui/`. See [CLAUDE.md](CLAUDE.md) for the full contract and coding rules.

### Structure Per Entity Type

```
ui/<type>/local.yaml     — tile widget for a locally-defined ESPHome entity
ui/<type>/remote.yaml    — tile widget for a Home Assistant entity
ui/<type>/detail.yaml    — full-screen detail UI (complex types only)
```

All three files for a type live together. `local.yaml` and `remote.yaml` are the public entry points — users `!include` only these. `detail.yaml` is an internal dependency pulled in via `packages:` inside the button files; it is never included directly by users.

### Local vs Remote

The `local` and `remote` variants share the same tile layout, globals, and detail page. They differ only in how they communicate with the entity:

- **local** — ESPHome native actions and `on_state` hooks
- **remote** — `homeassistant.action` calls and `homeassistant` platform sensors

This is enforced via the **abstract script contract**: each button file implements a fixed set of `${uid}_`-prefixed scripts that the detail page calls without knowing which transport is in use.

### Simple vs Complex Types

- **Simple** (switch, button) — tile only, no detail page. Short-click performs the action.
- **Complex** (light, climate, sensor) — tile plus a full-screen detail page opened via long-press. `detail.yaml` is included by both `local.yaml` and `remote.yaml` via `packages:`.

### Entity Type Status

| Type | Local | Remote | Detail Page |
|---|---|---|---|
| `light` | ✅ | ✅ | ✅ |
| `switch` | ✅ | ✅ | — |
| `sensor` | ✅ | ✅ | — (maybe later) |
| `binary_sensor` | ✅ | ✅ | — |
| `text_sensor` | ✅ | ✅ | — |
| `button` | ✅ | ✅ | — |
| `climate` | ✅ | ✅ | ✅ |

---

## Legacy Button Components

The upstream flat button files are present in the repository with a `_legacy` suffix and are considered **superseded**. New devices should use the `ui/` components. These files are not maintained as part of this fork.

| Legacy file | Replacement |
|---|---|
| `buttons/switch_button_legacy.yaml` | `ui/switch/local.yaml` or `ui/switch/remote.yaml` |
| `buttons/sensor_button_legacy.yaml` | `ui/sensor/local.yaml` or `ui/sensor/remote.yaml` |
| `buttons/dimmer_light_button.yaml` + `pages/light_color.yaml` | `ui/light/local.yaml` or `ui/light/remote.yaml` (single include) |
| `buttons/cover_button_legacy.yaml` | — (not planned) |
| `buttons/scene_button_legacy.yaml` | — (not planned) |
| `buttons/page_button_legacy.yaml` | — (not planned) |
| `buttons/time_button_legacy.yaml` | — (not planned) |

---

## Infrastructure (Unchanged from Upstream)

These modules are reused as-is and not modified by this fork.

### Common (`common/`)

| File | Purpose |
|---|---|
| `wifi.yaml` | WiFi configuration template |
| `ota.yaml` | Full-screen OTA overlay with progress bar |
| `backlight_time.yaml` | 3-mode brightness (Day/Evening/Night) based on sun position |
| `sensors_base.yaml` | WiFi signal, CPU temp, restart/factory-reset buttons |
| `sensors_base_sdl.yaml` | Minimal variant for SDL desktop testing |
| `swipe_navigation.yaml` | Adds swipe gestures to any page via `<<: !include` |
| `time_homeassistant.yaml` | Time sync from Home Assistant |
| `time_sntp.yaml` | Time sync via NTP (standalone, no HA) |

### Theme bundle (`common/theme/`)

Include `common/theme/index.yaml` once — it pulls in all four files below:

| File | Purpose |
|---|---|
| `color.yaml` | ~50 named colors + full CSS color table reference |
| `fonts.yaml` | Nunito font at 9 sizes (`nunito_12` → `nunito_72`) |
| `mdi_glyph_substitutions.yaml` | 6000+ MDI icon substitutions (`$mdi_lightbulb`, etc.) |
| `theme_style.yaml` | LVGL-wide defaults, `page_style`, button/label styles |
| `theme_style_debug.yaml` | Same but with red outlines on all widgets |
| `index.yaml` | Bundle: includes the four files above |
| `index_debug.yaml` | Bundle: uses `theme_style_debug.yaml` instead |

### Theme and Color Rules

Always reference colors by name — never by hex value. Two pools are available:

- **Library colors** defined in `common/color.yaml`: `ep_orange`, `steel_blue`, `misty_blue`, `very_dark_gray`, `ep_green`, `ep_blue`, and many more
- **ESPHome built-in CSS colors**: `aliceblue`, `coral`, `dodgerblue`, `forestgreen`, `teal`, etc.

Button appearance is controlled via substitution variables in the user's device YAML:

```yaml
substitutions:
  button_on_color:  "ep_orange"
  button_off_color: "very_dark_gray"
  icon_on_color:    "yellow"
  icon_off_color:   "gray"
  label_on_color:   "white"
  label_off_color:  "gray"
  icon_font:        mdi_icons_40
```

Component files always use these substitution vars — never hardcoded colors or font IDs.

### Hardware (`hardware/`)

Each file is a self-contained device config providing display driver, touch controller, backlight PWM, I2C bus, PSRAM, and framework settings. Included as a single package. Provides `$screen_width` and `$screen_height` substitutions used by OTA and other components.

Supported families: Guition, Sunton, Waveshare, Elecrow, LilyGo, Espressif dev kits, and SDL desktop simulation.

### Common (`common/`) — additional files

| File | Purpose |
|---|---|
| `sensors_base.yaml` | WiFi signal, CPU temp, restart/factory-reset buttons |
| `sensors_base_sdl.yaml` | Minimal variant for SDL desktop testing |
| `swipe_navigation.yaml` | Adds swipe gestures to any page via `<<: !include` |

### UI Feature Modules (`ui/`)

Beyond the core entity types, `ui/` also contains:

| Folder | Purpose |
|---|---|
| `ui/clock/flip_clock.yaml` | Gluqlo-style flip clock widget |
| `ui/weather/` | HA weather tile (`today.yaml`) and 4-day forecast (`forecast.yaml`) |
| `ui/solar/` | Enphase/solar production and consumption monitoring |
| `ui/tides/` | NOAA tide clock (`tide_update.yaml`) and NOAA API integration (`NOAA_tide_update.yaml`) |

---

## Icon System

Icons use Material Design Icons via substitution variables from `common/mdi_glyph_substitutions.yaml`. Usage: `icon: $mdi_lightbulb`. The actual font must be declared in the device YAML with the specific glyphs needed:

```yaml
font:
  - file: 'https://github.com/Templarian/MaterialDesign-Webfont/raw/v7.4.47/fonts/materialdesignicons-webfont.ttf'
    id: mdi_icons_40
    size: 40
    bpp: 8
    glyphs: [$mdi_lightbulb, $mdi_ceiling_light, ...]
```

---

## Testing

```bash
cd /path/to/parent/directory
bash esphome-modular-lvgl-buttons/testing/test_configs.sh
```

Runs `esphome config` on every file in `example_code/` to verify YAML compilation. Run this before committing any change.

Advanced examples live in `example_code/advanced/` and are not covered by the basic test script.

---

## SDL Desktop Development

Use the SDL hardware config to develop and test UI on a desktop (Linux/macOS) without flashing hardware:

```yaml
packages:
  hardware: !include esphome-modular-lvgl-buttons/hardware/SDL-lvgl.yaml
  sensors:  !include esphome-modular-lvgl-buttons/common/sensors_base_sdl.yaml
  swipe:    !include esphome-modular-lvgl-buttons/common/swipe_navigation.yaml
```

Then run `esphome run <your-config>.yaml`. A window opens simulating the touchscreen. This is the recommended first step before deploying to real hardware.
