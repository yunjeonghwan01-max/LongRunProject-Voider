# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENTS.md

Shared development workflow, approval/risk policy, and Godot collaboration principles are defined there and apply here too. Use Claude Code's Plan Mode selectively for complex or high-risk work per that policy — it is not required for every task.

## Project overview

Voider is a 2D side-scrolling action game built in Godot 4.7, grown out of the IBBD Prototype Base template. The current focus is the core combat loop (attack vs. counter, "카유공" = counter-inducing attacks). Design decisions, playtest results and history live in `PROGRESS.md`; a scored project audit (pre-refactor snapshot) is in `PROJECT_AUDIT.md`.

Engine settings worth knowing:
- The effective renderer is **Compatibility** (`renderer/rendering_method="gl_compatibility"`), even though `config/features` still lists `"Forward Plus"`.
- 2D physics uses Godot's default 2D engine. `3d/physics_engine="Jolt Physics"` only affects 3D.

## Running and editing

This is a Godot Engine project — there is no CLI build/test/lint pipeline. Open and run it through the Godot 4.7 editor (macOS app path configured in `.vscode/settings.json` as `/Applications/Godot.app`). The main scene is `app/main.tscn` (set via `run/main_scene` in `project.godot`, referenced by UID).

To run headless from the terminal (e.g. to sanity-check the project loads):
```
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit
```

There are no automated tests in this repo.

## Directory layout

The structure rules (folder responsibilities, file/node naming, Scene Tree vocabulary, engine-constraint exceptions) are defined in **`VOIDER_STRUCTURE_REFACTOR_V0.md`**. Follow it when adding files or nodes, and update it when the structure changes.

- `app/` — top-level shell (`main.tscn`: current level instance + toolkit). No level content here.
- `actors/` — things with their own state and behavior: `player/` (incl. `abilities/counter|melee_attack|windblast/`), `enemies/test_enemy/` (incl. `abilities/ranged_attack/`). An ability folder holds the whole skill: the `<name>_ability.gd` node under the actor's `Combat/` (input, cooldown, spawning) plus what it spawns (`<name>_projectile.*`).
- `combat/` — shared combat language not owned by one actor: `components/` (`HitboxComponent`, `HurtboxComponent`, `HealthComponent`), `counter/` (`CounterableAttack`, `CounterResult`), `effects/` (`SlashEffect`, `HitSpark`).
- `world/` — non-actor world objects/resources: `backgrounds/`, `tiles/` (TileSet).
- `levels/` — playable spaces: `combat_test/combat_test.tscn`, plus `level_containers.gd` (runtime spawn-container lookup).
- `camera/` — `CameraShake`.
- `toolkit/` — developer-only toolkit and debug HUD.
- `core/` — low-level shared foundations only: `physics/collision_layers.gd`.
- `assets/` — raw source assets: `characters/`, `environment/`, `temporary/` (placeholder/AI-generated art).
- `addons/godot_mcp/` — Godot MCP editor plugin.

Conventions: a scene and its script share a basename (`player.tscn` + `player.gd`); files are `snake_case`, nodes are `PascalCase`. Move `.uid` (scripts) and `.import` (images) files together with their source file; never hand-edit them. Do not hard-code another file's `res://` path in scripts: inherit via `class_name`, and take scenes as `@export var ...: PackedScene` assigned in the `.tscn` (stored by UID, so moves are safe).

## Architecture

`app/main.tscn` is a plain `Node` shell with two children: the current level instance (`CombatTest`) and the `Toolkit`.

`levels/combat_test/combat_test.tscn` holds `World` (background + `PlatformTileMap`), `Actors` (Player, TestEnemy), and the runtime containers `Projectiles` / `Effects` (groups `level_projectiles` / `level_effects`). Actors spawn projectiles/effects via `LevelContainers.projectiles(self)` / `LevelContainers.effects(self)`; without a level (e.g. running an actor scene alone) it falls back to the spawner's parent and warns once in debug builds.

Actors follow the V0 vocabulary: `Visual` (only this flips with facing), `BodyCollision` (the `CollisionShape2D` itself — must be a direct child of the body), `Combat` (`Health`, `Hurtbox` plus ability nodes such as `Counter`, `MeleeAttack/AttackHitbox`, `WindblastAbility`; each ability reads its own input, in tree order). The player root keeps movement/jump/dash/facing and the `set_counter_target`/`clear_counter_target` entry points used by counterable attacks.

All damage flows through one path: `HitboxComponent` → `HurtboxComponent.receive_hit(damage, source, knockback)` → `HealthComponent.take_damage()`. Attackers own a `HitboxComponent` (toggled via `monitoring`; it dedupes per `reset_hits()`); defenders own `Combat/Health` + `Combat/Hurtbox` and react only through the `hit_received` / `died` signals — actor scripts have no `take_damage()`, and targets are never looked up via `area.owner` or `has_method()`. Projectiles follow the preset `Visual` + `Hitbox` + `Collision` (layer 0, mask world; keep `monitorable` on — an Area2D with `monitorable = false` does not detect TileMap bodies). Player death shows "DEAD" and reloads the scene.

Combat principles to preserve: `CounterableAttack.try_counter()` — the attack judges counters itself and succeeds at most once; `RangedAttackProjectile` runs Pre-Signal → Counter Window → Flight, with its Hitbox enabled only during flight; `WindblastProjectile` pierces with independent per-target multi-hit and distributes total damage; `CameraShake` never lets a weaker request override a stronger active shake.

Physics layers are named in `project.godot` and mirrored as constants in `core/physics/collision_layers.gd` (world, player_body, enemy_body, player_attack, enemy_hurtbox, player_hurtbox, enemy_attack). Bodies mask only `world`; attack areas mask the opposing hurtbox layer.

`toolkit/toolkit.tscn` (`toolkit/toolkit.gd`) is a `CanvasLayer` that provides an always-on developer toolkit, independent of the game's pause state (`process_mode = PROCESS_MODE_ALWAYS`). It listens for dedicated `tool_*` input actions (defined in `project.godot`, distinct from the `player_*` gameplay actions) and currently supports:
- `tool_toggle_hud` — show/hide the debug HUD
- `tool_restart` — reload the current scene
- `tool_pause` — toggle `get_tree().paused`

The debug HUD (`toolkit/debug_hud.gd`, a `Control` under the toolkit's `CanvasLayer`) renders FPS, frame time, and current scene name into a `Label` every `_process` frame.

To add a new level, create it under `levels/<name>/` with the level vocabulary (`World`, `Actors`, `Projectiles`, `Effects` as needed) and instance it from `app/main.tscn` in place of `CombatTest`.
