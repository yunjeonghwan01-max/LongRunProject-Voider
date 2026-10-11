class_name PlayerCounter
extends Node

## 플레이어 카운터 입력 처리.
## CounterableAttack이 counter window를 열 때 Player를 통해 대상으로 등록되고(set_target),
## 카운터 입력이 들어오면 그 공격에게 판정을 요청한다. 실패(whiff/MISS) 시 recovery 동안 재입력 불가.

@export var recovery_duration: float = 0.3

var active_target: CounterableAttack = null
var is_in_recovery: bool = false
var _recovery_elapsed: float = 0.0

@onready var _player: Player = owner as Player


func _physics_process(delta: float) -> void:
	if is_in_recovery:
		_recovery_elapsed += delta
		if _recovery_elapsed >= recovery_duration:
			is_in_recovery = false

	# 공격 중에도 카운터 입력은 항상 허용한다 (공격/카운터 로직은 서로 독립적으로 유지).
	if Input.is_action_just_pressed("player_counter"):
		_try_counter()


## CounterableAttack이 counter window를 여는 시점에 스스로를 등록한다.
func set_target(attack: CounterableAttack) -> void:
	active_target = attack
	_player.status_label.show_text("!", Color(1, 0.9, 0.2, 1), 0.0)


## CounterableAttack이 counter window를 닫거나 무효화될 때 스스로를 해제한다.
func clear_target(attack: CounterableAttack) -> void:
	if active_target == attack:
		active_target = null
		_player.status_label.hide_text("!")


## 카운터 입력이 들어왔을 때 현재 대상 공격에게 판정을 요청한다.
## 대상 공격이 없다면 존재하는 다른 공격들에게 실패 이벤트를 뿌리지 않고 로컬 후딜만 적용한다.
func _try_counter() -> void:
	if is_in_recovery:
		return

	print("[Counter] input received")

	if active_target == null:
		print("[Counter] no active target - whiff")
		_player.status_label.show_text("MISS", Color(1, 0.3, 0.3, 1))
		_start_recovery()
		return

	var target := active_target
	var success := target.try_counter()
	if success:
		active_target = null
		_player.status_label.show_text("COUNTER SUCCESS", Color(0.3, 1, 0.4, 1))
	else:
		_player.status_label.show_text("MISS", Color(1, 0.3, 0.3, 1))
		_start_recovery()


func _start_recovery() -> void:
	is_in_recovery = true
	_recovery_elapsed = 0.0
