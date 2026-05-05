# Sensor Button Tile Type

## Summary

A new `ui/sensor_button/` entity type that combines a live sensor value display with a timed toggle action. The tile shows a sensor reading (like the existing `sensor/` type) and triggers an action on press (like the existing `button/` type), with a configurable visual "active" state that auto-reverts after a set duration.

Primary use case: displaying a temperature while allowing a tap to trigger a heating boost script, but the design is generic — any sensor + any action.

## Files

```
ui/sensor_button/
  local.yaml    — reads an ESPHome sensor + triggers a local button on press
  remote.yaml   — reads a HA sensor + triggers a HA script/button on press
```

No detail page. This is a simple type (tile-only).

## Variables

| Variable | Type | Description |
|---|---|---|
| `uid` | string | Unique identifier — prefixes all IDs, globals, scripts |
| `entity_id` | string | Sensor source. ESPHome component ID (local) or HA entity e.g. `"sensor.living_room_temperature"` (remote) |
| `action_entity_id` | string | Action target. ESPHome button component ID (local) or HA entity e.g. `"script.boost_heating"` (remote) |
| `active_duration` | int | Minutes the tile stays visually "on" after press. Optional, default 30 |
| `unit` | string | Unit string appended to value, e.g. `"°C"`. Optional, default `""` |
| `precision` | int | Decimal places for value display. Optional, default 1 |
| `row` | int | Grid row on parent page |
| `column` | int | Grid column on parent page |
| `text` | string | Tile label |
| `icon` | glyph | MDI icon glyph |
| `row_span` | int | Optional, default 1 |
| `column_span` | int | Optional, default 1 |
| `page_id` | string | Parent page ID. Optional, default `main_page` |
| `label_font` | font | Font for the label. Optional |
| `sensor_font` | font | Font for the sensor value. Optional |

## Globals

| Global | Type | Initial | Description |
|---|---|---|---|
| `${uid}_current_value` | float | 0.0 | Current sensor reading |
| `${uid}_is_active` | bool | false | Whether the tile is in the visual "on" state |

## Tile Layout

Identical to the existing sensor tile:

- Icon: top-left
- Label: bottom-left
- Sensor value: top-right
- The button widget is clickable (unlike the sensor tile where `clickable: false`)

### Visual States

**Off (default):**
- Background: default button style (theme-controlled)
- Icon color: `$icon_off_color`
- Label color: `$label_off_color`
- Value color: `$label_on_color`

**Active:**
- Background: `$button_on_color`
- Icon color: `$icon_on_color`
- Label color: `$label_on_color`
- Value color: `$label_on_color`

## Behavior

### Press (toggle)

1. If `${uid}_is_active` is false:
   - Call the action (local: `button.press`, remote: `homeassistant.action`)
   - Set `${uid}_is_active` to true
   - Update tile colors to "active" state
   - Start a timer for `active_duration` minutes

2. If `${uid}_is_active` is true:
   - Call the action again
   - Set `${uid}_is_active` to false
   - Revert tile colors to "off" state
   - Cancel the timer

### Timer Expiry

- Set `${uid}_is_active` to false
- Revert tile colors to "off" state
- No action is called on expiry — this is visual-only revert

### Sensor Updates

- Continuously update the value label regardless of active/off state
- Sensor updates do not affect the active/off visual state

## Scripts

| Script | Responsibility |
|---|---|
| `${uid}_sync_state` | Update value label from `${uid}_current_value`. Update tile colors from `${uid}_is_active` |
| `${uid}_toggle_action` | Toggle `${uid}_is_active`, call the action, start/cancel timer, update visuals |
| `${uid}_timer_expired` | Revert `${uid}_is_active` to false, update visuals |

## Implementation Notes

### Timer Mechanism

ESPHome does not have a built-in countdown timer widget. The timer will be implemented using a delayed script execution:

- A script `${uid}_timer_expired` with a `delay` of `active_duration` minutes
- On activation: execute the timer script (it waits, then reverts)
- On deactivation: stop the timer script (cancelling the pending delay)
- ESPHome's `script.execute` / `script.stop` handles this cleanly

### Remote Variant (remote.yaml)

- Sensor: `homeassistant` platform sensor subscribing to `entity_id`
- Action: `homeassistant.action` calling `homeassistant.turn_on` with `action_entity_id` (same pattern as `button/remote.yaml`)

### Local Variant (local.yaml)

- Sensor: `!extend` on the existing ESPHome sensor component (same pattern as `sensor/local.yaml`)
- Action: `button.press` on the ESPHome button component (same pattern as `button/local.yaml`)
