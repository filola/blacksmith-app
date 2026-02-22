# AGENTS.md

## Project Context
- Engine: Godot 4.6
- Language: GDScript
- Target: Web build (HTML5/WebAssembly)

## Structure Overview
- `autoload/`: Singleton managers and global state (autoloads).
- `scenes/`: Scene files (`.tscn`) and scene organization.
- `scripts/`: Shared scripts and gameplay logic.
- `resources/`: Data files and assets (including JSON-driven configs).
- `build/`: Export/output artifacts for web builds.
- `export_presets.cfg`: Export configuration for targets.
- Root `index.*` files: Web export entry points and assets.

## Coding Conventions
- Signals:
  - Declare signals at the top of scripts, grouped by purpose.
  - Emit signals from state-changing methods, not from callers.
- Autoloads:
  - Keep global state and cross-scene coordination in `autoload/` singletons.
  - Access autoloads via their registered names, avoid ad-hoc globals.
- Data-driven flow (JSON):
  - Keep gameplay tuning and tables in JSON under `resources/`.
  - Load and validate JSON in autoloads or dedicated loaders.
  - Prefer adding new content via JSON rather than hard-coded values.
