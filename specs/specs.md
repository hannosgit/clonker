You are a senior game-engine programmer and gameplay designer.

Build a playable 2D game inspired by the gameplay systems of **Clonk Rage**, but do NOT copy proprietary graphics, sounds, maps, names, UI artwork, or other copyrighted game assets. Create original placeholder assets and generic names. Reproduce the gameplay ideas and systemic interactions rather than making a pixel-for-pixel asset clone.

Use **Godot 4.x with GDScript** unless there is a strong technical reason to implement a particular subsystem differently.

The finished game should feel like a mixture of:

* 2D platforming
* sandbox physics
* mining
* base building
* resource management
* production chains
* environmental simulation
* physics-based combat
* Worms-like terrain destruction
* Settlers-like settlement development

## Core gameplay

The player controls small humanoid workers directly in a 2D side-view world.

The player should be able to:

* walk
* run
* jump
* climb
* swim
* fall
* dig
* mine
* pick up objects
* carry objects
* drop objects
* throw objects
* use tools
* interact with structures
* construct buildings
* collect resources
* manufacture items
* fight enemies
* switch between multiple crew members

Movement should feel responsive but physical.

Characters should interact naturally with slopes, tunnels, buildings, water, loose objects, explosions, and other characters.

## Destructible terrain

This is the most important technical feature.

Implement a dynamic pixel-based or grid-based terrain system.

The world consists of different materials such as:

* sky
* earth
* rock
* sand
* coal
* ore
* gold
* snow
* ice
* water
* lava

Each terrain cell/material should have properties such as:

* density
* solidity
* dig resistance
* blast resistance
* value
* color/visual type
* liquid behavior
* temperature where relevant

The terrain must support runtime modification.

Players must be able to create tunnels by digging.

Explosions must carve circular or irregular holes from the terrain.

Mining should remove terrain and optionally spawn collectible material chunks.

Do not model the terrain as thousands of individual physics bodies. Design an efficient representation such as chunks, pixel masks, grids, generated collision polygons, or another appropriate technique.

Only rebuild collision data in modified regions.

## Liquid simulation

Implement lightweight cellular liquid simulation.

At minimum support:

* water falling downward
* water spreading sideways
* water flowing through player-created tunnels
* water collecting in cavities
* characters swimming when submerged

Design the simulation so large bodies of liquid do not destroy performance.

Keep liquid simulation separate from rigid-body physics.

The architecture should eventually support other liquids such as lava and oil.

## Terrain interaction

Important emergent situations should naturally work.

Examples:

A player digs underneath a lake and accidentally floods their mine.

An explosion opens a tunnel connecting two cave systems.

A player mines underneath an enemy building.

Water flows down a newly created shaft.

A bridge spans a gap created by mining.

An explosive charge exposes previously inaccessible gold.

Design systems around interactions rather than scripted special cases.

## Crew system

Each player owns a crew.

Start with 3 crew members.

Allow the player to switch the actively controlled crew member.

Each crew member has:

* health
* stamina or action state
* inventory
* current tool
* movement state
* owner
* position
* velocity

Inactive crew members should remain in the world.

Basic AI commands can eventually allow commands such as:

* follow
* wait
* defend
* move here

For the first implementation, direct switching between crew members is sufficient.

## Inventory

Use a small physical inventory.

Characters should be able to hold objects such as:

* shovel
* pickaxe
* axe
* hammer
* torch
* explosive
* rock
* wood
* ore
* metal
* weapon

Prefer physical world objects over abstract inventory counters where practical.

Dropped objects should exist in the game world and interact with gravity.

## Mining

Different tools should work better against different materials.

Example:

Shovel:
good against earth and sand.

Pickaxe:
good against rock and ore.

Explosive:
destroys a larger area but is dangerous.

Mining valuable terrain should produce usable resources.

Example loop:

dig tunnel
→ discover ore
→ mine ore
→ transport ore
→ refine material
→ construct equipment
→ access deeper or more dangerous areas

## Settlement system

Players can construct a settlement.

Start with these buildings:

### Base

Stores resources and serves as the settlement center.

### Workshop

Produces tools and simple equipment.

### Furnace

Turns ore into metal.

### Sawmill

Processes wood.

### Elevator

Moves characters and materials vertically through mines.

### Generator

Produces power.

### Storage

Stores physical resources.

Buildings require materials.

Example recipes:

Workshop:
10 wood
5 stone

