# Repository Guidelines

## Project Structure & Module Organization

Clonker is a Godot 4.4.1 settlement sandbox written in GDScript. `project.godot` launches `scenes/sandbox.tscn`.

- `scripts/`: gameplay systems, catalogs, character control, HUD, and procedural artwork.
- `scenes/`: session, terrain, character, items, explosives, and diagnostics.
- `data/`: JSON definitions for materials, items, and buildings.
- `assets/`: the water shader; most visuals are generated in code.
- `tests/`: standalone smoke tests and performance benchmarks.
- `specs/`: design specification and milestone implementation plan. `README.md` documents controls, architecture, and measured limitations.

## Build, Test, and Development Commands

Use Godot 4.4.1, the documented reference version. Run commands from the repository root:

- `godot --editor --path .`: open the project for editing and resource imports.
- `godot --path .`: run the playable sandbox; F5 also runs it from the editor.
- `godot --headless --path . --script tests/construction_smoke.gd`: run one smoke test; substitute another test filename as needed.
- `godot --path . --resolution 1920x1080 --script tests/terrain_benchmark.gd`: measure rendered performance. Equivalent benchmarks cover explosions and liquids.

No separate package installation or build script is configured.

## Coding Style & Naming Conventions

Follow existing GDScript: tabs for indentation, explicit types where useful, `:=` for inferred values, and two blank lines between functions. Use `snake_case` filenames, functions, and variables; `PascalCase` class names; `UPPER_SNAKE_CASE` constants; and leading underscores for internal members. Use `res://` resource paths. No formatter or linter is configured.

Keep catalog definitions in JSON and preserve stable IDs. Route terrain changes through the shared edit API and defer collision rebuilds as existing systems do.

## Testing Guidelines

Tests extend `SceneTree` and use custom checks rather than an external framework. Name behavioral tests `tests/<feature>_smoke.gd` and measurements `tests/<feature>_benchmark.gd`.

Before submitting gameplay changes, run all six smoke tests: sandbox, terrain, mining/inventory, explosion, liquid, and construction. Verify affected interactions in the playable scene. For rendering or simulation changes, run relevant windowed benchmarks at 1920×1080 and record hardware, timings, and frame spikes. No numerical coverage threshold is configured.

## Commit & Pull Request Guidelines

History uses short subjects such as `milestone 6` and `Improve woodland visuals and gameplay HUD`; no strict prefix convention is established. Prefer concise, action-oriented subjects.

PRs should describe behavior changes, relevant milestones or issues, verification commands and results, and remaining limitations. Include screenshots for visual changes. Update README documentation and milestone records when controls, architecture, or performance change. Keep generated `.godot/` files out of commits.
