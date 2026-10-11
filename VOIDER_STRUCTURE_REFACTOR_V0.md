# Voider Structure V0 — 폴더 / Scene Tree 규칙

- 적용: 2026-09-27, 브랜치 `refactor/structure-v0`
- 이 문서는 **현재 코드 구조를 설명하는 규칙서**다. 구조를 바꾸면 이 문서도 같이 고친다.

> **Scene은 필요한 역할만 가진다. 같은 역할은 프로젝트 어디에서나 같은 문법으로 표현한다.**
>
> **기능은 발산한다. 문법은 수렴한다.**

이 규칙은 부모 클래스나 강제 Schema가 아니라 **Convention / Preset**이다.
빈 역할 Node, 빈 폴더, "나중에 필요할 것 같은" Manager/Component는 만들지 않는다. 필요해지면 그때 생긴다.
Godot 엔진의 실제 제약이 이 문서와 충돌하면 **엔진 제약이 우선**한다 (아래 "엔진 제약에 따른 예외" 참고).

---

## 1. 최상위 폴더

| 폴더 | 책임 | 현재 내용 |
|---|---|---|
| `app/` | 게임 최상위 Shell. Level 콘텐츠를 직접 두지 않는다 | `main.tscn`, `main.gd` |
| `actors/` | 자기 상태를 가지고 행동하는 존재 | `player/`, `enemies/test_enemy/` |
| `combat/` | Player/Enemy 어느 한쪽에 종속되지 않는 **공용 전투 언어** | `counter/`, `effects/` |
| `world/` | 살아 있지 않은 World Object / World 리소스 | `backgrounds/`, `tiles/` |
| `levels/` | 실제 게임 공간 | `combat_test/`, `level_containers.gd` |
| `camera/` | Camera 공용 기능 | `camera_shake.gd` |
| `toolkit/` | 개발자용 기능 (플레이어용 UI 아님) | `toolkit.tscn`, `toolkit.gd`, `debug_hud.gd` |
| `core/` | 여러 영역이 공유하는 **저수준** 기반. "어디 둘지 모르겠다"의 대피소가 아니다 | `physics/collision_layers.gd` |
| `assets/` | 원본 Asset (이미지 등) | `characters/`, `environment/`, `temporary/` |
| `addons/` | Godot 에디터 플러그인 (godot_mcp) | — |

아직 없는 폴더 — 실제 대상이 생길 때 만든다:

- `ui/` (`hud/`, `menus/`, `dialogue/`, `transitions/`): 플레이어용 UI
- `managers/`: **게임 전체 범위**의 상태/흐름을 실제로 조율하는 고수준 관리자 (GameManager, SceneManager, SaveManager, AudioManager 등). `EnemyManager`, `DoorManager` 같은 객체별 Manager는 만들지 않는다. Manager는 `core/`가 아니다.
- `combat/components/` (`hitbox/`, `hurtbox/`, `health/`), `combat/projectiles/`
- `world/platforms|hazards|interactables|props/`, `actors/npcs/`

### 판단 기준

- **누가 / 왜** 이 공격을 쓰는가 → `actors/<actor>/abilities/` (예: Player 고유 `Windblast`, TestEnemy 고유 `RangedAttack`)
  - 사용처가 하나뿐이면 그 Actor 아래에 둔다. 두 번째 사용처가 실제로 생기면 그때 `combat/`으로 올린다 (복제하지 않는다 — `class_name` 중복)
- 공격과 피격 **자체가 어떻게** 작동하는가 → `combat/` (예: `CounterableAttack.try_counter()`, `CounterResult`)
- Raw 이미지/오디오 → `assets/`, 그것을 사용하는 Godot 리소스(`.tres`)는 사용하는 쪽 (예: TileSet → `world/tiles/`)

---

## 2. 파일 명명

- 같은 기능의 Scene과 Script는 **같은 basename**: `player.tscn` + `player.gd`.
- 파일/폴더명은 `snake_case`. (`X.tscn.gd` 규칙은 폐기)
- `.uid` 파일은 Godot이 관리한다. 스크립트를 옮길 때는 `.uid`도 함께 옮기고, 손으로 편집하지 않는다.
- 이미지를 옮길 때는 `.import`도 함께 옮긴다 (UID 유지). Asset 파일명 자체는 불필요하게 바꾸지 않는다.
- 스크립트에 다른 파일의 `res://` 경로를 직접 쓰지 않는다. 상속은 `class_name`으로(`extends CounterableAttack`), Scene 참조는 `@export var ...: PackedScene`으로 받고 값은 `.tscn`에서 지정한다 (UID로 저장되어 파일 이동에 안전).

## 3. 노드 명명

- 노드 이름은 **PascalCase**.
- **역할 노드는 역할 이름**: `Visual`, `BodyCollision`, `Combat`, `Hurtbox`, `AttackHitbox`, `Sensors`, `Components`, `Audio`.
- **역할 안의 단일 leaf는 타입 이름**: `CollisionShape2D`, `AnimatedSprite2D`, `Polygon2D`, `Sprite2D`.

---

## 4. Scene Tree Vocabulary

### Actor

```text
ActorRoot (CharacterBody2D)
├── Visual          보이는 요소. 좌우 반전은 여기서만 (판정 노드를 뒤집지 않는다)
├── BodyCollision   Actor ↔ World 물리 충돌. Hitbox/Hurtbox와 별개
├── Combat          Hurtbox, AttackHitbox, 공격 관련 Timer 등
├── Sensors         감지만 한다. 판단/행동은 Actor/State가 한다
├── Components      재사용 가치가 실제로 있는 행동 Component
└── Audio
```

전부 필수가 아니다. 현재 Player/TestEnemy는 `Visual`, `BodyCollision`, `Combat`만 가진다.

