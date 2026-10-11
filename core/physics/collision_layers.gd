class_name CollisionLayers

## 2D 물리 레이어 비트마스크 정의. project.godot의 [layer_names]와 번호를 반드시 일치시킨다.
##
## 설계 원칙: "땅을 밟는 바디"와 "공격/피격 트리거"를 서로 다른 노드·레이어로 분리한다.
##   - 바디(CharacterBody2D)는 WORLD만 mask → 플레이어/적 바디끼리는 서로 밀어내지 않는다.
##   - 공격(Area2D)은 상대 진영의 HURTBOX만 mask → 바디/지형과는 무관하게 피격 판정만 한다.
##   - 허트박스(Area2D)는 monitorable 전용(layer만, mask 0) → 스스로 감지하지 않고 감지'당'하기만 한다.
##
## | 레이어 | 이름            | 사용 노드                       | mask                |
## |--------|-----------------|---------------------------------|---------------------|
## | 1      | world           | TileMapLayer (지형/벽)          | -                   |
## | 2      | player_body     | Player (CharacterBody2D)        | WORLD               |
## | 3      | enemy_body      | TestEnemy (CharacterBody2D)     | WORLD               |
## | 4      | player_attack   | Player/Combat/MeleeAttack/AttackHitbox, WindblastProjectile/Hitbox | ENEMY_HURTBOX |
## | 5      | enemy_hurtbox   | TestEnemy/Combat/Hurtbox (HurtboxComponent) | 0       |
## | 6      | player_hurtbox  | Player/Combat/Hurtbox (HurtboxComponent) | 0          |
## | 7      | enemy_attack    | RangedAttackProjectile/Hitbox   | PLAYER_HURTBOX      |
##
## 투사체의 지형 소멸용 `Collision` Area2D는 layer 0, mask WORLD (감지만 하고 감지당하지 않는다).

const WORLD := 1 << 0
const PLAYER_BODY := 1 << 1
const ENEMY_BODY := 1 << 2
const PLAYER_ATTACK := 1 << 3
const ENEMY_HURTBOX := 1 << 4
const PLAYER_HURTBOX := 1 << 5
const ENEMY_ATTACK := 1 << 6
