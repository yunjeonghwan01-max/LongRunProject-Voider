# PROJECT AUDIT — Voider LongRun Project

- 작성일: 2026-09-26
- 기준 브랜치: `fix/test-enemy-movement` (커밋 `645dd78`에 커밋되지 않은 충돌 레이어 정리 작업을 더한 상태)
- 목적: 대규모 리팩토링과 BASE 구축에 앞서, 지금 구현된 모든 것을 게임 개발 관점에서 정리하고 영역별로 점수(10점 만점)를 매긴다.
- 점수 기준: "장르가 액션 플랫포머인 **장기 프로젝트의 베이스**로서 그대로 확장해도 되는가"를 본다. 프로토타입 단계라는 사정은 감안하지만, 기준을 낮추지는 않는다.

---

## 0. 총평

| 영역 | 점수 | 한 줄 평 |
|---|---|---|
| 1. Collision Architecture | **6.5** | 레이어 체계와 바디/트리거 분리는 잡혔음. 컴포넌트화가 안 되어 있고, 코드와 씬 설정이 따로 놀아 다시 망가지기 쉬움 |
| 2. Scene Architecture | **4.0** | 폴더 규칙이 섞여 있고, 레벨·월드·이펙트 계층이 없음 |
| 3. Input Architecture | **4.0** | `tool_`/`player_` 접두사는 좋음. 키 충돌·죽은 액션이 있고, 버퍼링과 추상화가 없음 |
| 4. Player Controller | **5.0** | 기능은 돌아감. bool 플래그와 `await` 타이머 체인이라 확장·일시정지에 취약함 |
| 5. Combat System | **5.5** | Attack/Counter 개념과 Windblast 설계는 좋음. 데미지 파이프라인이 없음 |
| 6. Enemy / AI | **2.5** | 검증용 스텁. 중력·상태·조준이 없음 |
| 7. Game Feel / VFX | **6.5** | 참격·스파크·플래시·쉐이크가 있음. 히트스톱·사운드·애니메이션이 없음 |
| 8. Camera | **5.0** | 쉐이크 컴포넌트는 깔끔함. 리밋·스무딩·데드존이 없음 |
| 9. Debug Tooling | **6.0** | 항상 켜진 툴킷은 좋은 출발점. 로그 체계와 충돌 시각화가 없음 |
| 10. Data Architecture | **2.0** | 모든 수치가 노드 `@export`에 박혀 있음. Resource 기반 데이터가 없음 |
| 11. Game Flow / UI / Audio | **1.0** | 메인 씬 하나뿐. UI·사운드·씬 전환·세이브가 없음 |
| 12. Project Config / Assets | **3.5** | 렌더러 설정이 어긋나 있고, 텍스처가 과대하며, 임시 에셋이 섞여 있음 |
| 13. Docs / Process | **6.5** | CLAUDE.md와 PROGRESS.md는 훌륭함. 다만 내용이 코드와 이미 어긋나기 시작함. 테스트 없음 |
| **종합** (13개 영역 단순 평균) | **4.5 / 10** | **"핵심 전투 아이디어를 검증하는 프로토타입"으로는 합격이지만, 이대로 BASE로 쓰기는 어렵다.** |

> 요약: 게임의 **핵심 가설(카운터 유도 공격, 카유공)** 은 잘 격리된 형태로 검증되고 있고, 코드 주석과 문서화 습관도 좋다. 그런데 그 위에 올라갈 **뼈대(컴포넌트, 상태 머신, 데이터, 이벤트, 씬 계층)** 가 거의 없다. 지금 코드를 계속 키우면 `player.gd`가 God Object가 된다. 따라서 리팩토링 시점으로는 지금이 딱 맞다.

---

## 1. 구현된 기능 인벤토리

