[← Back to main README](../../README.md)

# ui/climate

Thermostat tile with full-screen detail page. Tile shows target temperature and reflects active mode color. Detail page has a large arc for target temperature, mode selector, fan speed selector, and swing mode selector.

Supported modes, fan speeds, and swing modes are detected at runtime from HA attributes (remote) or ESPHome climate traits (local) — no vars needed.

## Files

| File | Purpose |
|---|---|
| `local.yaml` | ESPHome climate component (defined in the same device YAML) |
| `remote.yaml` | Home Assistant climate entity |
| `detail.yaml` | Shared detail page — included automatically, do not include directly |

## Variables

| Variable | Required | Description |
|---|---|---|
| `uid` | ✅ | Unique identifier |
| `entity_id` | ✅ | ESPHome climate ID (local) or HA entity e.g. `"climate.living_room"` (remote) |
| `row` | ✅ | Grid row position (0-based) |
| `column` | ✅ | Grid column position (0-based) |
| `text` | ✅ | Label shown on tile |
| `icon` | — | MDI glyph (default: `$mdi_thermostat`) |
| `row_span` | — | Number of rows to span (default: `1`) |
| `column_span` | — | Number of columns to span (default: `1`) |
| `page_id` | — | Parent page ID (default: `main_page`) |

## Usage

```yaml
# Remote — Home Assistant climate entity
ac_tile: !include
  file: esphome-modular-lvgl-buttons/ui/climate/remote.yaml
  vars:
    uid: bedroom_ac
    entity_id: "climate.bedroom_ac"
    row: 0
    column: 1
    text: "Bedroom"
    icon: $mdi_air_conditioner

# Local — ESPHome climate component (e.g. pid_climate, bang_bang)
hvac_tile: !include
  file: esphome-modular-lvgl-buttons/ui/climate/local.yaml
  vars:
    uid: hvac
    entity_id: living_room_climate   # your climate: component id
    row: 0
    column: 0
    text: "Living Room"
```

## Required glyphs

Add to your device `font:` block:

```
$mdi_thermostat   $mdi_fan   $mdi_chevron_left
$mdi_arrow_oscillating   $mdi_water_percent
```

## Detail page layout

- **Arc** — drag to set target temperature (disabled when OFF / FAN_ONLY / DRY); command sent on finger release only
- **Target temp label** — large center label; shows `OFF` when mode is off, `low°-high°` in heat_cool mode, hidden in fan_only / dry mode
- **Current temp** — smaller label below target, in `misty_blue`
- **Mode status label** — shows HEATING / COOLING / IDLE above target temp
- **Top-left button** — opens swing mode dropdown (hidden if not supported)
- **Top-right button** — back to parent page
- **Bottom-left button** — opens mode dropdown (OFF / HEAT / COOL / AUTO / FAN / DRY)
- **Bottom-right button** — opens fan speed dropdown (AUTO / LOW / MED / HIGH), hidden if not supported
- **Tap outside dropdown** — dismisses dropdown

## Notes

- Arc temperature range is fetched at runtime from the climate entity — no `min_temp` / `max_temp` vars needed.
- Supported modes, fan speeds, and swing modes are detected at runtime. All mode/fan/swing buttons are hidden by default and revealed only if the entity supports them.
- The remote variant reads `temperature` for single-setpoint and `target_temp_low` / `target_temp_high` for heat_cool mode.
- The arc sends the temperature command only on finger release, preventing multiple rapid state updates while dragging.
