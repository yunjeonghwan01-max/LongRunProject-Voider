class_name SlashEffect
extends Node2D

## 기본 근접 공격에 맞춰 표시되는 보라색 초승달(크레센트) 참격 이펙트.
## 스폰 직후 짧게 확대되며 페이드아웃되는 1회성 연출이며, 재생이 끝나면 스스로 삭제된다.

@export var slash_color: Color = Color(0.65, 0.25, 0.95, 0.95)
@export var radius: float = 34.0
@export var thickness: float = 10.0
@export var arc_degrees: float = 140.0
@export var lifetime: float = 0.18

@onready var _polygon: Polygon2D = $polygon


func _ready() -> void:
	_polygon.polygon = _build_crescent_points()
	_polygon.color = slash_color
	scale = Vector2(0.5, 0.5)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), lifetime) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_polygon, "modulate:a", 0.0, lifetime) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)


## 바깥쪽 큰 호와 안쪽 작은 호를 이어 초승달 모양 폴리곤을 만든다.
## 두 호의 반지름 차이(thickness)가 초승달의 두께가 된다.
func _build_crescent_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	var half_arc := deg_to_rad(arc_degrees) * 0.5
	var segments := 16

	for i in range(segments + 1):
		var t: float = lerp(-half_arc, half_arc, float(i) / segments)
		points.append(Vector2(cos(t), sin(t)) * radius)

	var inner_radius := radius - thickness
	for i in range(segments + 1):
		var t: float = lerp(half_arc, -half_arc, float(i) / segments)
		points.append(Vector2(cos(t), sin(t)) * inner_radius)

	return points
