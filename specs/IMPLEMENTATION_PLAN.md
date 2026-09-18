# Game implementation plan

Based on [specs.md](specs.md). This checklist describes what to implement, how to approach it, and when each step is ready to start. The workspace currently contains the specification and no Godot project.

## How to use this plan

- Work through milestones 1–10 in order. Start the next milestone only after the current milestone passes its completion checks.
- Keep a playable scene throughout development. At every milestone, run the game and replay earlier interactions to catch regressions.
- Use Godot 4.x and GDScript, original placeholder assets, and small components. Record the exact Godot version when initializing the project.
- Treat completion checks as the schedule: dates require measured implementation effort and an agreed team size.
- Milestones 1–5 prove the simulation; 6–8 establish the settlement loop; 9 delivers the playable single-player MVP; 10 makes that MVP reliable and usable. The remaining single-player features follow in steps 11–13.
- For each milestone, record changed files, architecture decisions, controls, run instructions, verification results, and remaining limitations.

## 1. Character sandbox

**Start when:** This plan is accepted for implementation. This is the first coding task.

- [x] Initialize a clean Godot project with folders for scenes, scripts, data, assets, and tests.
- [x] Separate scenario/session management, world content, character control, and presentation. Introduce systems as they become necessary rather than scaffolding every planned system immediately.
- [x] Define movement and jump actions in Godot's Input Map so controls can be rebound later.
- [x] Build a small test scene with flat ground, slopes, platforms, walls, and a pit using temporary static terrain.
- [x] Implement a `CharacterBody2D` controller with responsive left/right movement, jumping, gravity, and collision in the physics tick.
- [x] Add original geometric character graphics, a smooth following camera, and an FPS display.
- [x] Keep the controller dependent on normal world collision, without references to temporary terrain nodes, so generated terrain can replace them later.
- [x] Document how to launch the sandbox and its controls.

**Complete when:** The game launches without errors; the character can traverse slopes, jump onto platforms, collide with walls, and fall into the pit; the camera follows smoothly. Deliver and verify this sandbox before beginning terrain work.

**Milestone 1 verification (2026-09-18):** Godot 4.4.1 (`49a5bc7b6`) launched the scene in a window and exited with code 0. The headless runtime and `tests/sandbox_smoke.gd` passed ground, slope, platform, wall, pit, input binding, overlay, and camera checks. See [README.md](../README.md) for files, controls, run instructions, architecture, and limits.

## 2. Destructible terrain

**Start when:** Milestone 1 works and its controls feel usable.

- [ ] Define material data with stable IDs, solidity, density, dig/blast resistance, value, appearance, and optional liquid/temperature properties. Start with sky, earth, and rock.
- [ ] Prototype a chunked cell grid as the authoritative terrain representation. Use generated textures for rendering and static collision geometry for solid regions; avoid a physics body per cell.
- [ ] Choose cell resolution, chunk dimensions, map size, and a reference desktop using measurements from the prototype. Record them as the baseline benchmark configuration.
- [ ] Implement terrain query and edit operations, including circular removal and batched edits. Return material removal information for later mining yields.
- [ ] Regenerate rendering and collision only for dirty chunks and affected boundaries. Merge edits to avoid repeated rebuilds in one update.
- [ ] Apply collision updates at safe physics boundaries and handle objects or characters intersecting newly updated geometry.
- [ ] Add a debug digging brush and material painting tools, then replace the sandbox's temporary terrain.
- [ ] Expand the overlay with terrain chunk counts, dirty chunks, and rebuild timings.
- [ ] Document coordinate conversion, collision generation, chunk seams, and edit scheduling.

**Complete when:** Digging creates traversable tunnels, including across chunk boundaries. Narrow passages, slopes, and repeated edits produce no collision gaps, invisible barriers, or persistent stale collision. Profile editing at 1920×1080 against the 60 FPS target before proceeding.

## 3. Mining, physical items, and inventory

**Start when:** Terrain editing and collision regeneration pass milestone 2.

