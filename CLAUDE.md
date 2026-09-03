# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

IBBD Prototype Base is a starter/template project for Godot 4.7 (Forward Plus rendering, Jolt Physics for 3D) intended as a common launchpad for rapid gameplay prototyping. It is currently in a very early, mostly-empty scaffold state — `prototypes/` and `systems/` exist only as placeholder directories (`.gitkeep`) for prototype-specific scenes and shared systems that will be added over time.

## Running and editing

This is a Godot Engine project — there is no CLI build/test/lint pipeline. Open and run it through the Godot 4.7 editor (macOS app path configured in `.vscode/settings.json` as `/Applications/Godot.app`). The main scene is `_scenes/main.tscn` (set via `run/main_scene` in `project.godot`).

To run headless from the terminal (e.g. to sanity-check the project loads):
```
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
```

There are no automated tests in this repo.

## Directory layout

- `_scenes/` — top-level `.tscn` scene files (prefixed with `_` to sort above gameplay content in the editor's FileSystem dock).
- `_scripts/` — GDScript files, mirroring the scene tree. A script for a scene named `X.tscn` is named `X.tscn.gd` and lives alongside a matching `.uid` file (Godot 4's script UID references — do not hand-edit `.uid` files).
- `_assets/` — raw art/audio source assets (`sprites/`, `audio/`, `fonts/`).
- `prototypes/` — intended home for individual gameplay prototypes built on this base (currently empty).
- `systems/` — intended home for shared/reusable gameplay systems (currently empty).

## Architecture

`main.tscn` is the root scene: a `Node2D` (`_scripts/main.tscn.gd`) with two children — a `game` node (empty placeholder where prototype content is expected to be added) and an instance of `toolkit.tscn`.

`toolkit.tscn` (`_scripts/tool_kit/ibbd_toolkit.gd`) is a `CanvasLayer` that provides an always-on developer toolkit, independent of the game's pause state (`process_mode = PROCESS_MODE_ALWAYS`). It listens for dedicated `tool_*` input actions (defined in `project.godot`, distinct from the `player_*` gameplay actions) and currently supports:
- `tool_toggle_hud` — show/hide the debug HUD
- `tool_restart` — reload the current scene
- `tool_pause` — toggle `get_tree().paused`

The debug HUD (`_scripts/tool_kit/debug_hud.gd`, a `Control` under the toolkit's `CanvasLayer`) renders FPS, frame time, and current scene name into a `Label` every `_process` frame.

When adding new prototypes, the expected pattern is to build them under `prototypes/` (or as children of the `game` node in `main.tscn`) so they get the toolkit's debug/pause/restart affordances for free.
