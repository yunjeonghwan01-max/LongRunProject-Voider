# PROGRESS

이 파일은 단순 TODO 리스트가 아니라, 새 세션(Claude/GPT 무관)에서 Voider 프로젝트의
개발 맥락을 빠르게 복구하기 위한 프로젝트 공용 메모리 파일이다.
새로운 결정/플레이테스트 결과/방향 전환이 있을 때마다 이 파일을 갱신할 것.

## 프로젝트 개요
IBBD Prototype Base 스캐폴드(Godot 4.7, Forward+, Jolt Physics) 위에서
2D 횡스크롤 액션 게임 "Voider"의 핵심 전투 루프(공격 vs 카운터)를 프로토타이핑 중.

### 프로젝트 공용 용어
- **카유공**: **카운터 유도 공격**의 약칭. 실제 전투 중 적의 여러 행동 가운데
  간헐적으로 발동되어 플레이어에게 카운터 기회를 제공하는 공격을 뜻함.

## 구현된 시스템

### 플레이어 (`systems/player/player.gd`)
- 기본 이동/점프/중력 (`speed`, `jump_velocity`, `gravity`)
- 바라보는 방향에 따라 visual/attack_hitbox 좌우 반전
- 대쉬 (`player_dash` 액션, 기본 키 Shift)
  - 현재 `facing_direction`으로 즉시 `velocity.x = dash_speed`를 설정하는 순수 수평 이동
  - `dash_speed`(900) / `dash_duration`(0.15s) / `dash_cooldown`(0.5s) 모두 export 변수로 분리
  - 대쉬 중에는 일반 이동/감속 로직을 건너뛰어 재발동 및 입력 간섭을 막고, 종료 시 그대로 일반 이동 상태로 복귀
  - 무적판정 / 공격 캔슬 / 공중 대쉬 / 스태미나는 의도적으로 미구현 (v0.1은 단순 이동만)
- 근접 기본 공격 (`player_attack` 액션, 기존 `attack`에서 개명): startup(0.08s) → active(0.12s) → recovery(0.25s) 3단계 상태 머신
  - 공격 중에도 카운터 입력은 항상 허용 (공격과 카운터는 서로 독립적으로 동작)
  - 공격 hitbox는 active 구간에서만 monitoring, 동일 active 구간 내 동일 대상 중복 타격 방지
- 카운터 입력 처리 (`player_counter` 액션)
  - `active_counter_target` (현재 카운터 가능한 Attack 참조)이 있을 때만 성공 가능
  - 실패(whiff) 시 `counter_recovery_duration`(현재 0.3s) 동안 재입력 불가
  - 성공/실패 시 머리 위 상태 텍스트(`status_label`)로 피드백

### 전투 공통 (`systems/combat/`)
- `attack.gd` (`Attack` 베이스 클래스): 상태=변수, 판정=함수, 결과 전달=Signal 원칙
  - `counterable`, `counter_window_duration`, `try_counter()`, `counter_succeeded` 시그널
- `counter_result.gd` (`CounterResult`): 카운터 성공/실패 결과 데이터 (attacker, attack_type,
  input_time_msec, success) — 궁극기 게이지 등 후속 시스템이 구독할 수 있도록 설계했으나
  **현재 어떤 시스템에도 연결되어 있지 않음** (미연결 상태로 존재)