- [ ] Create declarative item/tool definitions and a shared tool action interface.
- [ ] Implement shovel and pickaxe actions with reach, action timing, and material-specific effectiveness.
- [ ] Add coal, ore, and gold deposits. Convert mined cells into resource chunks with defined yields and limits on spawned object counts.
- [ ] Implement physical resource and equipment objects that fall, slide, collide, sleep when stationary, and can be picked up, carried, dropped, and thrown.
- [ ] Add a small per-character inventory with item selection and explicit transfers between held and world states to prevent duplication.
- [ ] Add a minimal HUD for health, selected item, and inventory. Expose active physics object counts in the overlay.
- [ ] Test inventory capacity and transfers, tool/material effectiveness, and resource yield accounting as pure logic where practical.

**Complete when:** The player can dig to ore, mine it with the appropriate tool, collect it, transport it, and drop it elsewhere. Repeated pickup/drop actions neither duplicate nor lose resources.

## 4. Explosions and damage

**Start when:** Tools, items, and resource removal use shared terrain operations.

- [ ] Add health and a reusable damage/impulse interface for characters and damageable objects.
- [ ] Implement a throwable timed explosive with a fuse and one shared explosion operation.
- [ ] Use material blast resistance to carve terrain; damage characters and apply knockback to characters and loose objects.
- [ ] Queue chain reactions so each explosive detonates once and large chains do not cause recursive processing spikes.
- [ ] Add restrained camera shake, a visible blast effect, and a simple recovery/restart path after death.
- [ ] Test damage falloff, single detonation, and chain reaction handling.

**Complete when:** A blast opens a tunnel between caves, exposes resources, moves objects, and can injure the player. Consecutive blasts across chunk boundaries leave collision correct and remain within the measured performance budget.

## 5. Water and swimming

**Start when:** Terrain edits and explosions reliably notify affected world regions.

- [ ] Implement `LiquidSystem` separately from rigid-body physics, using cellular water amounts and fixed simulation steps.
- [ ] Support downward flow, lateral spreading, and settling in cavities. Define world-edge behavior explicitly.
- [ ] Update active cells or regions with a bounded per-tick budget. Wake settled regions when neighboring terrain or water changes.
- [ ] Preserve water volume during transfers; define what happens when construction or later terrain changes displace water.
- [ ] Add submersion queries and swimming movement to the character controller.
- [ ] Reserve liquid type IDs and material interaction hooks for later lava/oil support without implementing those liquids yet.
- [ ] Show simulated liquid cell counts and liquid update timing in the debug overlay.
- [ ] Test closed-basin volume conservation, flow across chunks, and settled-region reactivation.

**Complete when:** Digging below a lake floods a mine; water falls through a new shaft and collects below; characters swim when submerged. A large settled lake consumes little simulation time and wakes correctly after excavation.

## 6. Construction and settlement storage

**Start when:** Physical resource transport and flooding work together.

- [ ] Define building data for footprint, support rules, required materials, storage capacity, and interaction points.
- [ ] Implement a translucent placement preview with clear feedback for invalid placement or missing resources.
- [ ] Validate terrain support, overlap with structures/characters, allowed construction area, and resource availability before committing placement and material consumption together.
- [ ] Add the base, workshop, furnace, and storage. Use instant construction initially, with construction state separate from placement validation so timed work can be added later.
- [ ] Implement resource deposits and withdrawals with explicit accounting. Stored resources can be serialized contents that return to physical objects when withdrawn.
- [ ] Resolve progression bootstrapping: provide starting metal, a starter furnace, or an alternative initial recipe so a furnace requiring metal can actually be built.
- [ ] Define and implement what happens when digging removes a building's support; recheck support after relevant terrain edits.

**Complete when:** The player can collect materials, place and supply a building, and store/retrieve resources. Invalid placements consume nothing. Undermining a building produces the defined support behavior, and the starting supplies allow progression to refining.

## 7. Production and economy

**Start when:** Buildings can reliably accept and return resources.

