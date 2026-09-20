extends Node2D

@onready var sprite: Sprite2D = $sprite


func _ready() -> void:
	get_viewport().size_changed.connect(_update_scale)
	_update_scale()


func _update_scale() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var texture_size: Vector2 = sprite.texture.get_size()
	if texture_size.x == 0 or texture_size.y == 0:
		return
	var scale_factor: float = max(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.position = viewport_size / 2.0