- `ranged_attack.gd` (`RangedAttack : Attack`): 원거리 카운터 가능 공격 프로토타입 ("카유공")
  - 발동 시 방향(dot product) + 시야(raycast, layer 2 장애물) 검사로 카운터 후보 여부 결정
  - 후보면 Pre-Signal → counter window 순으로 진행, 카운터 안 되면 window 종료 후
    플레이어를 향해 직선 비행하여 히트
  - **Pre-Signal**: counter window가 열리기 전 예고 구간(`pre_signal_duration`, 기본 0.35s).
    어두운 기본 상태(`pre_signal_dark_color`)에서 흰색(정상 밝기)까지 서서히 밝아지며,
    끝나는 즉시 counter window로 전환됨
  - **Counter Window**: 기존 오버브라이트 glow(최대 modulate 3.0/2.6, 확대/축소 반복)로
    Pre-Signal보다 훨씬 강렬하게 발광 — "지금이 카운터 타이밍"임을 명확히 표시
  - window 종료 시 밝기/스케일 원상 복구 (`_stop_window_glow`)
  - 카운터 판정 로직 자체는 이번 작업에서 변경하지 않음 (순수 시각 효과만 추가)

### 테스트 적 (`prototypes/combat_test/test_enemy.gd`)
- 이동/AI 없음. 일정 주기(`attack_interval`, 기본 2.5s)로 RangedAttack만 발동하는
  카운터 시스템 검증 전용 최소 스텁. 체력/피격 로그만 존재.

### 전투 테스트용 TileMap 플랫폼 환경 (`_scenes/main.tscn`, `_assets/sprites/`)
- 기존 고정 `floor`(StaticBody2D) 노드를 제거하고 `game/platform_tilemap`(TileMapLayer)으로 교체.
  Godot 에디터의 타일 페인트 도구로 바닥/벽/발판을 자유롭게 다시 설계할 수 있음.
- `_assets/sprites/combat_test_tileset.tres`: 32x32 임시 그래픽(`tile_placeholder.png`) 기반
  TileSet. `physics_layer_0/collision_layer|mask = 1`로 플레이어 충돌 레이어(1/1)와 매칭.
- 기본으로 깔아둔 레이아웃 (32px 그리드, 바닥 top y=640): 전체 폭 2타일 두께 바닥,
  좌우 경계 벽, 점프로 닿을 수 있는 높이(바닥 위 64px, 점프 최대 높이 ~80px 이내)의
  발판 2개. 플레이어/test_enemy 시작 위치도 새 바닥 높이에 맞춰 y=616으로 조정.
- 구조는 단순하게 유지(TileMapLayer 1개 + TileSet 1개)했고, 적 AI/스킬/신규 전투 시스템은
  이번 작업 범위에 포함하지 않음.

## 플레이테스트 결과 (카운터 윈도우 튜닝)
- **counter_window_duration = 0.25s**: 근접 공격과 카운터 입력을 병행해야 하는 상황에서
  지나치게 어려움 (반응 여유가 거의 없어 실패율이 높았음)
- **counter_window_duration = 0.4s**: 훨씬 수월하게 느껴짐. 다만 이 값이 일반 플레이어
  기준으로도 적절한 난이도인지는 아직 미검증 (테스터가 제한적이었음)
- 현재 코드 기본값은 0.4s (`ranged_attack.gd`)로 되어 있음
- 현재의 **counter_window_duration 0.4s + Pre-Signal** 조합은 카운터 v0.1의 임시 가설로 둠.
- 카운터만 분리한 환경에서의 추가 미세튜닝은 보류. 실제 전투 환경을 먼저 만든 뒤,
  이동/공격/회피/스킬과 적의 다른 행동이 동시에 일어나는 상황에서 체감을 다시 검증할 것.

## 배경 / 타일셋 / 공격 이펙트 (2026-09-20)

### 배경 씬 (`_scenes/background.tscn`, `_scripts/background.tscn.gd`)
- `_assets/sprites/tem_ai_assets/bg.png`를 `main.tscn`의 배경으로 사용하기 위해
  전용 씬으로 분리 (Node2D 루트 + Sprite2D `body`).
- 뷰포트 크기에 맞춰 이미지를 cover 방식(가로/세로 중 큰 배율)으로 스케일 + 중앙
  정렬하는 스크립트 포함. `get_viewport().size_changed` 시그널로 창 크기 변경에도 대응.
