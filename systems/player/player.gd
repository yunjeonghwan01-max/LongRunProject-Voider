extends CharacterBody2D

## 2D 횡스크롤 프로토타입용 기본 플레이어 컨트롤러.
## 이동/점프/중력/바닥 판정/바라보는 방향 + 별도 InputMap counter 액션 처리를 담당한다.

@export var speed: float = 300.0
@export var jump_velocity: float = -420.0
@export var gravity: float = 1100.0
@export var counter_recovery_duration: float = 0.3

var facing_direction: int = 1

var active_counter_target: Attack = null
var is_in_counter_recovery: bool = false
var _counter_recovery_elapsed: float = 0.0

@onready var _visual: Node2D = $visual
@onready var _status_label: Label = $status_label


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("player_jump") and is_on_floor():
		velocity.y = jump_velocity

	var direction := Input.get_axis("player_move_left", "player_move_right")
	if direction != 0.0:
		velocity.x = direction * speed
		_set_facing_direction(int(sign(direction)))
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)

	move_and_slide()

	if is_in_counter_recovery:
		_counter_recovery_elapsed += delta
		if _counter_recovery_elapsed >= counter_recovery_duration:
			is_in_counter_recovery = false

	if Input.is_action_just_pressed("player_counter"):
		_try_counter()


func _set_facing_direction(new_direction: int) -> void:
	if new_direction == 0 or new_direction == facing_direction:
		return
	facing_direction = new_direction
	if _visual:
		_visual.scale.x = facing_direction


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