| 기능 | 파일 | 상태 |
|---|---|---|
| 좌우 이동 / 점프 / 중력 | `systems/player/player.gd` | ✅ 동작 |
| 대쉬 (수평, 쿨다운) | `player.gd` `_start_dash` | ✅ 동작 |
| 근접 기본 공격 (startup → active → recovery) | `player.gd` `_start_attack` | ✅ 동작 |
| 카운터 입력 / whiff 후딜 | `player.gd` `_try_counter` | ✅ 동작 |
| 장풍 Windblast (관통, 다단히트, 쿨다운, 반동) | `systems/combat/windblast.gd` | ✅ 동작 |
| 공격 베이스 클래스 / 카운터 판정 | `systems/combat/attack.gd` | ✅ 동작 |
| 카운터 결과 데이터 | `systems/combat/counter_result.gd` | ⚠️ 아무도 구독하지 않음 |
| 원거리 카유공 (방향·시야 검사, Pre-Signal, Counter Window, 비행) | `systems/combat/ranged_attack.gd` | ⚠️ 명중해도 로그만 찍힘 (데미지 없음) |
| 참격 이펙트 / 히트 스파크 | `systems/combat/slash_effect.gd`, `hit_spark.gd` | ✅ 동작 (절차적 폴리곤) |
| 카메라 쉐이크 | `_scripts/camera_shake.gd` | ✅ 동작 |
| 테스트 적 (좌우 이동, 벽 반전, 피격 플래시, 넉백, 주기 공격) | `_scripts/test_enemy.gd` | ⚠️ 스텁 수준 |
| TileMap 전투 테스트 맵 | `_scenes/main.tscn`, `combat_test_tileset.tres` | ✅ 동작 |
| 배경 (뷰포트 cover 스케일) | `_scenes/background.tscn` | ⚠️ 월드 공간에 고정됨 |
| 개발 툴킷 (HUD 토글 / 재시작 / 일시정지) | `_scripts/tool_kit/*` | ✅ 동작 |
| 2D 물리 레이어 이름 + `CollisionLayers` 상수 | `project.godot`, `systems/physics/collision_layers.gd` | ✅ (커밋 전) |
| 플레이어 체력 / 피격 / 사망 | — | ❌ 없음 |
| 적 AI 상태 / 복수 패턴 | — | ❌ 없음 |
| UI / 사운드 / 씬 전환 / 세이브 | — | ❌ 없음 |

---

## 2. 영역별 상세 평가

### 2.1 Collision Architecture — 6.5

**좋은 점**
- 레이어 7개에 이름을 붙였고(`world`, `player_body`, `enemy_body`, `player_attack`, `enemy_hurtbox`, `player_hurtbox`, `enemy_attack`), 같은 번호를 `CollisionLayers` 상수로도 만들었다.
- **땅을 밟는 바디(CharacterBody2D, mask=world)** 와 **공격/피격 트리거(Area2D)** 를 분리했다. 그래서 플레이어와 적이 서로 밀지 않는다.
- 허트박스는 layer만 쓰고 mask=0이다. 공격 쪽만 상대를 감지한다(단방향 감지).
- Windblast는 mask에 world를 포함해 지형에 닿으면 소멸한다.

**문제점**
- **씬 파일에 숫자가 그대로 박혀 있다** (`collision_layer = 16` 등). `CollisionLayers` 상수는 코드 한 곳(`ranged_attack.gd`의 LOS)에서만 쓰인다. 사람이 인스펙터를 한 번 잘못 누르면 바로 깨진다. 실제로 `main.tscn` 인스턴스에 `collision_layer = 1`이 덮어써져 구조 전체가 무너진 일이 있었다.
- **Hitbox/Hurtbox가 클래스가 아니다.** 피격 대상을 `area.get_parent()`로 찾고 `has_method("take_damage")`로 확인하는 덕 타이핑이다. 허트박스를 한 단계만 더 깊이 넣어도 깨진다.
- 같은 판정 로직(대상 중복 방지, 데미지 전달)이 `player.gd`와 `windblast.gd`에 **중복**되어 있다.
- **`player_hurtbox`와 `enemy_attack` 레이어는 쓰는 곳이 없다.** 원거리 공격은 물리 대신 `distance_to() < hit_distance`로 명중을 판정한다.
- 적 넉백이 Tween으로 `position`을 직접 옮기기 때문에 **물리를 우회한다.** 벽 근처에서 맞으면 벽 속으로 파고들 수 있다.
- 타일셋 `physics_layer_0`에 one-way 플랫폼, 가시(hazard) 같은 지형 종류 구분이 없다.