- `main.tscn`에서 `game` 노드보다 먼저(형제 순서상 위) 배치해 항상 맨 뒤에 그려지도록 함.

### 타일셋 투명 타일 (`_assets/sprites/combat_test_tileset.tres`)
- `tile_transparent.png`(완전 투명 32x32) 이미지를 새 `TileSetAtlasSource`(`sources/1`)로 추가.
- **주의**: 최초 추가 시 충돌 폴리곤(`physics_layer_0/polygon_0`)을 빠뜨려서 플레이어가
  이 타일을 그냥 통과하는 버그가 있었음. Godot의 TileMap 충돌은 이미지 알파값이 아니라
  타일셋에 정의된 폴리곤으로만 결정되므로, 시각적으로 투명해도 충돌을 원하면 반드시
  기존 타일과 동일한 폴리곤을 별도로 지정해야 함. → 폴리곤 추가로 해결.
- 현재 투명 타일은 기존 타일과 동일하게 32x32 정사각형 충돌체를 가짐 (보이지 않는
  발판/벽 용도로 사용 가능).

### 공격 연출 추가 (`systems/player/player.gd`, `systems/combat/`)
- 근접 공격 hitbox 활성화 시 `slash_effect.tscn`(보라색 초승달 참격)을 바라보는 방향에 스폰.
- 타격 성공 시 `hit_spark.tscn`(보라색 히트 스파크)을 타격 지점에 스폰 + 카메라 쉐이크
  (`attack_hit_shake_strength`, `attack_hit_shake_duration` export로 조절 가능).
- `ranged_attack.tscn`(적 원거리 투사체)과 `windblast.tscn`(플레이어 장풍) 색상을
  각각 붉은 계열 / 연보라 계열로 변경 (순수 색상 조정, 판정 로직 변경 없음).

### 파일 구조 정리
- `prototypes/combat_test/test_enemy.gd(.uid)/.tscn` → `_scripts/test_enemy.gd`,
  `_scenes/test_enemy.tscn`으로 이동 (CLAUDE.md의 `_scripts`/`_scenes` 명명 규칙 준수).
- `systems/camera/camera_shake.gd(.uid)` → `_scripts/camera_shake.gd`로 이동.
- 위 이동에 따라 `prototypes/`, `systems/camera/`는 다시 빈 디렉터리 상태로 복귀.

## test_enemy 좌우 이동 시도 (2026-09-23, 손코딩 실험 — 미완성/버그 있음)

오늘은 AI 도움 없이 손코딩으로 `test_enemy`에 좌우 이동을 붙여보려 한 실험.
결과물은 동작은 하지만 로직이 상당히 엉성해서, 그대로 다음 세션에 넘기지 말고
아래 문제부터 정리할 것.

### 변경 내용
- `_scripts/test_enemy.gd`: `_physics_process`에서 매 프레임 `_move(delta)` 호출 추가.
  `move_distance`/`move_timer`(`@export`)와 `move_time`(내부 상수 2.0초)로 일정 주기마다
  랜덤한 "이동량"을 뽑아 `facing_direction` 방향으로 흘러가듯 이동시키는 방식.
- `_set_facing_direction()` 함수도 추가했지만 **어디서도 호출하지 않음** — 죽은 코드.
- `_scenes/main.tscn`: 에디터에서 타일을 좀 더 칠함(플레이어 시작 위치 왼쪽으로 벽/발판 확장).
  코드와는 무관한 레벨 디자인 변경.

### 발견된 문제 (다음에 고칠 것)
- **적이 방향을 절대 바꾸지 않음**: `facing_direction`은 `_ready`에서 정한 값(기본 LEFT)
  그대로 고정이고, 이를 바꾸는 `_set_facing_direction()`은 호출되는 곳이 없다.
  결과적으로 적은 계속 왼쪽으로만 걸어가다가 결국 맵 밖으로 나가버린다.
  "좌우 이동"을 만들 생각이었다면 방향 전환 트리거(타이머 만료 시 반전, 벽 감지 등)가
  아예 빠져 있음.
