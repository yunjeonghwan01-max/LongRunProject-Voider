class_name Attack
extends Node2D

## 모든 공격의 공통 상태/판정 기반 클래스.
## 상태 = 변수, 판정 = 함수, 결과 전달 = Signal 원칙을 따른다.

@export var attack_type: String = "generic"
@export var counterable: bool = false
@export var counter_window_duration: float = 0.25

var attacker: Node = null
var counter_window_open: bool = false
var was_countered: bool = false
var is_valid: bool = true

signal counter_succeeded(result: CounterResult)


## 카운터 성공 여부를 자신의 상태를 기준으로 판정한다. 최대 한 번만 성공할 수 있다.
func try_counter() -> bool:
	var input_time := Time.get_ticks_msec()
	if not counterable or not is_valid or was_countered or not counter_window_open:
		print("[Counter] input REJECTED type=%s counterable=%s is_valid=%s was_countered=%s window_open=%s" % [
			attack_type, counterable, is_valid, was_countered, counter_window_open
		])
		return false

	was_countered = true
	is_valid = false
	print("[Counter] COUNTER SUCCESS type=%s attacker=%s" % [attack_type, attacker])

	var result := CounterResult.new(attacker, attack_type, input_time, true)
	counter_succeeded.emit(result)
	_on_countered()
	return true


## 카운터 성공 시 공격을 무효화한다. 서브클래스에서 확장 가능.
func _on_countered() -> void:
	queue_free()
