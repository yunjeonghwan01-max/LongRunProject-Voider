class_name HitSpark
extends Node2D

## 공격이 적중했을 때 타격 지점에 표시되는 보라색 원형 스파크.
## 짧게 확산되며 사라지는 1회성 연출로, 타격을 더 명확하게 체감시키기 위한 용도다.

@export var spark_color: Color = Color(0.85, 0.55, 1.0, 0.9)
@export var start_radius: float = 4.0
@export var end_radius: float = 22.0
@export var lifetime: float = 0.16

@onready var _polygon: Polygon2D = $polygon


func _ready() -> void:
	_polygon.color = spark_color
	_set_ring_radius(start_radius)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(_set_ring_radius, start_radius, end_radius, lifetime) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_polygon, "modulate:a", 0.0, lifetime) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)


func _set_ring_radius(r: float) -> void:
	var points := PackedVector2Array()
	var segments := 12
	for i in range(segments):
		var t := TAU * float(i) / segments
		points.append(Vector2(cos(t), sin(t)) * r)
	_polygon.polygon = points
