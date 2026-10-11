class_name Player
extends CharacterBody2D

## 2D 횡스크롤 프로토타입용 기본 플레이어 컨트롤러.
## 이동/점프/중력/대쉬/바라보는 방향을 담당한다.
## 전투 기능은 Combat/ 아래 Ability 노드가 각자 입력을 받아 처리한다 (트리 순서 = 입력 처리 순서):
##   Combat/Counter (PlayerCounter), Combat/MeleeAttack (MeleeAttack), Combat/WindblastAbility (WindblastAbility)

@export var speed: float = 300.0
@export var jump_velocity: float = -420.0
@export var gravity: float = 1100.0

@export_group("Dash")
@export var dash_speed: float = 900.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5

var facing_direction: int = 1

var is_dashing: bool = false
var can_dash: bool = true

@onready var camera: CameraShake = $Camera
@onready var status_label: StatusLabel = $StatusLabel
@onready var _visual: Node2D = $Visual
@onready var _counter: PlayerCounter = $Combat/Counter
@onready var _melee_attack: MeleeAttack = $Combat/MeleeAttack


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("player_jump") and is_on_floor():
		velocity.y = jump_velocity

	if not is_dashing:
		var direction := Input.get_axis("player_move_left", "player_move_right")
		var move_speed := speed
		if _melee_attack.is_attacking:
			move_speed *= _melee_attack.move_speed_scale
		if direction != 0.0:
			velocity.x = direction * move_speed
			_set_facing_direction(int(sign(direction)))
		else:
			velocity.x = move_toward(velocity.x, 0.0, move_speed)

	move_and_slide()

	if Input.is_action_just_pressed("player_dash") and can_dash and not is_dashing:
		_start_dash()


func _set_facing_direction(new_direction: int) -> void:
	if new_direction == 0 or new_direction == facing_direction:
		return
	facing_direction = new_direction
	if _visual:
		_visual.scale.x = facing_direction
	_melee_attack.update_facing(facing_direction)


## CounterableAttack이 counter window를 열고 닫을 때 호출하는 Player 쪽 진입점. 실제 처리는 Combat/Counter.
func set_counter_target(attack: CounterableAttack) -> void:
	_counter.set_target(attack)


func clear_counter_target(attack: CounterableAttack) -> void:
	_counter.clear_target(attack)


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
