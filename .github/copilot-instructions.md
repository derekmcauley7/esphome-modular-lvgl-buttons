# Copilot Instructions — esphome-modular-lvgl-buttons

This is an **ESPHome YAML library** for building LVGL touchscreen UIs. Not Python, not JavaScript — pure ESPHome YAML with inline C++ lambdas.

Read [ARCHITECTURE.md](../ARCHITECTURE.md) for full details. See [CLAUDE.md](../CLAUDE.md) for the full coding contract.

## Key Rules

- **Always use named colors, never hex values.** Use library colors from `common/color.yaml` (e.g., `ep_orange`, `misty_blue`, `very_dark_gray`, `gray50`-`gray900`) or ESPHome built-in CSS color names (e.g., `coral`, `dodgerblue`, `teal`, `tomato`). If you need a new color, define it as a substitution and reference as `$my_color` — never inline hex.
- Every tile component needs a **unique `uid`** — reusing one causes LVGL ID compile errors
- Tiles extend pages via `!extend ${page_id | default("main_page")}` — they don't create pages
- Widget IDs follow the pattern: `button_${uid}`, `icon_${uid}`, `label_${uid}`, `slider_${uid}`, `value_${uid}`
- All scripts, globals, and IDs are namespaced with `${uid}_`
- Variables use `${var | default(value)}` syntax for defaults
- Colors use substitution variables: `$button_on_color`, `$button_off_color`, `$icon_on_color`, `$icon_off_color`, `$label_on_color`, `$label_off_color`
- Icons are substitution vars from `common/mdi_glyph_substitutions.yaml`: `$mdi_lightbulb`, `$mdi_home`, etc.
- Fonts: `$icon_font` for icons, `$text_font` for labels
- Grid positioning: `grid_cell_row_pos`, `grid_cell_column_pos`, `grid_cell_row_span`, `grid_cell_column_span`
- **Never hardcode pixel coordinates or screen dimensions** — use LVGL alignment and percentage widths

## Architecture: Local / Remote / Detail

All UI components live under `ui/<type>/`. Each type has:
- `local.yaml` — drives ESPHome native components directly
- `remote.yaml` — drives Home Assistant via `homeassistant.action` and `homeassistant` platform sensors
- `detail.yaml` — (complex types only) full-screen detail page, included automatically by both local and remote

Users `!include` only `local.yaml` or `remote.yaml` — one include per entity, never `detail.yaml` directly.

## The Abstract Script Contract

The detail page calls only `${uid}_`-prefixed scripts — it has no knowledge of whether the entity is local or remote. Each button file implements the contract for its transport:

- `light`: `${uid}_light_toggle`, `${uid}_light_set_brightness`, `${uid}_light_apply_hs`, `${uid}_light_apply_color_temp`
- `switch`: `${uid}_switch_toggle`, `${uid}_sync_state`

## File Structure for a New Tile

1. YAML comment header listing all `vars:`
2. `globals:` for state tracking (prefixed `${uid}_`)
3. `lvgl: pages:` section using `!extend` with `container → button → labels`
4. State subscription (`binary_sensor`, `sensor`, or `text_sensor` from `platform: homeassistant`)
5. `script:` implementing the abstract script contract + `${uid}_sync_state`
6. For complex types: pull in `detail.yaml` via `packages:`

## Implemented Types

| Type | Status |
|---|---|
| `light` | ✅ local + remote + detail |
| `switch` | ✅ local + remote |
| `sensor` | ✅ local + remote |
| `button` | 🔜 planned |
| `climate` | 🔜 planned |

## LVGL Gotchas

Read [LVGL_REFERENCE.md](../LVGL_REFERENCE.md) for critical LVGL v8 behavior — especially image tiling, layout override rules, and the obj wrapper pattern for images.

## Testing

```bash
esphome config example_code/SDL-lvgl-display_modular_480px.yaml
```

Or run full validation: `bash testing/test_configs.sh`