### 2.2 Scene Architecture — 4.0

**좋은 점**
- `main.tscn`의 `game` 노드와 `toolkit` 인스턴스 분리는 템플릿으로서 괜찮은 출발이다.
- 이펙트·투사체는 모두 독립 씬(`.tscn`)으로 분리되어 있다.

**문제점**
- **폴더 규칙이 두 개 섞여 있다.**
  - `_scenes/` + `_scripts/` (씬과 스크립트를 분리하는 방식): `test_enemy`, `camera_shake`, `background`
  - `systems/<feature>/` (기능 단위로 모으는 방식): `player`, `combat`, `physics`
  - `camera_shake.gd`는 `_scripts/`에 있는데 `systems/player/player.tscn`이 쓰고 있다. 공용 시스템이 템플릿 폴더에 들어가 있는 셈이다.
  - `X.tscn.gd` 명명 규칙(CLAUDE.md)을 `test_enemy.gd`와 `camera_shake.gd`가 따르지 않는다.
- **레벨이 씬으로 분리되어 있지 않다.** TileMap, 플레이어, 적이 `main.tscn`에 바로 들어 있다. 두 번째 맵을 만들려면 main을 복사해야 한다.
- 이펙트·투사체를 `get_parent().add_child()`로 스폰한다. 결과가 "스폰한 주체가 어디에 붙어 있느냐"에 좌우된다. 월드 안에 `effects`/`projectiles` 컨테이너 노드가 필요하다.
- 배경이 `Node2D`라 월드 좌표에 고정된다. 카메라가 따라가면 배경이 벗어난다. `CanvasLayer`(layer -1)나 `Parallax2D`가 맞다.
- `main.tscn.gd`는 Godot 기본 템플릿(빈 `_ready`/`_process`)이 그대로 남아 있다.
- Autoload(전역 싱글톤)가 없다. 이벤트 버스, 게임 상태, 씬 전환을 둘 곳이 없다.
- 그룹 기반 조회(`get_first_node_in_group("player")`, `"player_camera"`)가 흩어져 있다. 결합도는 낮지만 추적이 어렵다.

### 2.3 Input Architecture — 4.0

**좋은 점**
- `tool_*`와 `player_*`로 개발용과 게임플레이용 입력을 네임스페이스처럼 분리했다.
- 툴킷은 `_unhandled_input`, 게임플레이는 폴링을 쓴다. 역할은 대체로 맞다.

**문제점**

| 문제 | 내용 |
|---|---|
| **키 충돌** | `player_attack` = `player_confirm` = **X**. `player_move_up` = `player_interaction` = **↑** |
| **안 쓰는 액션** | `player_confirm`, `player_cancel`, `player_move_up`, `player_move_down`, `player_interaction` (코드 어디서도 참조하지 않음) |
| **게임패드 없음** | 모든 바인딩이 키보드 전용이다. 액션 게임에서 패드는 거의 필수다 |
| **입력 버퍼 / 코요테 타임 없음** | `is_action_just_pressed`를 그 프레임에만 판정한다. 공격 후딜 끝나기 직전의 입력, 발판 끝에서의 점프 입력이 버려진다. **카운터 게임에서는 특히 치명적이다** |
| **추상화 없음** | `player.gd`가 `Input`을 직접 읽는다. AI나 리플레이가 같은 컨트롤러를 쓸 수 없다 |
| **가변 점프 없음** | 점프 키를 떼도 상승이 끊기지 않는다 |
| **키 메타데이터 이상** | `tool_*` 이벤트 일부가 `device=16`이다. `player_jump`에는 `unicode=12619`(한글 IME의 'ㅋ')가 기록되어 있다. physical_keycode 기준이라 당장은 동작하지만, 에디터에서 다시 기록하는 게 안전하다 |
| **문서와 불일치** | PROGRESS.md는 대쉬 키를 Shift라고 하지만, 실제 바인딩은 **C**다 |

