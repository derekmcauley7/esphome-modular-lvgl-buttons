[← Back to main README](../../README.md)

# ui/button

Momentary press tile — fires an action on tap, no state tracking.

Simple type — tile only, no detail page.

## Files

| File | Purpose |
|---|---|
| `local.yaml` | ESPHome button component (defined in the same device YAML) |
| `remote.yaml` | Home Assistant entity — works with `button.*`, `script.*`, `scene.*`, `input_button.*` |

## Variables

| Variable | Required | Description |
|---|---|---|
| `uid` | ✅ | Unique identifier — must be unique across all tiles on the device |
| `entity_id` | ✅ | ESPHome button ID (local) or HA entity string e.g. `"button.restart"` (remote) |
| `row` | ✅ | Grid row position (0-based) |
| `column` | ✅ | Grid column position (0-based) |
| `text` | ✅ | Label shown on tile |
| `icon` | ✅ | MDI glyph e.g. `$mdi_gesture_tap` |
| `row_span` | — | Number of rows to span (default: `1`) |
| `column_span` | — | Number of columns to span (default: `1`) |
| `page_id` | — | Parent page ID to place the tile on (default: `main_page`) |

## Usage

```yaml
# Local — ESPHome button component
restart_btn: !include
  file: esphome-modular-lvgl-buttons/ui/button/local.yaml
  vars:
    uid: restart_btn
    entity_id: restart_button   # your button: component id
    row: 0
    column: 0
    text: "Restart"
    icon: $mdi_restart

# Remote — Home Assistant button
doorbell_btn: !include
  file: esphome-modular-lvgl-buttons/ui/button/remote.yaml
  vars:
    uid: doorbell
    entity_id: "button.doorbell"
    row: 0
    column: 1
    text: "Doorbell"
    icon: $mdi_doorbell

# Remote — trigger a script
goodnight_btn: !include
  file: esphome-modular-lvgl-buttons/ui/button/remote.yaml
  vars:
    uid: goodnight
    entity_id: "script.good_night"
    row: 0
    column: 2
    text: "Good Night"
    icon: $mdi_weather_night

# Remote — activate a scene
movie_btn: !include
  file: esphome-modular-lvgl-buttons/ui/button/remote.yaml
  vars:
    uid: movie
    entity_id: "scene.movie_mode"
    row: 1
    column: 0
    text: "Movie"
    icon: $mdi_television_play
```

## Notes

- No state is tracked — the tile color stays at `$button_off_color` permanently.
- The remote variant uses `homeassistant.turn_on` which works for `button`, `script`, `scene`, and `input_button` domains.
- For local buttons, the ESPHome `button:` component must be defined in your device YAML before this tile is included.