- [ ] Define recipes as Godot Resources or another consistent declarative format with inputs, outputs, duration, and compatible buildings.
- [ ] Add production jobs with input reservation, progress, output capacity checks, and defined cancellation behavior.
- [ ] Implement ore → metal, coal + ore → refined metal, metal + wood → tools, and resources → explosives.
- [ ] Add a basic renewable or finite wood source and axe interaction, then add the sawmill and wood → processed wood recipe.
- [ ] Add currency, gold conversion, and basic equipment purchases at the base. Specify how wealth is counted so transferring or selling resources cannot count the same value twice.
- [ ] Show building recipes, resource requirements, production progress, and settlement resources in a functional interface.
- [ ] Test recipe validation, insufficient inputs, blocked outputs, cancellation, purchases, and wealth accounting.

**Complete when:** The player can mine, transport, refine, manufacture equipment, and use that equipment to access more resources. Gold conversion and purchases work, and the chain has no unreachable initial requirements.

## 8. Three-member crew

**Start when:** Inventory, health, tools, and movement state belong to individual characters.

- [ ] Add `CrewManager` with ownership, three starting members, and a stable active-member reference.
- [ ] Implement Tab switching and transfer camera/input focus to the selected member.
- [ ] Preserve each member's health, action state, inventory, tool, position, and velocity while inactive.
- [ ] Keep inactive crew physically present and subject to water, gravity, collisions, and damage. Waiting is sufficient for initial inactive behavior.
- [ ] Handle active-member death, switching to survivors, and loss of the entire crew.
- [ ] Update the HUD to identify the active member and show crew status.

**Complete when:** Switching among three workers preserves their state and allows resource handoffs. Inactive workers remain affected by the world, and losing the active worker does not break input or camera control.

## 9. Gold Rush: complete single-player MVP

**Start when:** The settlement loop and crew system work together.

- [ ] Add data-driven biome/scenario definitions and deterministic seeded generation for Temperate Valley: surface, layers, caves, rock formations, coal, ore, gold, and water pockets.
- [ ] Give generation its own seeded random stream. Validate safe crew spawn, base placement, and accessible starting resources.
- [ ] Define the map/seed version used by generation so future generator changes can be handled by saves.
- [ ] Introduce modular objective components and implement the settlement objective: accumulate 500 wealth.
- [ ] Configure Gold Rush with three workers, shovel, pickaxe, base, and the bootstrap resources chosen in milestone 6.
- [ ] Provide minimal scenario start, visible seed, objective progress, victory/defeat, and restart controls.
- [ ] Test repeatability for identical seeds and play several fixed seeds from start to victory, including a run where excavation floods a mine.

**Complete when:** A fresh player can launch Gold Rush, understand the objective, grow a settlement, earn 500 wealth, and reach victory. The same seed and generator version recreate the same initial map. This is the playable MVP checkpoint.

## 10. Save/load, usability, and performance

**Start when:** Gold Rush is playable from start to victory.

- [ ] Implement a versioned save format and explicit migration/rejection behavior for older or unsupported versions.
- [ ] Save the world seed and generation version, terrain changes, liquid state, crew and health, ownership, inventories, loose objects, buildings, production jobs, currency, and objective progress. Preserve pending gameplay state such as explosive fuses where relevant.
- [ ] Capture a consistent simulation snapshot, restore stable entity references, and write saves atomically.
- [ ] Add round-trip checks using an edited, flooded, populated world; confirm loading and continuing gives the expected gameplay state.
- [ ] Complete the HUD, pause menu, settings, scenario selection, seed entry, restart, and return-to-menu flow.
- [ ] Implement persisted control rebinding with conflict handling and reset-to-defaults. Resolve shared inputs such as item selection versus camera zoom with explicit bindings.
- [ ] Complete camera look-ahead, zoom limits, world boundaries, and adjustable shake.
- [ ] Add original placeholder audio and hooks for movement, digging, mining, water, construction, explosions, weapons, machinery, and cave ambience. Improve animation and particles after gameplay is reliable.
- [ ] Profile a documented stress scene with large terrain, active water, repeated explosions, dozens of objects, and multiple workers. Record FPS/frame times, physics bodies, chunks, dirty chunks, and simulated liquid cells on the reference hardware.
- [ ] Fix measured bottlenecks and replay milestones 1–9 after changes. Document any remaining limits on map size or active simulation.

