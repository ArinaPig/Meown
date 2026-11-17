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
  map_manifest.example.json # Safe template; complete=false keeps it inactive
  map_manifest.json         # Create only when the full art pack is ready
  background/               # Full 480x800 map background
  paths/                    # Winding path and path decorations
  buildings/                # Shop and home sprites; party picnic area
  nature/                   # Trees, bushes, flowers, fences and lamps
  characters/               # Resident cats and animation frames
  ui/                       # Optional decorative UI textures
```

## Canvas and visual direction

- Design canvas: **480x800**, portrait.
- Pixel-art filtering: nearest-neighbour; no blur, anti-aliasing or smoothing.
- Use a consistent pixel scale. Small props should fit a 32x32 grid where practical.
- Buildings and larger props may use multi-tile sprites.
- Export individual props as transparent PNGs; only the background should be opaque.
- Palette: peach, cream, pink, caramel, sage green, sky blue, warm yellow and dark warm-brown outlines.
- Use chunky readable silhouettes, restrained detail and clear contrast between the path and grass.
- Keep the scene airy: the three locations and their labels/buttons must remain easy to spot.
- Do not bake text, counters, labels or clickable controls into the artwork. Godot UI controls render those separately.
- Avoid cafe/restaurant imagery. The first location is an ordinary neighbourhood shop where the kitten gathers party food.

## Current location layout

These are approximate visual anchors on the 480x800 canvas. Keep each landmark fully above its matching button.

| Location | Landmark centre | Suggested sprite bounds | Button area |
|---|---:|---:|---:|
| Shop | (125, 285) | x=57, y=217, w=136, h=128 | x=48, y=350, w=154, h=62 |
| Home | (350, 430) | x=282, y=350, w=136, h=128 | x=263, y=485, w=174, h=62 |
| Party picnic | (155, 615) | x=75, y=565, w=160, h=100 | x=66, y=680, w=178, h=58 |

The path should guide the eye from the shop to the home and then to the party picnic area. Keep the clickable button rectangles clear of foreground decorations.

## Manifest format

The loader reads `res://assets/map/map_manifest.json` only. The checked-in `map_manifest.example.json` is a planning template, not an active manifest. It deliberately has `complete: false`, so copying it without finishing the art pack cannot hide the fallback map.

When the art pack is ready, copy the template to `map_manifest.json`, update texture paths and layer bounds, and set `complete` to `true`. The loader expects a JSON object with a `layers` array. Each layer supports `name`, `texture`, `position`, `size`, `z_index`, and `required`.

Recommended draw order (back to front):
1. Opaque grass/background.
2. Pond and other water.
3. Main winding path.
4. Location buildings and picnic props.
5. Foreground trees, bushes and fences.
6. Resident cats and small animated decorations.

The map loader keeps the current fallback map visible unless the manifest is marked complete and every required texture exists. Optional layers can set `required` to `false`; their absence will not prevent the new art pack from activating.
