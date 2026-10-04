# Clonker settlement sandbox

Milestone 6 of the [implementation plan](specs/IMPLEMENTATION_PLAN.md) adds construction and settlement storage to the playable mining, explosion, and water sandbox. It uses Godot **4.4.1** (official build `49a5bc7b6`). Open `project.godot` and press F5, or run `godot --path .`.

The woodland presentation adds a gradient sky, parallax hills, pines and surface plants, textured earth and mineral deposits, an animated miner with visible equipment, distinct timber and masonry buildings, and gently animated water. The compact HUD shows vitality, six equipment slots, nearby storage, and construction costs. **F1** opens the field guide; **F3** toggles performance diagnostics. All artwork is drawn locally with Godot shapes, cached terrain tiles, and one water shader; no external assets or downloads are required.

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
| Toggle building preview | B |
| Choose base, workshop, furnace, or storage while building | 1–4 |
| Place preview building | Left click on a valid site |
| Cancel building preview | Right click or Esc |
| Deposit selected resource stack into nearest building | G |
| Choose resource to withdraw | [ / ] |
| Withdraw chosen resource as a physical item | H |
| Toggle field guide | F1; Esc also closes it |
| Toggle performance diagnostics | F3 |

The first two slots contain a shovel and a pickaxe; slot 6 starts with three timed charges. The shovel digs earth; the pickaxe digs earth, rock, coal, ore, and gold. Coal lies near x=-470 and ore near x=-385, just below the starting ground. Dig toward a deposit, collect its loose chunks with E, carry them in inventory, and drop them elsewhere with Q. Rock yields stone when mined with a pickaxe. Two caves centered near (-615, 440) and (-465, 440) are separated by a wall; a charge can connect them. A thrown charge arms a two-second fuse. The blast removes material according to blast resistance, turns exposed deposits into resource piles, damages the player, and pushes loose objects. A lake fills the pit at x=620–770. A dry mine centered at (700, 640) sits below it; excavate the lake floor around (700, 520) and continue down through the roof to flood the mine. Hold jump to swim upward when submerged. Dead characters cannot act until R recovers them at spawn with full health. Right-click painting and the mouse-wheel brush are debug editing tools. Painting occupied character cells is rejected.

A supplied base stands west of the starting character at x=-736. It begins with 24 wood, 24 stone, and 5 metal. These supplies cover a workshop, furnace, and storage without requiring metal to be refined first. Press B, choose a building with 1–4, and move the mouse near flat ground; the preview is green when valid and red with a reason in the HUD when blocked. Left click to build instantly. Costs come from carried resources first, then buildings within 256 px of the site. Walk near a building and press G with a resource stack selected to store it. Use [ and ] to choose a stored resource and H to withdraw up to one inventory stack as a physical item, then collect it with E. The HUD shows nearby contents and remaining capacity.

## Files and architecture