### 2.4 Player Controller — 5.0

**좋은 점**
- 튜닝값을 `@export_group`으로 잘 정리했다 (Dash, Basic Attack, Windblast 등).
- 공격과 카운터 입력이 서로 막지 않도록 의도적으로 분리했고, 주석으로 이유를 남겼다.
- 공격 hitbox 위치를 visual의 scale 반전과 독립적으로 다룬다.

**문제점**
- **상태 머신이 없다.** `is_dashing`, `is_attacking`, `is_in_counter_recovery`, `can_*` bool 조합으로 상태를 표현한다. 피격, 경직, 사망, 공중공격이 추가되면 조합이 폭발한다.
- **`await get_tree().create_timer()` 체인.** `create_timer`는 기본값 `process_always = true`라 **`tool_pause`로 일시정지해도 대쉬·공격·쿨다운 타이머가 계속 흐른다.** 흐름 중간에 취소(피격 캔슬 등)할 수단도 없다.
- 한 파일(`player.gd`, 약 300줄)이 이동, 점프, 대쉬, 공격, 카운터, 장풍, 이펙트 스폰, 상태 텍스트를 모두 맡는다. God Object로 가는 중이다.
- 체력, 피격, 무적 시간, 사망이 없다.
- 공중 대쉬 중에도 중력이 계속 쌓인다. 대쉬가 끝나면 급낙하한다 (의도였다면 문서화가 필요하다).
- `print()` 로그가 매 행동마다 찍힌다.

### 2.5 Combat System — 5.5

**좋은 점**
- `Attack` 베이스 클래스의 원칙("상태 = 변수, 판정 = 함수, 결과 전달 = Signal")이 명확하다.
- 카운터는 공격 쪽이 판정하고(`try_counter`), 한 번만 성공할 수 있게 보장한다. 좋은 설계다.
- `RangedAttack`의 Pre-Signal과 Counter Window 흐름은 게임 디자인 의도가 코드에 잘 드러난다.
- `Windblast`의 다단히트는 대상마다 독립 타이머를 쓰고 최대 횟수를 보장하며, 데미지를 고르게 나눈다. 완성도가 높다.

**문제점**
- **데미지 파이프라인이 없다.** `take_damage(amount, source, knockback)` 시그니처는 적에게만 있다. 원거리 공격 `_resolve_hit()`은 로그만 찍고 사라진다. **플레이어는 맞을 수 없다.** 전투 루프가 한쪽으로만 닫혀 있다.
- **카운터 대상이 슬롯 하나다.** `set_counter_target`이 기존 대상을 덮어쓴다. 카유공 두 개가 겹치면 먼저 온 공격의 카운터 기회가 조용히 사라진다.
- `CounterResult` / `counter_succeeded`를 구독하는 곳이 없다.
- `attack_type: String`은 오타에 취약하다. enum이나 Resource가 필요하다.
- 근접 공격은 `Attack` 계층을 쓰지 않는다. 공격이 두 가지 방식으로 구현되어 있다.
- 적이 투사체를 `facing_direction`으로 쏜다. 적이 벽에서 방향을 바꾼 뒤에는 플레이어 반대쪽으로 쏠 수 있다.

### 2.6 Enemy / AI — 2.5

