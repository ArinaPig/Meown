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
  map_manifest.example.json           # Portrait template; complete=false keeps it inactive
  map_manifest.landscape.example.json # Tablet template; complete=false keeps it inactive
  map_manifest.json                   # Active portrait pack; create only when ready
  map_manifest.landscape.json         # Active tablet pack; create only when ready
  background/               # Full 480x800 map background
  paths/                    # Winding path and path decorations
  buildings/                # Shop and home sprites; party picnic area
  nature/                   # Trees, bushes, flowers, fences and lamps
  characters/               # Resident cats and animation frames
  ui/                       # Optional decorative UI textures
```

## Canvas and visual direction

- Portrait art canvas: **480x800**.
- Landscape tablet art canvas: **1280x800** when a dedicated wide composition is prepared. The loader activates an art pack only when its declared `canvas` matches the active map layout; portrait artwork is deliberately not stretched across a landscape tablet.
- Keep separate compositions for portrait phones and landscape tablets. The portrait and tablet templates are separate because the landmarks and route are arranged differently. Until the matching complete art pack exists, the built-in map drawing remains active for that layout.
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

## Landscape tablet layout

Use the dedicated **1280x800** composition for a horizontal tablet. The three destinations form a left-to-right route: Shop → Home → Party. Keep the title and subtitle in the top band, landmarks in the middle band, and the interactive buttons below them.

| Location | Landmark centre | Suggested sprite bounds | Button area |
|---|---:|---:|---:|
| Shop | (300, 355) | x=210, y=270, w=180, h=170 | x=170, y=510, w=260, h=76 |
| Home | (640, 355) | x=550, y=270, w=180, h=170 | x=510, y=510, w=260, h=76 |
| Party picnic | (980, 355) | x=890, y=270, w=180, h=170 | x=850, y=510, w=260, h=76 |

Keep the central route readable and leave the bottom status area (approximately y=730–772) unobstructed. These positions match the current tablet fallback composition and UI controls in `WorldMap.gd`.

## Manifest format

The loader reads `res://assets/map/map_manifest.json` for portrait and `res://assets/map/map_manifest.landscape.json` for landscape tablets. The checked-in `map_manifest.example.json` and `map_manifest.landscape.example.json` are planning templates, not active manifests. Both deliberately have `complete: false`, so copying either template without finishing the art pack cannot hide the fallback map.

When each art pack is ready, copy its matching template to the active filename, update texture paths and layer bounds, and set `complete` to `true`. Both manifests must include the five required layer names: `map_background`, `main_path`, `shop_building`, `home_building`, and `party_picnic`. The loader expects a JSON object with a `canvas` array and a `layers` array. Each layer supports `name`, `texture`, `position`, `size`, `z_index`, and `required`.

Recommended draw order (back to front):
1. Opaque grass/background.
2. Pond and other water.
3. Main winding path.
4. Location buildings and picnic props.
5. Foreground trees, bushes and fences.
6. Resident cats and small animated decorations.

The map loader keeps the current fallback map visible unless the manifest is marked complete and every required texture exists. Optional layers can set `required` to `false`; their absence will not prevent the new art pack from activating.

## Pre-activation validation

Before switching the game to a new art pack, run the read-only validator from the project root:

```sh
godot --headless --path . --script res://tools/validate_map_assets.gd
```

The validator checks each active portrait/tablet manifest for:
- the expected canvas size and `complete: true`;
- all five required layer names, marked as required;
- unique layer names and valid texture resources;
- positive layer sizes and bounds contained within the canvas.

Missing optional textures are reported as warnings. If an active manifest is absent, that layout is skipped; this is expected while the artwork is being prepared. A successful validation is a preflight check, not a replacement for opening the game and visually testing both orientations and all three location buttons.
