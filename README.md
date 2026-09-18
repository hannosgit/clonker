# Clonker character sandbox

This is milestone 1 of the [implementation plan](specs/IMPLEMENTATION_PLAN.md): a playable 2D movement and collision sandbox built with **Godot 4.4.1** (official build `49a5bc7b6`). Open `project.godot` in Godot 4.4.1 and press **F6** with `scenes/sandbox.tscn` open, or press **F5** to run the project. From a terminal, run `godot --path .` with Godot 4.4.1 on your path.

Milestone files: `project.godot` defines the project and Input Map; `scenes/` holds the playable sandbox, character, world, and overlay; `scripts/` holds their behavior; `tests/sandbox_smoke.gd` verifies gameplay; `data/` and `assets/` are reserved for later content. This README and the milestone checklist record the implementation and verification.

| Action | Default keys |
| --- | --- |
| Move | A / D or Left / Right |
| Jump | Space, W, or Up (hold for a higher jump) |
| Reset to start | R |

The course has a flat starting area, a climbable slope, raised platforms, a wall, and a pit. The character respawns automatically after falling below the course. The overlay shows FPS and the controls.

## Architecture

- `scenes/sandbox.tscn` and `scripts/game_session.gd` own the session, spawn point, and reset behavior.
- `scenes/sandbox_world.tscn` and `scripts/sandbox_world.gd` define temporary static world geometry.
- `scenes/character.tscn` and `scripts/character_controller.gd` own physics movement and camera follow. The controller queries only Godot collision; it has no reference to the temporary world.
- `scenes/debug_overlay.tscn` and `scripts/debug_overlay.gd` own the FPS presentation.

Movement and jump are Input Map actions in `project.godot`, so their bindings can be changed in the Godot editor now and exposed in a settings menu later. Movement, gravity, and jumping are calculated in `_physics_process`. Coyote time, jump buffering, and variable jump height make the controls forgiving without changing the collision model.

## Verification and limits

Run the focused headless smoke check with `godot --headless --path . --script tests/sandbox_smoke.gd`. On 2026-09-18, it passed ground contact, slope ascent, platform jump, wall collision, pit fall, camera movement, input bindings, and FPS overlay checks with Godot 4.4.1. The project also launched in a window and exited cleanly after a short run. Manual play is still useful for judging feel. This milestone has only static test terrain, one character, and a reset action; terrain editing and generated collision belong to milestone 2.

For milestone 2, introduce a chunked cell grid behind a world terrain scene, derive both visuals and static collision from dirty chunks, and swap that scene into `sandbox.tscn`. Keep the `CharacterBody2D` controller collision driven. Measure chunk rebuild and physics costs before choosing cell and chunk sizes.
