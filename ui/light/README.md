[← Back to main README](../../README.md)

# ui/light

Full RGB / CCT / brightness tile for a light entity. Short-click toggles on/off. Long-press opens a detail page with brightness slider, hue arc, saturation slider, and color temperature arc.

Capabilities (RGB, CCT, brightness-only) are **detected at runtime** — never declared by the user.

## Files

| File | Purpose |
|---|---|
| `local.yaml` | ESPHome light component (defined in the same device YAML) |
| `remote.yaml` | Home Assistant light entity |
| `detail.yaml` | Shared detail page — included automatically, do not include directly |

## Variables

| Variable | Required | Description |
|---|---|---|
| `uid` | ✅ | Unique identifier — must be unique across all tiles on the device |
| `entity_id` | ✅ | ESPHome light ID (local) or HA entity string e.g. `"light.kitchen"` (remote) |
| `row` | ✅ | Grid row position (0-based) |
| `column` | ✅ | Grid column position (0-based) |
| `text` | ✅ | Label shown on tile and detail page header |
| `icon` | ✅ | MDI glyph e.g. `$mdi_ceiling_light` |
| `row_span` | — | Number of rows to span (default: `1`) |
| `column_span` | — | Number of columns to span (default: `1`) |
| `page_id` | — | Parent page ID to place the tile on (default: `main_page`) |

## Usage

```yaml
# Local — ESPHome light component
desk_lamp_btn: !include
  file: esphome-modular-lvgl-buttons/ui/light/local.yaml
  vars:
    uid: desk_lamp
    entity_id: desk_lamp        # your light: component id
    row: 0
    column: 0
    text: "Desk"
    icon: $mdi_lamp

# Remote — Home Assistant light entity
ceiling_btn: !include
  file: esphome-modular-lvgl-buttons/ui/light/remote.yaml
  vars:
    uid: ceiling
    entity_id: "light.ceiling"
    row: 0
    column: 1
    text: "Ceiling"
    icon: $mdi_ceiling_light
```

## Supported light types

| ESPHome platform | Detected capability | Detail page UI |
|---|---|---|
| `binary` | none | toggle only |
| `monochromatic` | brightness | brightness slider |
| `rgb` | RGB | hue arc + saturation slider + brightness |
| `color_temperature` | CCT | color temp arc + brightness |
| `rgbww` / `rgbct` | RGB + CCT | all controls + RGB↔CCT mode toggle |

For remote lights, capabilities are parsed from the `supported_color_modes` HA attribute.

## Required glyphs

Make sure these glyphs are declared in your device `font:` block:

```
$mdi_brightness_6   $mdi_circle_opacity   $mdi_lightbulb
$mdi_chevron_up     $mdi_eyedropper
```
