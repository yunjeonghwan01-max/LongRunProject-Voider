class_name CounterResult
extends RefCounted

## Counter 성공/실패 결과를 다른 시스템에 전달하기 위한 데이터.
## 궁극기 게이지 등 후속 시스템이 이 데이터를 구독해서 사용할 수 있다 (현재는 미연결).

var attacker: Node
var attack_type: String
var input_time_msec: int
var success: bool


func _init(p_attacker: Node, p_attack_type: String, p_input_time_msec: int, p_success: bool) -> void:
	attacker = p_attacker
	attack_type = p_attack_type
	input_time_msec = p_input_time_msec
	success = p_success