- `data/materials.json` defines stable IDs 0–5 for sky, earth, rock, coal, ore, and gold. Deposits declare an item and yield per cell. Every entry has solidity, density, dig and blast resistance, value, color, and optional liquid and temperature fields. `scripts/material_catalog.gd` loads these definitions.
- `data/items.json` declares the shovel, pickaxe, and resource items, including tool reach, radius, cooldown, material power, and stack size. `scripts/item_catalog.gd` loads them. `scripts/tool_action.gd` applies one shared mining action through the terrain edit API.
- `data/items.json` also declares the timed charge's fuse, blast radius, power, and damage. `scenes/timed_explosive.tscn` and `scripts/timed_explosive.gd` make it a physical throwable item. `scripts/explosion_system.gd` owns the shared blast operation, bounded detonation queue, and visible blast ring. Both character and loose objects implement `receive_damage(amount, impulse)`; nearby charges queue detonation through the same operation. The player camera applies a short, capped shake.
- `scripts/inventory.gd` owns six slots and atomic insert/selection/removal operations. Each character owns its inventory; `scripts/game_session.gd` transfers item quantities between that inventory and world objects, turns deposit cell removal into loose resource piles, and caps mined resource piles at 96.
- `data/buildings.json` declares stable building IDs, footprint sizes, required support fraction, costs, storage capacity, interaction radius, and colors. `scripts/building_catalog.gd` loads them. `scripts/building.gd` owns each structure's collision, construction state, visual, and serialized resource contents. `scripts/construction_system.gd` owns preview, placement validation, synchronous cost deduction, nearby storage transfers, and support checks after terrain edits. Unsupported buildings collapse and spill their contents as physical items; construction materials are not refunded.
- `scenes/world_item.tscn` and `scripts/world_item.gd` define one rigid body for both equipment and resources. Bodies collide with terrain, fall and slide, and sleep after settling. The selected inventory slot is the held item; the HUD shows it.
- `scenes/sandbox_world.tscn` and `scripts/sandbox_world.gd` own the authoritative terrain cells, rendering, collision, edit API, and rebuild statistics. The old hand-built terrain has been replaced.
- `scripts/liquid_system.gd` owns water amounts and liquid type IDs in separate cell arrays, fixed-step flow, active-cell scheduling, submersion queries, water rendering, displacement accounting, and a contact signal for future material reactions. The terrain edit API emits changed cells; mining, painting, and explosions therefore wake the same liquid simulation. `CharacterController` queries submersion for swimming.
- `scenes/sandbox.tscn` and `scripts/game_session.gd` own the playable session, items, debug brush, spawn, and reset. `scripts/character_controller.gd` uses regular physics collision and a grounded 8 px step to traverse cell-sized slope ledges. It never queries a terrain node.
- `scripts/game_hud.gd` displays vitality, equipment, construction, nearby storage, contextual instructions, and the F1 field guide. `scenes/debug_overlay.tscn` and `scripts/debug_overlay.gd` retain performance metrics behind F3. `scripts/item_art.gd` shares tool and resource artwork between the HUD, held equipment, and loose items.
- `scripts/sky_backdrop.gd` draws the sky and camera-relative distant hills. `scripts/world_scenery.gd` draws underground backgrounds and decorations anchored to solid terrain. `scripts/character_visual.gd` animates the miner's stride, held tool, and damage flash. `scripts/world_feedback.gd` supplies a mining cursor, bounded debris particles, and nearby pickup prompts. `assets/water.gdshader` animates the water's tint without changing its simulation.
- `tests/sandbox_smoke.gd` replays movement from milestone 1. `tests/terrain_smoke.gd` checks edits, material accounting, dirty rebuilds, collision, seam traversal, and a narrow rock passage. `tests/mining_inventory_smoke.gd` checks tool effectiveness, ore yield, transfers, capacity, and body settling. `tests/explosion_smoke.gd` checks damage falloff, caves, collision after seam blasts, physical yields, impulses, fuse timing, bounded chains, and recovery. `tests/liquid_smoke.gd` checks settled-lake work, swimming, displacement, flooding, a chunk seam, and volume conservation. `tests/construction_smoke.gd` checks invalid placement accounting, the metal bootstrap, all four buildings, resource storage and retrieval, and undermining. The benchmark scripts measure edits, blasts, and water at 1920×1080.

## Construction and support

Building positions snap to 8 px. A valid footprint must fit within the map with an 8 px margin, be within 320 px of the character, contain no solid terrain, overlap neither a character nor another building, and have at least 75% of its width supported by the solid terrain row below. A preview names the first failed rule, including shortages. Placement validation runs before any resource is consumed, and the deduction and creation run synchronously. The `construction_state` field is separate from validation; structures currently become complete immediately. Buildings have static collision.

Each building stores only resource items, up to its total unit capacity. Deposits transfer the entire selected stack if it fits. Withdrawals create one physical stack beside or above the building and deduct exactly that quantity from serialized contents. A blocked output leaves contents intact. Terrain edits near a footprint schedule one support recheck after the edit batch. If support falls below the declared fraction, the building is removed and each stored resource is released as physical stacks. This also applies to excavation and explosions through the shared terrain edit signal.

## Water simulation

Each 8 px cell stores 0–255 water units; one full cell is 255 units. Water uses a 30 Hz fixed step separate from rigid-body physics. Each step processes at most 512 queued cells, first transferring downward into available space, then equalizing left and right neighbors. Transfers preserve integer water units. A cell wakes with its neighbors when water moves or when nearby terrain changes; a settled lake has an empty queue and costs effectively no flow work. The map edges are sealed: water cannot enter or leave outside the 288×144-cell map.

Water is drawn as translucent teal chunk textures with a pale surface edge and a subtle animated shader. `LiquidType` reserves IDs 1–3 for water, lava, and oil; only water is simulated. `liquid_material_contact` is the hook for later terrain reactions. When new solid terrain covers water, the system first removes the water from that cell and seeks nearby open capacity. If no reachable capacity exists within the bounded search, the units stay in a displacement reserve and are retried when terrain changes. `total_water_units()` includes this reserve, so construction and terrain edits do not silently delete water. The character samples head, torso, and legs; at half submersion it switches to slower horizontal swimming, reduced downward motion, and jump-held upward movement.

