# World map art assets

This folder contains the modular pixel-art artwork for the **Meown** world map.

The story locations are:
1. **Shop** — the kitten collects food for the party in the Match-3 mini-game.
2. **Home** — the kitten searches for party items.
3. **Party** — the cats meet for the Cat.io mini-game.

This is a small neighbourhood map, not a cafe. Keep the artwork consistent with the game's cozy pastel pixel-art style.

## Planned structure

```
assets/map/
  README.md
  map_manifest.json       # Add only when the complete art pack is ready
  background/              # Full 480x800 map background
  paths/                   # Winding path and path decorations
  buildings/               # Shop and home sprites; party picnic area
  nature/                  # Trees, bushes, flowers, fences and lamps
  characters/              # Resident cats and animation frames
  ui/                      # Optional decorative UI textures
```

## Canvas and visual direction

- Design canvas: **480x800**, portrait.
- Pixel-art filtering: nearest-neighbour; no blur, anti-aliasing or smoothing.
- Use a consistent pixel scale. Small props should fit a 32x32 grid where practical.
- Buildings and larger landmarks may use multi-tile sprites.
- Export individual props as transparent PNGs; only the background should be opaque.
- Palette: peach, cream, pink, caramel, sage green, sky blue, warm yellow and dark warm-brown outlines.
- Use chunky readable silhouettes, restrained detail and clear contrast between the path and grass.
- Keep the scene airy: the three locations and their labels/buttons must remain easy to spot.
- Do not bake text, counters, labels or clickable controls into the artwork. Godot UI controls render those separately.
- Avoid cafe/restaurant imagery. The first location is an ordinary neighbourhood shop where the kitten gathers party food.

## Current location layout

These are approximate visual anchors on the 480x800 canvas. Keep the main landmark artwork above its matching button.

| Location | Landmark centre | Button area |
|---|---:|---:|
| Shop | (125, 285) | x=48, y=350, w=154, h=62 |
| Home | (350, 430) | x=263, y=485, w=174, h=62 |
| Party picnic | (155, 625) | x=66, y=680, w=178, h=58 |

The path should guide the eye from the shop to the home and then to the party picnic area.

## Manifest format

Create `map_manifest.json` only when the complete replacement art pack is ready. The loader expects a JSON object with `complete: true` and a `layers` array. Layers are drawn in array order; use `z_index` for explicit depth ordering.

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

The map loader keeps the current fallback map visible unless the manifest is marked complete and every required texture exists. This lets the art pack be prepared in stages without showing a partially rendered replacement map.

Optional layers can set `required` to `false`. Their absence will not prevent the new art pack from activating.
