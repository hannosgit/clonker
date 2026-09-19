# Clonker water and mining sandbox

Milestone 5 of the [implementation plan](specs/IMPLEMENTATION_PLAN.md) adds water and swimming to the playable mining and explosion sandbox. It uses Godot **4.4.1** (official build `49a5bc7b6`). Open `project.godot` and press F5, or run `godot --path .`.

| Action | Default input |
| --- | --- |
| Move | A/D or Left/Right |
| Jump or swim upward | Space, W, or Up |
| Mine with selected tool | Hold left mouse button near the character |
| Throw selected timed charge | Select slot 6, then left click within 340 px or press F |
| Select inventory slot | 1–6 |
| Pick up nearby item | E |
| Drop selected stack | Q |
| Throw selected stack | F |
| Paint earth | Hold right mouse button |
| Paint rock | Shift + right mouse button |
| Change brush radius | Mouse wheel, 8–80 px |
| Recover after death or reset character | R |

The first two slots contain a shovel and a pickaxe; slot 6 starts with three timed charges. The shovel digs earth; the pickaxe digs earth, rock, coal, ore, and gold. Coal lies near x=-470 and ore near x=-385, just below the starting ground. Dig toward a deposit, collect its loose chunks with E, carry them in inventory, and drop them elsewhere with Q. Two caves centered near (-615, 440) and (-465, 440) are separated by a wall; a charge can connect them. A thrown charge arms a two-second fuse. The blast removes material according to blast resistance, turns exposed deposits into resource piles, damages the player, and pushes loose objects. A lake fills the pit at x=620–770. A dry mine centered at (700, 640) sits below it; excavate the lake floor around (700, 520) and continue down through the roof to flood the mine. Hold jump to swim upward when submerged. Dead characters cannot act until R recovers them at spawn with full health. Right-click painting and the mouse-wheel brush are debug editing tools. Painting occupied character cells is rejected.

## Files and architecture

- `data/materials.json` defines stable IDs 0–5 for sky, earth, rock, coal, ore, and gold. Deposits declare an item and yield per cell. Every entry has solidity, density, dig and blast resistance, value, color, and optional liquid and temperature fields. `scripts/material_catalog.gd` loads these definitions.
- `data/items.json` declares the shovel, pickaxe, and resource items, including tool reach, radius, cooldown, material power, and stack size. `scripts/item_catalog.gd` loads them. `scripts/tool_action.gd` applies one shared mining action through the terrain edit API.
- `data/items.json` also declares the timed charge's fuse, blast radius, power, and damage. `scenes/timed_explosive.tscn` and `scripts/timed_explosive.gd` make it a physical throwable item. `scripts/explosion_system.gd` owns the shared blast operation, bounded detonation queue, and visible blast ring. Both character and loose objects implement `receive_damage(amount, impulse)`; nearby charges queue detonation through the same operation. The player camera applies a short, capped shake.
- `scripts/inventory.gd` owns six slots and atomic insert/selection/removal operations. Each character owns its inventory; `scripts/game_session.gd` transfers item quantities between that inventory and world objects, turns deposit cell removal into loose resource piles, and caps mined resource piles at 96.
- `scenes/world_item.tscn` and `scripts/world_item.gd` define one rigid body for both equipment and resources. Bodies collide with terrain, fall and slide, and sleep after settling. The selected inventory slot is the held item; the HUD shows it.
- `scenes/sandbox_world.tscn` and `scripts/sandbox_world.gd` own the authoritative terrain cells, rendering, collision, edit API, and rebuild statistics. The old hand-built terrain has been replaced.
- `scripts/liquid_system.gd` owns water amounts and liquid type IDs in separate cell arrays, fixed-step flow, active-cell scheduling, submersion queries, water rendering, displacement accounting, and a contact signal for future material reactions. The terrain edit API emits changed cells; mining, painting, and explosions therefore wake the same liquid simulation. `CharacterController` queries submersion for swimming.
- `scenes/sandbox.tscn` and `scripts/game_session.gd` own the playable session, items, debug brush, spawn, and reset. `scripts/character_controller.gd` uses regular physics collision and a grounded 8 px step to traverse cell-sized slope ledges. It never queries a terrain node.
- `scenes/debug_overlay.tscn` and `scripts/debug_overlay.gd` display health, inventory, selected slot, FPS, active physics object count, chunk count, pending dirty chunks, last rebuild time, simulated water cell count, queued liquid cells, last liquid update time, and controls.
- `tests/sandbox_smoke.gd` replays movement from milestone 1. `tests/terrain_smoke.gd` checks edits, material accounting, dirty rebuilds, collision, seam traversal, and a narrow rock passage. `tests/mining_inventory_smoke.gd` checks tool effectiveness, ore yield, transfers, capacity, and body settling. `tests/explosion_smoke.gd` checks damage falloff, caves, collision after seam blasts, physical yields, impulses, fuse timing, bounded chains, and recovery. `tests/liquid_smoke.gd` checks settled-lake work, swimming, displacement, flooding, a chunk seam, and volume conservation. The benchmark scripts measure edits, blasts, and water at 1920×1080.

