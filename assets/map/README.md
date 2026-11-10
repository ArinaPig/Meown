# World map art assets

This folder contains the modular pixel-art artwork for the Kitten Cafe world map.

## Planned structure

```
assets/map/
  README.md
  map_manifest.json       # Add this when the complete art pack is ready
  background/              # Full 480x800 map background
  paths/                   # Separate path segments or path decorations
  buildings/               # Shop, home and party location sprites
  nature/                  # Trees, bushes, flowers and lamps
  characters/              # Resident cats and their animation frames
  ui/                      # Optional map-specific decorative UI textures
```

## Visual and technical rules

- Design canvas: 480x800, portrait.
- Pixel-art filtering: nearest-neighbour; avoid blur and smoothing.
- Small props: work on a 32x32 pixel grid where practical.
- Buildings and large props may be larger multi-tile sprites.
- Export sprites as PNG with transparent backgrounds unless the layer is a full-screen background.
- Keep the existing Kitten Cafe palette: peach, cream, pink, caramel, sage, sky blue and warm brown.
- Keep important clickable areas clear. Artwork must not cover the location buttons.

## Manifest format

Create `map_manifest.json` only when the complete replacement pack is ready. The loader expects a JSON object with `complete: true` and a `layers` array. Layers are drawn in array order; use `z_index` for explicit depth ordering.

Example:

```json
{
  "complete": true,
  "layers": [
    {
      "name": "map_background",
      "texture": "res://assets/map/background/map_background.png",
      "position": [0, 0],
      "size": [480, 800],
      "z_index": -10,
      "required": true
    },
    {
      "name": "main_path",
      "texture": "res://assets/map/paths/main_path.png",
      "position": [0, 0],
      "size": [480, 800],
      "z_index": -5,
      "required": true
    },
    {
      "name": "shop_building",
      "texture": "res://assets/map/buildings/shop.png",
      "position": [65, 215],
      "size": [120, 110],
      "z_index": 2,
      "required": true
    }
  ]
}
```

The map loader keeps the current code-drawn map visible unless the manifest is marked complete and every required texture exists. This allows the art pack to be prepared separately without leaving the game with a partially rendered map.

Optional layers can set `required` to `false`. Their absence will not prevent the new art pack from activating.
