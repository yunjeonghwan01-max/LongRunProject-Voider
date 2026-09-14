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
- 근접 기본 공격: startup(0.08s) → active(0.12s) → recovery(0.25s) 3단계 상태 머신
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

## 플레이테스트 결과 (카운터 윈도우 튜닝)
- **counter_window_duration = 0.25s**: 근접 공격과 카운터 입력을 병행해야 하는 상황에서
  지나치게 어려움 (반응 여유가 거의 없어 실패율이 높았음)
- **counter_window_duration = 0.4s**: 훨씬 수월하게 느껴짐. 다만 이 값이 일반 플레이어
  기준으로도 적절한 난이도인지는 아직 미검증 (테스터가 제한적이었음)
- 현재 코드 기본값은 0.4s (`ranged_attack.gd`)로 되어 있음
- 현재의 **counter_window_duration 0.4s + Pre-Signal** 조합은 카운터 v0.1의 임시 가설로 둠.
- 카운터만 분리한 환경에서의 추가 미세튜닝은 보류. 실제 전투 환경을 먼저 만든 뒤,
  이동/공격/회피/스킬과 적의 다른 행동이 동시에 일어나는 상황에서 체감을 다시 검증할 것.

## 다음에 이어서 볼 것
- 현재 방향: 카운터만 계속 미세튜닝하지 않고 실제 전투 환경을 만들며 검증한다.
- 다음 우선순위:
  1. Godot 에디터에서 직접 설계할 수 있는 전투 테스트용 TileMap/플랫폼 환경 구축
  2. 플레이어 대쉬 구현
  3. 역할이 분명한 플레이어 스킬 1개 구현
  4. 강한 필드몹 수준의 적 AI/스탯 및 복수 행동 패턴 구현
  5. 해당 행동 패턴 중 하나로 카유공을 간헐적으로 섞어 실제 전투 중 카운터 체감 검증
- `CounterResult`를 실제로 소비하는 시스템(궁극기 게이지 등)이 아직 없음 — 필요 시 연결
- 근접 공격에는 아직 counterable 개념이 없음 (원거리만 카운터 가능)
- 적 AI/이동/복수 공격 패턴은 아직 미구현 (`test_enemy`는 검증용 스텁)
- Pre-Signal 지속시간(0.35s)과 카운터 윈도우(0.4s)를 합친 전체 리드타임은
  실제 전투 환경 구축 후 플레이테스트에서 확인할 것.