- `CharacterBody2D` 전환, 벽 반전, 스프라이트 반전, 피격 플래시, 넉백까지는 있다.
- **중력이 없다.** 배치된 높이에서 수평으로만 움직이고, 발판 끝을 감지하지 못한다.
- AI 상태(순찰, 추적, 공격, 경직)와 행동 패턴 스케줄러가 없다. 공격은 고정 타이머다.
- 적 공통 베이스(Enemy 클래스)나 체력 컴포넌트가 없다. 적을 하나 더 만들면 코드를 복붙해야 한다.
- 스크립트 끝에 빈 줄과 공백 줄이 남아 있고, `_ready`와 `_physics_process` 사이에 빈 줄이 없다. 손코딩 흔적이 그대로 남아 있다.

### 2.7 Game Feel / VFX — 6.5

- 참격(초승달 폴리곤), 히트 스파크(확산 링), 적 오버브라이트 플래시, 카메라 쉐이크가 있다. 쉐이크는 여러 번 호출돼도 가장 강한 값만 반영해서 과도하게 누적되지 않는다.
- 카운터 윈도우의 발광·스케일 펄스로 가독성을 확보했다.
- 이펙트 스크립트가 셰이더나 텍스처 없이 절차적으로 생성된다. 프로토타입에 적합하다.
- **히트스톱(프레임 정지)이 없다.** 타격감에서 가장 비용 대비 효과가 큰 요소가 빠져 있다.
- 사운드, 파티클, 스프라이트 애니메이션(모든 AnimatedSprite가 1프레임 idle)이 없다.
- 이펙트를 풀링하지 않는다 (지금 규모에서는 문제없음).

### 2.8 Camera — 5.0

- `CameraShake`는 재사용 가능한 작은 컴포넌트로 잘 만들어졌다.
- 카메라가 플레이어 씬 안에 박혀 있다. 컷신, 보스룸 고정, 사망 연출 때 분리하기 어렵다.
- `limit_*`, 스무딩, 데드존, 룩어헤드 설정이 없다.
- 카메라를 찾는 방법이 두 가지다. 플레이어는 `$camera`를 직접 참조하고, Windblast는 그룹 `"player_camera"`로 찾는다.

### 2.9 Debug Tooling — 6.0

- `PROCESS_MODE_ALWAYS` 툴킷이 있어서 일시정지 중에도 동작한다. HUD에 FPS, 프레임타임, 씬 이름이 나온다. 템플릿으로서 좋은 출발이다.
- 로그는 `print()`만 쓰고 채널, 레벨, 끄기 기능이 없다. 전투 로그가 콘솔을 뒤덮는다.
- 없는 것들:
  - 충돌 영역 시각화 토글 (Debug → Visible Collision Shapes 대체)
  - 타임스케일(슬로우 모션) 조절. 카운터 타이밍 튜닝에 특히 유용하다
  - 무적, 체력 리셋 같은 치트
  - 현재 플레이어 상태 표시
- `debug_hud.gd`가 `get_tree().current_scene.name`을 매 프레임 읽는다. 씬을 리로드하는 순간 null일 가능성이 있다.

### 2.10 Data Architecture — 2.0

- 공격 데미지, 프레임 데이터, 쿨다운, 적 스탯이 모두 노드 스크립트의 `@export`에 있다.
- 무기, 스킬, 적 종류를 **데이터(Resource `.tres`)로 교체**할 수 없다. 밸런싱을 하려면 씬을 하나씩 열어야 한다.
- 세이브/로드, 설정 저장(키 리바인딩, 볼륨)이 없다.

### 2.11 Game Flow / UI / Audio — 1.0

- 타이틀, 일시정지 메뉴, HUD(체력, 게이지), 게임오버, 씬 전환이 전부 없다.
- 오디오 버스와 사운드가 없다 (`_assets/audio`는 비어 있음).
- 게임 상태(플레이 중, 일시정지, 사망)를 관리하는 곳이 없다. `tool_pause`가 유일한 일시정지 경로다.

### 2.12 Project Config / Assets — 3.5
- **렌더러 설정이 서로 다르다.**
  - `config/features`에는 `"Forward Plus"`가 있다.
  - 실제 `renderer/rendering_method`는 `"gl_compatibility"`다.
  - CLAUDE.md와 PROGRESS.md는 Forward+라고 적고 있다.
  - 어느 쪽인지 확정하고 문서를 맞춰야 한다.