## Water simulation

Each 8 px cell stores 0–255 water units; one full cell is 255 units. Water uses a 30 Hz fixed step separate from rigid-body physics. Each step processes at most 512 queued cells, first transferring downward into available space, then equalizing left and right neighbors. Transfers preserve integer water units. A cell wakes with its neighbors when water moves or when nearby terrain changes; a settled lake has an empty queue and costs effectively no flow work. The map edges are sealed: water cannot enter or leave outside the 288×144-cell map.

Water is drawn as translucent blue chunk textures. `LiquidType` reserves IDs 1–3 for water, lava, and oil; only water is simulated. `liquid_material_contact` is the hook for later terrain reactions. When new solid terrain covers water, the system first removes the water from that cell and seeks nearby open capacity. If no reachable capacity exists within the bounded search, the units stay in a displacement reserve and are retried when terrain changes. `total_water_units()` includes this reserve, so construction and terrain edits do not silently delete water. The character samples head, torso, and legs; at half submersion it switches to slower horizontal swimming, reduced downward motion, and jump-held upward movement.

## Terrain coordinates and rebuilding

Cell size is **8×8 world pixels**. The map has **288×144 cells** (2304×1152 px), split into **32×32 cell chunks** (45 chunks total). Local map origin is **(-800, -384)**. `world_to_cell` floors the offset world coordinate divided by 8; `cell_to_world` returns a cell's upper-left world position. Out-of-map queries return sky.

The byte array of material IDs is authoritative. `apply_edits` accepts an array of `{"cell": Vector2i, "material": id}` commands and returns counts of replaced solid material IDs. `remove_circle` and `paint_circle` use this API. Edits update cells immediately and mark touched chunks dirty, including neighboring chunks when a boundary cell changes. A single deferred flush rebuilds each dirty chunk once after the edit batch, outside the physics query/update phase.

Each chunk creates an RGBA image from its cells, shown through a nearest-filtered `Sprite2D`. Solid cells are merged into horizontal runs, then identical runs across rows become `RectangleShape2D` regions on one `StaticBody2D` per chunk. Rectangles end exactly at cell and chunk boundaries. Old shapes are detached before new shapes are installed in the deferred flush. Sky has no collision. Terrain changes that would overlap a character are skipped; the flush also moves any embedded terrain actor upward to the first free position within 32 cells. These rules avoid invisible stale collision after edits and preserve traversable seams.

## Verification and performance

Run:

```sh
godot --headless --path . --script tests/sandbox_smoke.gd
godot --headless --path . --script tests/terrain_smoke.gd
godot --headless --path . --script tests/mining_inventory_smoke.gd
godot --headless --path . --script tests/explosion_smoke.gd
godot --headless --path . --script tests/liquid_smoke.gd
godot --path . --resolution 1920x1080 --script tests/terrain_benchmark.gd
godot --path . --resolution 1920x1080 --script tests/explosion_benchmark.gd
godot --path . --resolution 1920x1080 --script tests/liquid_benchmark.gd
```

The movement, terrain, mining/inventory, explosion, and liquid smoke tests passed on 2026-09-19 with Godot 4.4.1. The liquid test checks that the large lake settles, the player swims, solid placement preserves volume, excavation wakes the lake and fills the mine floor, water crosses a chunk seam, and enclosed displaced water returns when space reopens. The windowed liquid benchmark runs 180 rendered frames for each of a settled lake and flooding mine: settled average 4.66 ms, worst 7.61 ms, zero frames over 16.67 ms; flooding average 4.81 ms, worst 33.91 ms, one frame over 16.67 ms. Peak liquid update was 1.77 ms while flooding. Earlier explosion benchmark: average 5.80 ms, worst 30.45 ms, two frames over 16.67 ms. Reference desktop: AMD Ryzen 7 7800X3D, 30 GiB RAM, AMD Radeon integrated graphics via WSLg D3D12/Mesa 22.3.6. Benchmark results and known limits are recorded in the [milestone plan](specs/IMPLEMENTATION_PLAN.md).

This remains a small static sample map with one character. Cell edges are visible on slopes, and the step assist is tuned to this 8 px grid. The debug brush edits any material equally and does not produce mining yields. A mined resource pile may contain more than one inventory stack; E then takes as many units as fit. At the 96-pile limit, new mining yields merge into an existing pile of the same item or wait in the session until a slot opens. Loose item health is 100 and sufficiently strong blasts can destroy them. Water has no buoyancy or drag effect on loose rigid bodies yet. The benchmark covers this sample lake and mine; it does not cover the larger water/object/worker stress scene planned for milestone 10. Windowed frame spikes above 16.67 ms remain in the measured run.