Furnace:
10 stone
5 metal

Elevator:
10 wood
10 metal

Keep recipes data-driven rather than hard-coded.

## Construction

Buildings should have placement rules.

Check:

* sufficient terrain support
* collision with existing structures
* required resources
* valid construction area

Display a translucent placement preview.

Construction may initially happen instantly.

Later the architecture should allow crew members to physically construct buildings over time.

## Production chains

Support simple production chains.

Examples:

wood → processed wood

ore → metal

coal + ore → refined metal

metal + wood → tools

resources → explosives

Buildings should expose recipes through data files/resources so new recipes can be added without modifying engine code.

## Economy

Include a simple settlement currency.

Gold or valuable minerals can be converted into currency.

Currency can be used to purchase basic equipment from the base.

The long-term economic loop should be:

explore
→ mine
→ transport
→ process
→ build
→ improve equipment
→ reach more resources

## Combat

Combat should use the same physical world simulation as mining.

Implement:

* melee weapon
* throwable rock
* bow or simple projectile weapon
* timed explosive
* explosive projectile

Projectiles should interact with terrain.

Explosions should:

* damage characters
* apply knockback
* destroy terrain
* affect loose objects

This should allow players to use weapons for both combat and environmental manipulation.

## Physics objects

Loose resources and equipment should exist as physical entities.

Objects should:

* fall
* slide
* collide
* be picked up
* be thrown
* react to explosions

Avoid unnecessarily expensive simulations.

Use sleeping/deactivation for distant stationary objects where appropriate.

## World generation

Create procedurally generated maps.

Generate:

* surface
* underground layers
* caves
* resource deposits
* water pockets
* rock formations

Use deterministic seeds.

Display the seed so the same map can be recreated.

Start with one biome:

Temperate Valley.

Later support:

* Arctic
* Desert
* Jungle
* Volcanic
* Underground
* Islands

The biome system should be data-driven.

## Camera

Implement a smooth 2D camera.

Features:

* follows active crew member
* slight look-ahead based on movement
* zoom in/out
* map boundaries
* camera shake from nearby explosions

Do not overdo camera shake.

## Game modes

Design objectives as modular components.

Initially implement:

### Settlement

Reach a target amount of wealth.

### Mining

Collect a specified amount of a target mineral.

### Survival

Keep at least one crew member alive while surviving environmental hazards.

Architecture should later support:

* deathmatch
* last crew standing
* capture the flag
* racing
* cooperative missions
* exploration scenarios

Objectives must not be hard-coded into the main game loop.

## UI

Create a functional original UI.

HUD should display:

* active crew member
* health
* selected item/tool
* inventory
* settlement resources
* objective progress

Include:

* pause menu
* settings
* scenario selection
* seed entry
* restart
* return to menu

Keep the visual design original rather than recreating Clonk Rage's UI.

## Controls

Default keyboard controls:

A / D — move

Space — jump

S — crouch/interact depending on context

Left mouse — use selected item

Right mouse — alternate action

Mouse wheel — change inventory item

1–9 — select inventory slot

Tab — switch crew member

E — interact

B — build menu

F — throw/drop context action

Esc — pause

Controls must be remappable.

## Multiplayer architecture

Do NOT implement full internet multiplayer before the single-player simulation is stable.

However, design important gameplay state so future deterministic or server-authoritative multiplayer is possible.

Separate:

* presentation
* simulation
* user input
* game state

Do not bury gameplay state inside UI nodes.

Avoid frame-rate-dependent gameplay logic.

Use fixed simulation ticks where useful.

After the single-player MVP is reliable, add local multiplayer or LAN multiplayer as a later milestone.

## Modding architecture

One of the important goals is extensibility.

Make these systems data-driven:

* materials
* items
* tools
* buildings
* production recipes
* objectives
* biomes
* scenarios

Prefer Godot Resources, JSON, or another clean declarative representation.

Adding a new tool or building should ideally require creating data and a script/component rather than editing a large central switch statement.

## Code architecture

Use clear systems such as:

GameManager

WorldManager

TerrainSystem

TerrainChunk

MaterialDatabase

LiquidSystem

CharacterController

CrewManager

InventoryComponent

Item

Tool

BuildingSystem

ProductionSystem

ResourceSystem

ObjectiveSystem

ExplosionSystem

ProjectileSystem

ScenarioManager

SaveSystem

Use signals/events to reduce tight coupling.