- 3D용 Jolt Physics 설정은 2D 게임에는 영향이 없다 (2D는 Godot Physics 2D를 쓴다). 문서가 오해를 부른다.
- 텍스처가 과도하게 크다. 플레이어 원본은 1254×1254인데 `scale 0.049`로, 적 원본은 500×500인데 `scale 0.155`로 줄여 쓴다. 메모리와 필터링 품질에 모두 손해다. 게임 해상도에 맞춘 원본 크기가 필요하다.
- 픽셀아트인지 일러스트인지 방향이 정해지지 않았다. `default_texture_filter`가 설정되어 있지 않다.
- `tem_ai_assets/`(임시 AI 에셋)가 정식 에셋과 섞여 있다. `coin.png`, `portion.png`, `wizard.png`, `sprite--9px...png`는 쓰이지 않는다.
- **`.DS_Store`가 git에 추적되고 있다** (`.DS_Store`, `_assets/.DS_Store`). `.gitignore`에 `**/.DS_Store`가 필요하다.
- `addons/godot_mcp`가 저장소에 포함되어 있다. 의도한 것인지 확인이 필요하다.

### 2.13 Docs / Process — 6.5
- PROGRESS.md는 결정 이유, 플레이테스트 결과, 실패한 시도까지 기록한다. 장기 프로젝트 메모리로서 모범적이다.
- 코드 주석이 "왜"를 설명한다.
- 문서가 이미 코드와 어긋나 있다.
  - 대쉬 키 Shift → 실제는 C
  - test_enemy 경로 `prototypes/combat_test/` → 실제는 `_scenes/`, `_scripts/`
  - "타일 layer 1/1로 플레이어와 매칭" → 레이어 재설계 이후 사실이 아님
  - 렌더러 (2.12 참고)
- 자동화 테스트(GUT, gdUnit4)와 CI가 없다. 헤드리스 로드 검사조차 스크립트화되어 있지 않다.

---

## 3. 발견된 버그 / 리스크 목록 (우선순위순)

| # | 심각도 | 내용 | 위치 |
|---|---|---|---|
| 1 | 🔴 높음 | 플레이어가 피격될 수 없다. 전투 루프가 닫혀 있지 않다 | `ranged_attack.gd` `_resolve_hit` |
| 2 | 🔴 높음 | 일시정지 중에도 `create_timer` 기반 대쉬, 공격, 쿨다운이 진행된다 | `player.gd`, `windblast.gd` |
| 3 | 🟠 중간 | 카운터 대상 슬롯이 하나라 동시 카유공 중 하나가 소실된다 | `player.gd` `set_counter_target` |
| 4 | 🟠 중간 | 넉백 Tween이 물리를 우회해 벽을 관통할 수 있다 | `test_enemy.gd` `_apply_knockback` |
| 5 | 🟠 중간 | 인스턴스 오버라이드로 충돌 레이어가 쉽게 깨진다 (실제 발생) | `main.tscn` |
| 6 | 🟠 중간 | X, ↑ 키가 두 액션에 겹쳐 있다. UI를 붙이는 순간 충돌한다 | `project.godot` |
| 7 | 🟡 낮음 | 적이 방향 전환 후 플레이어 반대쪽으로 투사체를 쏠 수 있다 | `test_enemy.gd` `_spawn_ranged_attack` |
| 8 | 🟡 낮음 | 적에게 중력이 없다 | `test_enemy.gd` |
| 9 | 🟡 낮음 | 배경이 월드 공간에 고정되어 카메라 이동 시 벗어난다 | `background.tscn` |
| 10 | 🟡 낮음 | 렌더러 설정과 문서가 불일치한다 | `project.godot`, `CLAUDE.md` |

---

## 4. BASE 리팩토링 제안 (우선순위순)

