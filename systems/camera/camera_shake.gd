class_name CameraShake
extends Camera2D

## 재사용 가능한 최소 화면 흔들림 컴포넌트.
## shake()를 호출한 쪽의 세기가 더 강할 때만 갱신되므로(누적X, 최댓값만 반영),
## 짧은 간격으로 여러 번 호출되어도 흔들림이 과도하게 증폭되지 않는다.

var _shake_strength: float = 0.0
var _shake_duration: float = 0.0
var _shake_elapsed: float = 0.0


func _ready() -> void:
	add_to_group("player_camera")


func shake(strength: float, duration: float) -> void:
	if _shake_elapsed < _shake_duration and _shake_strength * (1.0 - _shake_elapsed / _shake_duration) >= strength:
		return
	_shake_strength = strength
	_shake_duration = duration
	_shake_elapsed = 0.0


func _process(delta: float) -> void:
	if _shake_elapsed >= _shake_duration:
		if offset != Vector2.ZERO:
			offset = Vector2.ZERO
		return

	_shake_elapsed += delta
	var remaining := 1.0 - (_shake_elapsed / _shake_duration)
	var current_strength := _shake_strength * remaining
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * current_strength
