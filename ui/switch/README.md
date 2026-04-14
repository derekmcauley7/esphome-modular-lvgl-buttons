[← Back to main README](../../README.md)

# ui/switch

On/off tile for any toggleable entity. Short-click toggles. Tile color reflects current state.

Simple type — tile only, no detail page.

## Files

| File | Purpose |
|---|---|
| `local.yaml` | ESPHome switch component (defined in the same device YAML) |
| `remote.yaml` | Home Assistant entity — works with `switch.*`, `input_boolean.*`, `automation.*`, or any entity that supports `homeassistant.toggle` |

## Variables

| Variable | Required | Description |
|---|---|---|
| `uid` | ✅ | Unique identifier — must be unique across all tiles on the device |
| `entity_id` | ✅ | ESPHome switch ID (local) or HA entity string e.g. `"switch.garden_pump"` (remote) |
| `row` | ✅ | Grid row position (0-based) |
| `column` | ✅ | Grid column position (0-based) |
| `text` | ✅ | Label shown on tile |
| `icon` | ✅ | MDI glyph e.g. `$mdi_power` |
| `row_span` | — | Number of rows to span (default: `1`) |
| `column_span` | — | Number of columns to span (default: `1`) |
| `page_id` | — | Parent page ID to place the tile on (default: `main_page`) |

## Usage

```yaml
# Local — ESPHome switch component
pump_btn: !include
  file: esphome-modular-lvgl-buttons/ui/switch/local.yaml
  vars:
    uid: pump
    entity_id: garden_pump      # your switch: component id
    row: 0
    column: 0
    text: "Pump"
    icon: $mdi_water_pump

# Remote — Home Assistant switch
fan_btn: !include
  file: esphome-modular-lvgl-buttons/ui/switch/remote.yaml
  vars:
    uid: fan
    entity_id: "switch.bedroom_fan"
    row: 0
    column: 1
    text: "Fan"
    icon: $mdi_fan

# Remote — input_boolean
guest_mode_btn: !include
  file: esphome-modular-lvgl-buttons/ui/switch/remote.yaml
  vars:
    uid: guest_mode
    entity_id: "input_boolean.guest_mode"
    row: 0
    column: 2
    text: "Guest"
    icon: $mdi_account
```

## Notes

- The remote variant reads state via the `binary_sensor` homeassistant platform, which works for any HA entity with an `on`/`off` state.
- Toggle is sent via `homeassistant.toggle`, which is compatible with `switch`, `light`, `input_boolean`, `fan`, `automation`, and `group` domains.
