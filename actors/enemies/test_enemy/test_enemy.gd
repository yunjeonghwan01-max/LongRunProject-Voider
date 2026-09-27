extends CharacterBody2D

## 카운터 시스템 검증용 최소 테스트 적.
## 좌우로 이동하다 벽(WORLD)에 닿으면 방향을 바꾸고, 일정 주기로 원거리 counterable attack을 발동한다.
##
## 충돌 노드 분리 (레이어 정의: systems/physics/collision_layers.gd)
##   - 루트 collision_shape: 지형 전용 바디 (layer ENEMY_BODY, mask WORLD) → 플레이어와는 부딪히지 않는다.
##   - hurtbox (Area2D): 피격 트리거 (layer ENEMY_HURTBOX) → 플레이어 공격 판정만 받는다.

const RANGED_ATTACK_SCENE := preload("res://systems/combat/ranged_attack.tscn")

@export var attack_interval: float = 2.5
@export var facing_direction: Vector2 = Vector2.LEFT
@export var move_speed = 100
@export var max_health: int = 3
var health: int

var _knockback_tween: Tween = null
var _flash_tween: Tween = null
var _body_original_modulate: Color

@onready var _attack_timer: Timer = $attack_timer
@onready var _body: AnimatedSprite2D = $body


func _ready() -> void:
	health = max_health
	_attack_timer.wait_time = attack_interval
	_attack_timer.timeout.connect(_on_attack_timer_timeout)
	_attack_timer.start()
	if _body:
		_body_original_modulate = _body.modulate
func _physics_process(delta):
	_move(delta)


## 플레이어 근접 공격 HitBox / 장풍 등이 hurtbox에 닿았을 때 호출된다.
## 별도의 체력 시스템이 없으므로 최소한의 health 감소 + 로그만 처리한다.
## knockback이 주어지면(넉백 벡터, 픽셀 단위 변위) 살짝 밀려나는 연출을 적용한다.
func take_damage(amount: int, _source: Node, knockback: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	print("[Enemy] %s took %d damage (health=%d/%d)" % [name, amount, health, max_health])

	_flash_hit()

	if knockback != Vector2.ZERO:
		_apply_knockback(knockback)

	if health <= 0:
		print("[Enemy] %s defeated" % name)
		queue_free()


## 피격 시 스프라이트 modulate를 순간 밝게 올렸다가 원래 값으로 되돌려, 타격을 눈에 띄게 드러낸다.
## 다단히트로 연속 호출되어도 깜빡이지 않도록 이전 플래시 Tween은 덮어쓴다.
func _flash_hit() -> void:
	if not _body:
		return

	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()

	_body.modulate = Color(4, 4, 4, 1)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_body, "modulate", _body_original_modulate, 0.12)


## 짧은 Tween으로 위치를 살짝 밀어내는 것으로
## 넉백을 대신한다. 다단히트로 연속 호출되어도 튀지 않도록 이전 넉백 Tween은 덮어쓴다.
func _apply_knockback(knockback: Vector2) -> void:
	if _knockback_tween and _knockback_tween.is_valid():
		_knockback_tween.kill()

	var target_position := position + knockback
	_knockback_tween = create_tween()
	_knockback_tween.tween_property(self, "position", target_position, 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_attack_timer_timeout() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	_spawn_ranged_attack(player)


func _spawn_ranged_attack(player: Node2D) -> void:
	var attack: RangedAttack = RANGED_ATTACK_SCENE.instantiate()
	attack.attacker = self
	attack.facing_direction = facing_direction
	attack.target_player = player
	attack.global_position = global_position
	get_parent().add_child(attack)

func change_facing_dir():
	facing_direction = -facing_direction
	# 스프라이트 기본 방향이 왼쪽이므로, 오른쪽을 볼 때만 X 스케일을 뒤집는다.
	var body_scale := _body.scale
	body_scale.x = absf(body_scale.x) * (-1.0 if facing_direction.x > 0.0 else 1.0)
	_body.scale = body_scale


func _move(_delta: float) -> void:
	velocity.x = facing_direction.x * move_speed
	move_and_slide()
	if is_on_wall():
		change_facing_dir()
	

	
	
