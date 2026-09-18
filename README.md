# Clonker terrain sandbox

Milestone 2 of the [implementation plan](specs/IMPLEMENTATION_PLAN.md) is a playable destructible-terrain sandbox. It uses Godot **4.4.1** (official build `49a5bc7b6`). Open `project.godot` and press F5, or run `godot --path .`.

| Action | Default input |
| --- | --- |
| Move | A/D or Left/Right |
| Jump | Space, W, or Up |
| Dig | Hold left mouse button |
| Paint earth | Hold right mouse button |
| Paint rock | Shift + right mouse button |
| Change brush radius | Mouse wheel, 8–80 px |
| Reset character | R |

The brush is a debug world-editing tool; tool reach, mining yield, inventory, and material resistance effects arrive in later milestones. The character can walk, jump, dig through the ground, and enter tunnels. Painting occupied cells is rejected so the brush cannot embed the character.

## Files and architecture

- `data/materials.json` defines stable IDs 0/1/2 for sky, earth, and rock. Every entry has solidity, density, dig and blast resistance, value, color, and optional liquid and temperature fields. `scripts/material_catalog.gd` loads these definitions.
- `scenes/sandbox_world.tscn` and `scripts/sandbox_world.gd` own the authoritative terrain cells, rendering, collision, edit API, and rebuild statistics. The old hand-built terrain has been replaced.
- `scenes/sandbox.tscn` and `scripts/game_session.gd` own the playable session, mouse brush, spawn, and reset. `scripts/character_controller.gd` uses regular physics collision and a grounded 8 px step to traverse cell-sized slope ledges. It never queries a terrain node.
- `scenes/debug_overlay.tscn` and `scripts/debug_overlay.gd` display FPS, chunk count, pending dirty chunks, last rebuild time, and controls.
- `tests/sandbox_smoke.gd` replays movement from milestone 1. `tests/terrain_smoke.gd` checks edits, material accounting, dirty rebuilds, collision, seam traversal, and a narrow rock passage. `tests/terrain_benchmark.gd` measures repeated edits in a 1920×1080 window.

## Terrain coordinates and rebuilding

Cell size is **8×8 world pixels**. The map has **288×144 cells** (2304×1152 px), split into **32×32 cell chunks** (45 chunks total). Local map origin is **(-800, -384)**. `world_to_cell` floors the offset world coordinate divided by 8; `cell_to_world` returns a cell's upper-left world position. Out-of-map queries return sky.

The byte array of material IDs is authoritative. `apply_edits` accepts an array of `{"cell": Vector2i, "material": id}` commands and returns counts of replaced solid material IDs. `remove_circle` and `paint_circle` use this API. Edits update cells immediately and mark touched chunks dirty, including neighboring chunks when a boundary cell changes. A single deferred flush rebuilds each dirty chunk once after the edit batch, outside the physics query/update phase.

Each chunk creates an RGBA image from its cells, shown through a nearest-filtered `Sprite2D`. Solid cells are merged into horizontal runs, then identical runs across rows become `RectangleShape2D` regions on one `StaticBody2D` per chunk. Rectangles end exactly at cell and chunk boundaries. Old shapes are detached before new shapes are installed in the deferred flush. Sky has no collision. Terrain changes that would overlap a character are skipped; the flush also moves any embedded terrain actor upward to the first free position within 32 cells. These rules avoid invisible stale collision after edits and preserve traversable seams.

## Verification and performance

Run:

```sh
godot --headless --path . --script tests/sandbox_smoke.gd
godot --headless --path . --script tests/terrain_smoke.gd
godot --path . --resolution 1920x1080 --script tests/terrain_benchmark.gd
```

The movement and terrain smoke tests passed on 2026-09-18 with Godot 4.4.1. The terrain test dug across a chunk boundary, verified collision with a physics ray, repainted and removed rock, and walked through a narrow passage. The benchmark edits 180 consecutive rendered frames after 30 warm-up frames. Reference desktop: AMD Ryzen 7 7800X3D, 30 GiB RAM, AMD Radeon integrated graphics via WSLg D3D12/Mesa 22.3.6. Benchmark results and known limits are recorded in the [milestone plan](specs/IMPLEMENTATION_PLAN.md).

This remains a small static sample map with one character. Cell edges are visible on slopes, and the step assist is tuned to this 8 px grid. The debug brush edits any material equally; resistance and yields are defined as data for the next milestones. The benchmark covers terrain editing in this map, not the larger water/object/explosion stress scene planned for milestone 10.