Avoid enormous singleton scripts.

Prefer components and composition.

Document complicated algorithms, especially terrain and liquid simulation.

## Performance

Target:

1920×1080
60 FPS
mid-range desktop hardware

The terrain simulation must remain performant with:

* large maps
* many terrain modifications
* liquids
* dozens of objects
* several characters
* repeated explosions

Profile before optimizing blindly.

Use chunking and dirty-region updates where appropriate.

Include a debug overlay showing:

* FPS
* active physics objects
* terrain chunks
* dirty chunks
* liquid cells being simulated

## Visual style

Use simple ORIGINAL placeholder art.

Aim for:

* readable silhouettes
* colorful 2D graphics
* slightly whimsical industrial/fantasy atmosphere
* clear terrain materials
* visually obvious interactive objects

Do not copy Clonk characters, sprites, textures, logos, menus, sounds, maps, or other protected artwork.

Simple geometric or hand-drawn placeholders are acceptable.

Gameplay systems are more important than polished graphics.

## Audio

Use original placeholder audio only.

Include hooks for:

* digging
* footsteps
* jumping
* splashes
* mining
* building
* explosions
* weapon impacts
* machinery
* ambient cave sounds

Audio implementation can come after the core gameplay loop works.

## Save system

Save:

* terrain modifications
* characters
* character health
* loose objects
* buildings
* resource inventories
* objective progress
* world seed

Use a versioned save format so future schema changes can be migrated.

## Development strategy

Do not attempt the entire game simultaneously.

Build it vertically.

### Milestone 1 — Character Sandbox

Create:

* test scene
* solid terrain
* player movement
* jumping
* camera
* collision

Deliver a playable test immediately.

### Milestone 2 — Destructible Terrain

Add:

* terrain chunks
* digging
* terrain collision regeneration
* multiple materials
* debug terrain tools

This milestone is critical.

Verify there are no collision gaps or severe performance problems before continuing.

### Milestone 3 — Mining

Add:

* shovel
* pickaxe
* resource terrain
* collectible resources
* inventory

Create the first real gameplay loop.

### Milestone 4 — Explosions

Add:

* explosive item
* blast terrain deformation
* damage
* knockback
* chain reactions

### Milestone 5 — Liquids

Add:

* water
* gravity flow
* lateral spreading
* pools
* flooding tunnels
* swimming

### Milestone 6 — Settlement

Add:

* building placement
* base
* workshop
* furnace
* resource storage

### Milestone 7 — Production

Add:

* recipes
* processing
* tools
* equipment manufacturing

### Milestone 8 — Crew

Add:

* multiple characters
* switching
* crew persistence

### Milestone 9 — Scenario

Create one polished scenario:

"Gold Rush"

Goal:
accumulate 500 units of wealth.

World:

* grassy surface
* underground caves
* coal deposits
* iron deposits
* gold deposits
* underground lake

Starting equipment:

* 3 crew members
* shovel
* pickaxe
* basic settlement base

The scenario must be fully playable from start to victory.

### Milestone 10 — Polish

Add:

* UI
* sounds
* improved animation
* particles
* save/load
* settings
* control rebinding
* performance profiling

Only after these milestones should multiplayer be considered.

## Required engineering workflow

Work directly in the repository.

Before making major architectural changes:

1. inspect the existing project
2. understand the current architecture
3. explain briefly what you are changing
4. implement it
5. run the project/tests
6. fix errors
7. report what changed

Do not merely generate large amounts of untested code.

After every milestone, run the game and ensure the previous milestones still function.

If automated tests are practical, add tests for pure logic such as:

* material behavior
* recipes
* inventory
* damage calculations
* procedural generation
* save serialization

## First task

Start by examining the repository.

If the repository is empty, initialize a clean Godot 4.x project.

Then implement ONLY Milestone 1.

Create a playable sandbox with:

* 2D side-view character
* responsive left/right movement
* jumping
* gravity
* collision
* simple test terrain
* smooth camera
* debug FPS display

Use simple original placeholder graphics.

Organize the code so the destructible terrain system from Milestone 2 can replace the temporary terrain without rewriting the character controller.

Run the project and fix errors before proceeding.

After completing Milestone 1, provide:

1. files created/modified
2. architecture overview
3. controls
4. how to run the game
5. known limitations
6. recommended implementation strategy for Milestone 2

Do not begin Milestone 2 until Milestone 1 is working.