### 그 외 Preset

```text
Environment:   Root ├ Visual └ Collision            (필요하면 Sensors 추가)
Hazard:        Root ├ Visual ├ Hitbox └ Collision(optional)
Interactable:  Root ├ Visual ├ InteractionArea └ Components
Projectile:    Root ├ Visual ├ Hitbox ├ Collision(optional) └ Lifetime
Attack:        Root ├ Hitbox ├ Visual(optional) └ Lifetime
```

### Level

```text
LevelRoot (Node2D)
├── World         Background, TileMap 등
├── Actors        Player, Enemy
├── Projectiles   런타임 투사체 (그룹 level_projectiles)
├── Effects       런타임 이펙트 (그룹 level_effects)
├── SpawnPoints   (필요할 때)
└── CameraPoints  (필요할 때)
```

런타임 스폰은 생성 주체의 `get_parent()`가 아니라 `LevelContainers.projectiles(self)` / `LevelContainers.effects(self)`로 컨테이너를 찾는다.
컨테이너가 없으면(Actor 씬 단독 F6 실행 등) 기존 부모로 fallback하고 디버그 실행에서 그룹별로 한 번 경고한다.
`LevelContainers`는 이 조회만 담당한다. 범용 Level API로 키우지 않는다.

### Main

```text
Main (Node)
├── CombatTest   현재 Level 인스턴스
└── Toolkit      항상 켜진 개발 툴킷 (PROCESS_MODE_ALWAYS)
```

`CurrentLevel` 같은 분류용 컨테이너는 두지 않았다. 런타임 Level 교체 코드가 생겨서 삽입 지점이 실제로 필요해지면 그때 만든다.

---

## 5. 현재 실제 Scene Tree

```text
Main (Node)                                   app/main.tscn
├── CombatTest (Node2D)                       levels/combat_test/combat_test.tscn
│   ├── World
│   │   ├── Background                        world/backgrounds/background.tscn
│   │   └── PlatformTileMap (TileMapLayer)    TileSet: world/tiles/combat_test_tileset.tres
│   ├── Actors
│   │   ├── Player                            actors/player/player.tscn
│   │   └── TestEnemy                         actors/enemies/test_enemy/test_enemy.tscn
│   ├── Projectiles                           [level_projectiles]
│   └── Effects                               [level_effects]
└── Toolkit (CanvasLayer)                     toolkit/toolkit.tscn
    └── DebugHud (Control) └ InfoLabel

Player (CharacterBody2D)                      layer player_body, mask world
├── Visual (Node2D)          scale.x = facing
│   ├── FacingArrow (Polygon2D)
│   └── AnimatedSprite2D
├── BodyCollision (CollisionShape2D)
├── Combat (Node2D)
│   ├── Hurtbox (Area2D) └ CollisionShape2D          layer player_hurtbox
│   └── AttackHitbox (Area2D) └ CollisionShape2D     layer player_attack, mask enemy_hurtbox
├── Camera (Camera2D, CameraShake)            group player_camera
└── StatusLabel (Label)

TestEnemy (CharacterBody2D)                   layer enemy_body, mask world
├── Visual (Node2D) └ AnimatedSprite2D        (반전/플래시는 기존대로 스프라이트에 적용)
├── BodyCollision (CollisionShape2D)
└── Combat (Node2D)
    ├── Hurtbox (Area2D) └ CollisionShape2D          layer enemy_hurtbox
    └── AttackTimer (Timer)

Windblast (Area2D)                            actors/player/abilities/windblast/
├── CollisionShape2D                          layer player_attack, mask world + enemy_hurtbox
└── Visual └ Polygon2D

RangedAttack (Node2D, extends CounterableAttack) actors/enemies/test_enemy/abilities/ranged_attack/
└── Visual └ Polygon2D

SlashEffect / HitSpark (Node2D) └ Polygon2D   combat/effects/
```

---

## 6. 엔진 제약에 따른 예외 / 현재 타협

| 항목 | 내용 | 이유 |
|---|---|---|
| `BodyCollision` | 컨테이너가 아니라 `CollisionShape2D` 노드 자체의 이름 | CharacterBody2D의 충돌 모양은 직계 자식이어야 동작한다 |
| `Camera`, `StatusLabel` | Vocabulary에 없는 노드지만 Player 루트에 유지 | 새 Vocabulary를 억지로 만들지 않음. `StatusLabel`은 `Visual` 아래에 두면 반전 때 글자가 뒤집힌다 |
| `Windblast` | 루트 자체가 Hitbox(Area2D). `Hitbox` 자식/`Lifetime` 노드 없음 | 기존 signal/damage 동작 보존. Lifetime은 스크립트 변수 |
| `RangedAttack` | Hitbox 없음, 거리(`hit_distance`)로 명중 판정 | 기존 설계. 데미지 파이프라인 작업 때 정리 |
| 피격 대상 조회 | `area.owner` (Hurtbox가 `Combat/` 아래에 있으므로 씬 루트) | V0 동작 보존용 최소 수정. **영구 표준 아님** — Hurtbox 컴포넌트화 때 교체 |

## 7. V0.1 후보

- Camera를 Player에서 분리 (Level/Camera rig 소유). 현재 `$Camera` 직접 참조와 `player_camera` 그룹 조회가 공존
- 디버그 표시용 노드(`StatusLabel` 등)의 자리 (`Debug` 슬롯 여부)
- Projectile preset을 "루트가 Area2D인 투사체"까지 포함하도록 완화할지, Hitbox 자식으로 맞출지
- Hitbox/Hurtbox 컴포넌트화 후 `area.owner` 조회 제거
- `CurrentLevel` 삽입 지점은 런타임 Level 교체가 생길 때 재검토
