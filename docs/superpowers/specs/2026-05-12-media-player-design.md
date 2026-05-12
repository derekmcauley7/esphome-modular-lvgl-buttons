# Media Player Entity Type -- Design Spec

**Date:** 2026-05-12
**Scope:** Remote-only (HA) media player entity type with tile + detail page, optimized for Spotify but compatible with any HA media_player entity.

---

## File Structure

```
ui/media_player/
  remote.yaml    -- tile widget + abstract script implementations via HA
  detail.yaml    -- full-screen playback UI, shared globals, UI sync scripts
```

No `local.yaml`. This is remote-only since media player metadata (track info, album art, progress) comes exclusively from Home Assistant.

---

## Variable Contract

Passed via `!include vars:` when including `remote.yaml`:

| Variable | Type | Required | Default | Description |
|---|---|---|---|---|
| `uid` | string | yes | -- | Unique prefix for all IDs, globals, scripts |
| `entity_id` | string | yes | -- | HA entity e.g. `"media_player.spotify"` |
| `row` | int | yes | -- | Grid row on parent page |
| `column` | int | yes | -- | Grid column on parent page |
| `text` | string | yes | -- | Tile label / detail page header |
| `icon` | glyph | yes | -- | MDI icon glyph for tile |
| `row_span` | int | no | 1 | Tile row span |
| `column_span` | int | no | 1 | Tile column span |
| `page_id` | string | no | `main_page` | Parent page ID for back navigation |

### Usage Example

```yaml
packages:
  spotify: !include
    file: ui/media_player/remote.yaml
    vars:
      uid: spotify
      entity_id: "media_player.spotify"
      text: "Spotify"
      icon: "\U000F0CB9"
      row: 0
      column: 2
```

The detail page is also a standalone swipeable page. Add `${uid}_detail_page` to the device's page list for swipe navigation access.

---

## Abstract Script Contract

### Action Scripts (implemented in `remote.yaml`, called by `detail.yaml`)

| Script | Responsibility |
|---|---|
| `${uid}_media_play_pause` | Toggle play/pause via `media_player.media_play_pause` |
| `${uid}_media_next` | Next track via `media_player.media_next_track` |
| `${uid}_media_previous` | Previous track via `media_player.media_previous_track` |
| `${uid}_media_set_volume` | Apply `${uid}_current_volume` [0.0-1.0] via `media_player.volume_set` |
| `${uid}_media_shuffle_set` | Toggle shuffle using `${uid}_is_shuffle` via `media_player.shuffle_set` |
| `${uid}_media_repeat_set` | Set repeat mode using `${uid}_repeat_mode` (off/one/all) via `media_player.repeat_set` |

### UI Sync Scripts (implemented in `detail.yaml`)

| Script | Responsibility |
|---|---|
| `${uid}_sync_state` | Push all globals to LVGL widget values and colors |
| `${uid}_update_play_indicator` | Update the play-state MDI icon and glow color |

### Implementation Pattern

`remote.yaml` implements actions via `homeassistant.action`:

```yaml
script:
  - id: ${uid}_media_play_pause
    then:
      - homeassistant.action:
          action: media_player.media_play_pause
          data:
            entity_id: ${entity_id}
```

`detail.yaml` calls only abstract scripts -- never references `${entity_id}`:

```yaml
on_click:
  then:
    - script.execute: ${uid}_media_play_pause
```

---

## Globals

Declared in `detail.yaml`:

| Global | Type | Range/Values | Description |
|---|---|---|---|
| `${uid}_is_playing` | bool | -- | true = playing, false = paused/idle |
| `${uid}_current_volume` | float | 0.0-1.0 | Current volume level |
| `${uid}_is_shuffle` | bool | -- | Shuffle on/off |
| `${uid}_repeat_mode` | int | 0=off, 1=one, 2=all | Repeat mode |
| `${uid}_progress_percent` | int | 0-100 | Track progress percentage |
| `${uid}_media_title` | std::string | -- | Current track name |
| `${uid}_media_artist` | std::string | -- | Current artist name |

---

## HA Sensors

Declared in `remote.yaml`:

### Text Sensors

| ID | Entity | Attribute | Purpose |
|---|---|---|---|
| `${uid}_title` | `${entity_id}` | `media_title` | Track name |
| `${uid}_artist` | `${entity_id}` | `media_artist` | Artist name |
| `${uid}_state` | `${entity_id}` | *(no attribute -- reads entity state directly)* | playing/paused/idle/off |
| `${uid}_shuffle` | `${entity_id}` | `shuffle` | Shuffle state |
| `${uid}_repeat` | `${entity_id}` | `repeat` | Repeat mode |