- **물리/충돌 없이 `position`을 직접 갱신**: `test_enemy`는 `Node2D`라 `CharacterBody2D`가
  아니고, `_move()`도 `move_and_slide()` 없이 `position +=`로 직접 이동시킨다. 즉 플랫폼
  가장자리나 벽을 전혀 인지하지 못하고 타일맵을 그냥 통과한다. 발판 위에서만 왔다갔다
  하는 그림을 기대했다면 이 구조로는 불가능.
- **속도 계산이 뒤죽박죽**: `move_distance = randi() % 100` (0~99, 사실상 "픽셀 거리"로 의도한
  듯)을 뽑아 `move_time`(2초)에 걸쳐 쓰기 위해 매 프레임 `(move_distance / move_time) * delta`
  만큼 이동시키는데, 이건 사실상 "속도"처럼 쓰이는 값을 "거리"라는 이름으로 들고 있는
  것이라 읽는 사람이 헷갈린다. 게다가 값 범위가 0~99라 최대 속도가 초당 약 50px 수준으로
  매우 느리고, 매 2초마다 속도가 랜덤하게 확 바뀌어서 움직임이 뚝뚝 끊기고 부자연스럽다.
- **`move_distance`/`move_timer`를 `@export`로 노출**: 둘 다 사실상 내부 런타임 상태(현재
  프레임의 이동 속도/남은 시간)인데 인스펙터에 노출돼 있어서, 마치 디자이너가 조절해야
  할 튜닝값처럼 보인다. 실제로는 `_move()` 내부에서만 매번 덮어써지므로 인스펙터에서
  바꿔봤자 곧바로 무시된다.
- **정지 상태가 없음**: 랜덤 값이 0이 나오지 않는 한 적은 쉬지 않고 계속 움직인다.
  "가끔 멈췄다 움직이는" 느낌을 의도했다면 대기(idle) 상태가 따로 필요함.
- 요약: 겉보기엔 "적이 이리저리 움직인다"처럼 보일 수 있지만, 실은 고정된 한 방향으로만
  느릿느릿 흘러가다 맵을 벗어나는 코드에 가깝다. 다음 세션에서 AI 도움을 받아 방향 전환
  로직과 `CharacterBody2D` 기반 충돌 처리부터 다시 잡을 것.

## 다음에 이어서 볼 것
- 현재 방향: 카운터만 계속 미세튜닝하지 않고 실제 전투 환경을 만들며 검증한다.
- 완료: TileMap 기반 전투 테스트 플랫폼 환경 구축, 플레이어 대쉬 구현
- 다음 우선순위:
  1. 역할이 분명한 플레이어 스킬 1개 구현
  2. 강한 필드몹 수준의 적 AI/스탯 및 복수 행동 패턴 구현
  3. 해당 행동 패턴 중 하나로 카유공을 간헐적으로 섞어 실제 전투 중 카운터 체감 검증
- `CounterResult`를 실제로 소비하는 시스템(궁극기 게이지 등)이 아직 없음 — 필요 시 연결
- 근접 공격에는 아직 counterable 개념이 없음 (원거리만 카운터 가능)
- 적 AI/이동/복수 공격 패턴은 아직 미구현 (`test_enemy`는 검증용 스텁).
  좌우 이동을 붙여보려는 시도는 있었으나 방향 전환/충돌 처리가 빠져 있어 실질적으로
  미완성 상태 ([test_enemy 좌우 이동 시도](#test_enemy-좌우-이동-시도-2026-09-23-손코딩-실험--미완성버그-있음) 참고)
- Pre-Signal 지속시간(0.35s)과 카운터 윈도우(0.4s)를 합친 전체 리드타임은
  실제 전투 환경 구축 후 플레이테스트에서 확인할 것.