**Complete when:** Saving and loading preserves gameplay progress; menus and rebinding work; Gold Rush remains completable; the agreed stress scene sustains the 1920×1080, 60 FPS target on the reference desktop. Record actual measurements rather than assuming the target is met.

## 11. Complete the remaining movement, building, and environmental features

**Start when:** Milestone 10 is reliable. Keep each addition separately playable and verified.

- [ ] Finish running, climbing, crouching/context actions, and any missing carrying/tool interactions. Add functional hammer and torch behavior.
- [ ] Add the elevator for transporting workers and resources, including platform collision and obstruction behavior.
- [ ] Add the generator and define a minimal power producer/consumer model for applicable machinery.
- [ ] Add constructible bridges and verify they span excavated gaps.
- [ ] Complete the listed material definitions: sand, snow, ice, and lava in addition to existing terrain and water. Specify which are static materials and which need movement or temperature simulation; implement their chosen gameplay behavior.
- [ ] Add lava through the liquid interface and introduce environmental damage/temperature interactions where relevant. Keep oil and additional biomes as extensions unless explicitly brought into scope.
- [ ] Verify unsupported buildings, flooding, elevators, bridges, and explosions interact through shared rules.

**Complete when:** The full initial movement and building roster is usable, all specified terrain materials are represented, and the new interactions preserve terrain collision, resource accounting, and save/load behavior.

## 12. Complete combat and the initial game modes

**Start when:** The single-player simulation is stable. Combat can precede step 11 if it uses only completed systems; final integration requires both.

- [ ] Add a melee weapon, impact damage for thrown rocks, a bow or simple projectile weapon, and an explosive projectile. Reuse the existing damage and explosion operations.
- [ ] Implement terrain-aware projectile collision and a basic enemy with readable behavior. Check fast projectiles for tunneling through thin terrain.
- [ ] Add a modular Mining objective with a specified mineral/amount and explicit rules for when collection counts.
- [ ] Add a modular Survival objective with environmental hazards, a defined survival duration or victory condition, and defeat when no crew survives.
- [ ] Add selectable scenarios for Mining and Survival, with restart and save/load support.
- [ ] Run an integrated regression pass through all three modes, every initial weapon/building, and the emergent situations described in the specification.

**Complete when:** Settlement, Mining, and Survival are playable to their defined outcomes, enemies can be fought with all initial weapon types, and weapons also modify the environment through the same simulation rules.

## 13. Validate extensibility and package the single-player game

**Start when:** Steps 1–12 satisfy their completion checks.

- [ ] Document the data formats for materials, items, tools, buildings, recipes, objectives, biomes, and scenarios.
- [ ] Validate definitions at load time with useful errors for missing IDs, invalid recipes, and incompatible components.
- [ ] Prove extensibility by adding a sample tool/building and a scenario through data plus a small component, without changing a central gameplay switch statement.
- [ ] Prepare a desktop export, controls reference, save location documentation, and known-limitations list.
- [ ] Run the exported game and complete a scenario outside the editor.

**Complete when:** The full initial single-player scope is playable in an exported build and content can be extended using the documented data/component model.

## 14. Later extensions and multiplayer

**Start when:** At minimum, milestones 1–10 are verified. Prefer completing the initial single-player scope before expanding it.

- [ ] Prioritize crew commands (follow, wait, defend, move here), timed construction, additional biomes/liquids, and extra objective types as separate increments.
- [ ] Choose local multiplayer or LAN as the first multiplayer target and define ownership, camera, input, and shared-world behavior before coding it.
- [ ] For LAN, prototype server authority for input commands, terrain edits, liquid state, objects, inventories, and objectives. Do not assume Godot rigid-body physics is deterministic across machines.
- [ ] Verify joining, state synchronization, authority checks, and recovery from disconnects before considering internet multiplayer.

**Throughout development:** Keep authoritative gameplay state outside UI nodes, use stable IDs for persistent entities, express input as gameplay actions, and use physics/fixed ticks for simulation. These foundations support saves, testing, and later networking without requiring networking infrastructure in the MVP.