### Numeric Sensors

| ID | Entity | Attribute | Purpose |
|---|---|---|---|
| `${uid}_volume` | `${entity_id}` | `volume_level` | Volume 0.0-1.0 |
| `${uid}_progress` | `${entity_id}` | `media_position` | Current position in seconds |
| `${uid}_duration` | `${entity_id}` | `media_duration` | Track duration in seconds |

### State Flow

1. HA sensor updates trigger `on_value:` handlers in `remote.yaml`
2. Handlers write new values to globals
3. Handlers call `${uid}_sync_state` to push globals to LVGL widgets

### Progress Bar Update

An `interval: 1s` timer in `detail.yaml`:
- Checks if `${uid}_is_playing` is true
- Calculates `(position / duration) * 100`
- Updates the progress bar widget
- Only ticks when playing to avoid unnecessary updates

---

## Tile Layout (in `remote.yaml`)

Standard grid tile following the project tile pattern:

- **Icon (top-left):** Media MDI icon
  - Playing: `$icon_on_color`
  - Paused/idle: `$icon_off_color`
- **Label (bottom-left):** Current track name, truncated (`long_mode: DOT`)
  - When playing: shows track title from `${uid}_media_title`
  - When idle/no track: shows `${text}` (e.g. "Spotify")
- **Play-state indicator (top-right):** Small circle
  - Green (`0x00FF00`) when playing
  - Grey when paused/idle
- **Background:** `$button_on_color` when playing, `$button_off_color` when paused/idle

### Interactions

- **Short-click:** Calls `${uid}_media_play_pause` (toggle play/pause)
- **Long-press:** Opens `${uid}_detail_page` with `MOVE_LEFT` animation (300ms)

---

## Detail Page Layout (in `detail.yaml`)

Full-screen layout using flex column arrangement. All sizing uses percentages and LVGL alignment properties -- no hardcoded pixel positions. Works across all supported display sizes.

### Header (top)

- **Back button (top-left):** Returns to `${page_id}` with `MOVE_RIGHT` animation (300ms)
- **Title label (centered):** `${text}` (e.g. "Spotify")

### Now Playing Card (middle, centered)

- **Large MDI icon (~120px, centered):** Music note icon
  - Playing: `$icon_on_color` with colored `shadow` glow effect
  - Paused: `$icon_off_color`, no glow/shadow
- **Track name label:** `nunito_24`, white, `long_mode: DOT`
  - Bound to `${uid}_media_title` global
- **Artist name label:** `nunito_18`, grey, `long_mode: DOT`
  - Bound to `${uid}_media_artist` global

### Progress Section

- **Progress bar (display-only):** Thin horizontal bar
  - Updated every 1s from `${uid}_progress_percent`
  - Indicator color: `$button_on_color`
  - Background: dark grey

### Transport Controls (centered row)

Left to right:
1. **Shuffle button:** MDI shuffle icon, highlighted when active (`$icon_on_color` vs `$icon_off_color`)
2. **Previous button:** MDI skip-previous icon
3. **Play/Pause button:** Large circular button (center, prominent)
   - Shows MDI play icon when paused, MDI pause icon when playing
   - Calls `${uid}_media_play_pause`
4. **Next button:** MDI skip-next icon
5. **Repeat button:** MDI repeat icon, highlighted when active
   - Cycles through off -> all -> one -> off
   - Shows MDI repeat-once icon when in repeat-one mode

### Volume Section (bottom)

- **Volume icon (left):** MDI volume icon
- **Horizontal slider:** Range 0-100, maps to 0.0-1.0
  - `on_value:` updates `${uid}_current_volume` global
  - `on_release:` calls `${uid}_media_set_volume` (via 500ms debounce script with `mode: restart`, matching the climate slider pattern)

---

## Swipe Integration

The detail page (`${uid}_detail_page`) is a standard LVGL page that can be:
1. Opened via long-press on the tile
2. Added to the device's swipe page list for direct swipe navigation

The device config controls which pages are in the swipe list. Example:

```yaml
pages:
  - main_page
  - ${uid}_detail_page
```

---

## Theme Compliance

All colors reference theme substitution variables:
- `$button_on_color`, `$button_off_color` for tile/button backgrounds
- `$icon_on_color`, `$icon_off_color` for icon states
- `$label_on_color`, `$label_off_color` for text
- `$icon_font` for the icon font

The only hardcoded color is the play-state indicator green (`0x00FF00`), which is a semantic constant (green = playing).

Fonts use project standard: `nunito_24` for track name, `nunito_18` for artist, `$icon_font` for icons.
