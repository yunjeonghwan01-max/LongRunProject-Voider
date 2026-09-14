extends CharacterBody2D

## 2D 횡스크롤 프로토타입용 기본 플레이어 컨트롤러.
## 이동/점프/중력/바닥 판정/바라보는 방향 + 별도 InputMap counter 액션 처리를 담당한다.

@export var speed: float = 300.0
@export var jump_velocity: float = -420.0
@export var gravity: float = 1100.0
@export var counter_recovery_duration: float = 0.3

@export_group("Dash")
@export var dash_speed: float = 900.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5

@export_group("Basic Attack")
@export var attack_startup_duration: float = 0.08
@export var attack_active_duration: float = 0.12
@export var attack_recovery_duration: float = 0.25
@export var attack_damage: int = 1
@export var attack_hitbox_offset: float = 28.0
@export var attack_move_speed_scale: float = 1.0

var facing_direction: int = 1

var is_dashing: bool = false
var can_dash: bool = true

var active_counter_target: Attack = null
var is_in_counter_recovery: bool = false
var _counter_recovery_elapsed: float = 0.0

var is_attacking: bool = false
var can_attack: bool = true
var _attack_hit_targets: Array = []

@onready var _visual: Node2D = $visual
@onready var _status_label: Label = $status_label
@onready var _attack_hitbox: Area2D = $attack_hitbox
@onready var _attack_hitbox_shape: CollisionShape2D = $attack_hitbox/collision_shape


func _ready() -> void:
	add_to_group("player")
	_update_attack_hitbox_position()
	if _attack_hitbox:
		_attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("player_jump") and is_on_floor():
		velocity.y = jump_velocity

	if not is_dashing:
		var direction := Input.get_axis("player_move_left", "player_move_right")
		var move_speed := speed
		if is_attacking:
			move_speed *= attack_move_speed_scale
		if direction != 0.0:
			velocity.x = direction * move_speed
			_set_facing_direction(int(sign(direction)))
		else:
			velocity.x = move_toward(velocity.x, 0.0, move_speed)

	move_and_slide()

	if Input.is_action_just_pressed("player_dash") and can_dash and not is_dashing:
		_start_dash()

	if is_in_counter_recovery:
		_counter_recovery_elapsed += delta
		if _counter_recovery_elapsed >= counter_recovery_duration:
			is_in_counter_recovery = false

	# 공격 중에도 카운터 입력은 항상 허용한다 (공격/카운터 로직은 서로 독립적으로 유지).
	if Input.is_action_just_pressed("player_counter"):
		_try_counter()

	if Input.is_action_just_pressed("player_attack") and can_attack and not is_attacking:
		_start_attack()


func _set_facing_direction(new_direction: int) -> void:
	if new_direction == 0 or new_direction == facing_direction:
		return
	facing_direction = new_direction
	if _visual:
		_visual.scale.x = facing_direction
	_update_attack_hitbox_position()


## AttackHitBox는 플레이어 collision/visual scale과 독립적으로,
## 바라보는 방향에 따라 자신의 position.x만 좌우로 반전한다.
func _update_attack_hitbox_position() -> void:
	if _attack_hitbox:
		_attack_hitbox.position.x = attack_hitbox_offset * facing_direction


## Attack이 counter window를 여는 시점에 스스로를 등록한다.
func set_counter_target(attack: Attack) -> void:
	active_counter_target = attack
	_show_status("!", Color(1, 0.9, 0.2, 1), 0.0)


## Attack이 counter window를 닫거나 무효화될 때 스스로를 해제한다.
func clear_counter_target(attack: Attack) -> void:
	if active_counter_target == attack:
		active_counter_target = null
		if _status_label and _status_label.text == "!":
			_status_label.visible = false


## 카운터 입력이 들어왔을 때 현재 대상 공격에게 판정을 요청한다.
## 대상 공격이 없다면 존재하는 다른 공격들에게 실패 이벤트를 뿌리지 않고 로컬 후딜만 적용한다.
func _try_counter() -> void:
	if is_in_counter_recovery:
		return

	print("[Counter] input received")

	if active_counter_target == null:
		print("[Counter] no active target - whiff")
		_show_status("MISS", Color(1, 0.3, 0.3, 1))
		_start_counter_recovery()
		return

	var target := active_counter_target
	var success := target.try_counter()
	if success:
		active_counter_target = null
		_show_status("COUNTER SUCCESS", Color(0.3, 1, 0.4, 1))
	else:
		_show_status("MISS", Color(1, 0.3, 0.3, 1))
		_start_counter_recovery()


## 현재 바라보는 방향으로 짧고 빠르게 이동하는 기본 대쉬.
## 대쉬 중에는 재발동이 불가능하며, 종료 후 쿨다운이 지나야 다시 사용할 수 있다.
func _start_dash() -> void:
	is_dashing = true
	can_dash = false
	velocity.x = facing_direction * dash_speed

	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false

	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true


## 근접 기본 공격 1타의 startup -> active -> recovery 흐름.
## 카운터 시스템과 결합하지 않으며, 진행 중 취소 없이 끝까지 흐른다.
func _start_attack() -> void:
	is_attacking = true
	can_attack = false
	_attack_hit_targets.clear()
	print("ATTACK START")

	await get_tree().create_timer(attack_startup_duration).timeout
	_activate_attack_hitbox()

	await get_tree().create_timer(attack_active_duration).timeout
	_deactivate_attack_hitbox()

	await get_tree().create_timer(attack_recovery_duration).timeout
	is_attacking = false
	can_attack = true
	print("ATTACK END")


func _activate_attack_hitbox() -> void:
	if not _attack_hitbox or not _attack_hitbox_shape:
		return
	_attack_hitbox.monitoring = true
	_attack_hitbox_shape.disabled = false
	print("ATTACK ACTIVE")


func _deactivate_attack_hitbox() -> void:
	if not _attack_hitbox or not _attack_hitbox_shape:
		return
	_attack_hitbox.monitoring = false
	_attack_hitbox_shape.disabled = true


## 한 번의 공격 active time 동안 같은 대상은 한 번만 타격한다.
func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	var target := area.get_parent()
	if target == null or target in _attack_hit_targets:
		return

	_attack_hit_targets.append(target)

	print("PLAYER ATTACK HIT")
	print("Target: %s" % target.name)
	print("Damage: %d" % attack_damage)

	if target.has_method("take_damage"):
		target.take_damage(attack_damage, self)


func _start_counter_recovery() -> void:
	is_in_counter_recovery = true
	_counter_recovery_elapsed = 0.0


## 플레이어 머리 위에 짧게 상태 텍스트를 표시한다. duration이 0이면 clear될 때까지 유지된다.
func _show_status(text: String, color: Color, duration: float = 0.6) -> void:
	if not _status_label:
		return

	_status_label.text = text
	_status_label.modulate = color
	_status_label.visible = true

	if duration > 0.0:
		var label := _status_label
		var shown_text := text
		get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(label) and label.text == shown_text:
				label.visible = false
		)