## Terrain coordinates and rebuilding

Cell size is **8×8 world pixels**. The map has **288×144 cells** (2304×1152 px), split into **32×32 cell chunks** (45 chunks total). Local map origin is **(-800, -384)**. `world_to_cell` floors the offset world coordinate divided by 8; `cell_to_world` returns a cell's upper-left world position. Out-of-map queries return sky.

The byte array of material IDs is authoritative. `apply_edits` accepts an array of `{"cell": Vector2i, "material": id}` commands and returns counts of replaced solid material IDs. `remove_circle` and `paint_circle` use this API. Edits update cells immediately and mark touched chunks dirty, including neighboring chunks when a boundary cell changes. A single deferred flush rebuilds each dirty chunk once after the edit batch, outside the physics query/update phase.

Each chunk creates an RGBA image from its cells, shown through a nearest-filtered `Sprite2D`. Solid cells are merged into horizontal runs, then identical runs across rows become `RectangleShape2D` regions on one `StaticBody2D` per chunk. Rectangles end exactly at cell and chunk boundaries. Old shapes are detached before new shapes are installed in the deferred flush. Sky has no collision. Terrain changes that would overlap a character are skipped; the flush also moves any embedded terrain actor upward to the first free position within 32 cells. These rules avoid invisible stale collision after edits and preserve traversable seams.

## Verification and performance

The visual update was verified on 2026-10-04 with all six smoke tests, including the field guide and diagnostic toggles, plus rendered HUD, storage, construction, and landscape checks. At 1920×1080, the terrain edit benchmark averaged 14.68 ms per frame and 4.49 ms per rebuild, versus 8.13 ms and 2.50 ms for the original game in the same session. The updated water benchmark averaged 7.93 ms for the settled lake and 9.87 ms for flooding; worst frames were 50.73 ms and 21.46 ms respectively. The detailed terrain increases edit cost, and occasional frames still exceed 16.67 ms. Terrain artwork is cached in small tiles and the HUD redraws when its displayed state changes.

Run:

```sh
godot --headless --path . --script tests/sandbox_smoke.gd
godot --headless --path . --script tests/terrain_smoke.gd
godot --headless --path . --script tests/mining_inventory_smoke.gd
godot --headless --path . --script tests/explosion_smoke.gd
godot --headless --path . --script tests/liquid_smoke.gd
godot --headless --path . --script tests/construction_smoke.gd
godot --path . --resolution 1920x1080 --script tests/terrain_benchmark.gd
godot --path . --resolution 1920x1080 --script tests/explosion_benchmark.gd
godot --path . --resolution 1920x1080 --script tests/liquid_benchmark.gd
```

The six smoke tests passed on 2026-09-19 with Godot 4.4.1. The construction test checks all four structures, costs and invalid placement accounting, collection and supply, storage withdrawal, and collapse after excavation. The scene also ran in a 1920×1080 window for 120 frames with exit code 0. The earlier liquid test checks that the large lake settles, the player swims, solid placement preserves volume, excavation wakes the lake and fills the mine floor, water crosses a chunk seam, and enclosed displaced water returns when space reopens. The windowed liquid benchmark runs 180 rendered frames for each of a settled lake and flooding mine: settled average 4.66 ms, worst 7.61 ms, zero frames over 16.67 ms; flooding average 4.81 ms, worst 33.91 ms, one frame over 16.67 ms. Peak liquid update was 1.77 ms while flooding. Earlier explosion benchmark: average 5.80 ms, worst 30.45 ms, two frames over 16.67 ms. Reference desktop: AMD Ryzen 7 7800X3D, 30 GiB RAM, AMD Radeon integrated graphics via WSLg D3D12/Mesa 22.3.6. Benchmark results and known limits are recorded in the [milestone plan](specs/IMPLEMENTATION_PLAN.md).

This remains a small static sample map with one character. Wood is starter stock until the wood source arrives in milestone 7; production and refining are also milestone 7 work. Collapsed structures release contents but do not refund construction costs. Cell edges are visible on slopes, and the step assist is tuned to this 8 px grid. The debug brush edits any material equally and does not produce mining yields. A mined resource pile may contain more than one inventory stack; E then takes as many units as fit. At the 96-pile limit, new mining yields merge into an existing pile of the same item or wait in the session until a slot opens. Loose item health is 100 and sufficiently strong blasts can destroy them. Water has no buoyancy or drag effect on loose rigid bodies yet. The benchmark covers this sample lake and mine; it does not cover the larger water/object/worker stress scene planned for milestone 10. Windowed frame spikes above 16.67 ms remain in the measured run.