### P0 — 뼈대
1. **폴더 규칙 통일.** 기능 단위(`systems/<feature>/`에 씬, 스크립트, 리소스를 함께)로 하나만 고른다. `_scenes/`와 `_scripts/`는 앱 셸(main, toolkit)에만 쓰고 CLAUDE.md를 갱신한다.
2. **컴포넌트화.**
   - `Hitbox`(Area2D, `class_name`, `damage_data` 보유)와 `Hurtbox`(Area2D, `owner_entity` 참조)를 만든다. `get_parent()` 덕 타이핑을 제거하고, 중복 방지 로직을 Hitbox 한 곳에 둔다.
   - `HealthComponent`에 `damaged`, `died` 시그널, 무적 시간을 둔다. 플레이어와 적이 공용으로 쓴다.
   - 충돌 레이어는 각 컴포넌트 `_ready()`에서 `CollisionLayers` 상수로 강제로 설정한다. 그러면 씬에 숫자가 박히지 않고, 인스턴스 오버라이드로 깨지는 일도 원천 차단된다.
3. **상태 머신.** 플레이어와 적 모두 노드 기반 또는 클래스 기반 FSM을 쓴다 (Idle / Run / Jump / Fall / Dash / Attack / Counter / Hurt / Dead). 타이머는 상태 내부 경과 시간으로 관리해 일시정지와 캔슬을 자연스럽게 지원한다.
4. **데미지 파이프라인 양방향 완성.** 적 공격도 `enemy_attack` Hitbox로 `player_hurtbox`를 치게 한다. 원거리 공격의 거리 판정은 제거한다.

### P1 — 게임 구조
5. **Autoload.**
   - `Events`: 전역 시그널 버스 (`counter_succeeded`, `player_damaged`, `enemy_died` 등)
   - `Game`: 상태, 일시정지, 씬 전환
   - `Log`: 채널별 로거. `print`를 대체한다
6. **레벨 씬 분리.** `levels/combat_test.tscn`에 TileMap, 스폰 포인트, `effects`/`projectiles` 컨테이너를 둔다. `main`은 레벨을 로드하는 셸이 된다.
7. **입력 계층.**
   - 입력 버퍼(약 100~150ms), 코요테 타임, 가변 점프를 넣는다.
   - 키 충돌을 정리하고 게임패드를 바인딩한다.
   - 컨트롤러가 `Input` 대신 "의도(intent)" 구조체를 읽게 한다. AI와 리플레이에 재사용할 수 있다.
8. **데이터 Resource화.** `AttackData`(데미지, startup/active/recovery, 넉백, counterable), `EnemyStats`, `SkillData`를 `.tres`로 만든다.

### P2 — 품질
9. 히트스톱, 사운드 버스 설정과 기본 SFX, 카메라 리밋과 스무딩.
10. 툴킷 확장: 타임스케일, 충돌 시각화, 상태 표시, 치트.
11. 프로젝트 설정 정리: 렌더러 확정, 텍스처 필터와 해상도 기준, `.DS_Store` 제거, 임시 에셋 격리.
12. 최소 자동 검증: 헤드리스 로드 스크립트와 gdUnit4 스모크 테스트 (데미지 분배, 카운터 1회 보장처럼 순수 로직부터).
13. PROGRESS.md와 CLAUDE.md를 현재 코드에 맞게 갱신한다.

---

## 5. 유지해야 할 것 (리팩토링 중에 잃지 말 것)

- `Attack.try_counter()`의 "공격이 스스로 판정하고, 한 번만 성공" 원칙
- Pre-Signal → Counter Window → Flight 흐름과 플레이테스트로 정한 수치(0.35s / 0.4s)
- Windblast의 대상별 독립 다단히트와 데미지 분배 로직
- CameraShake의 "최댓값만 반영" 정책
- `tool_*` / `player_*` 입력 네임스페이스, 항상 켜진 툴킷
- PROGRESS.md 기록 문화
