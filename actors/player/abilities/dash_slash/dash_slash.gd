class_name DashSlash
extends Node2D

## 대시 중에만 발동하는 베기. startup -> active -> recovery 흐름은 MeleeAttack과 같다.

@export var startup_duration: float = 0.08
@export var active_duration: float = 0.12
@export var recovery_duration: float = 0.25
@export var hitbox_offset: float = 28.0
@export var move_speed_scale: float = 1.0

@export var slash_effect_scene: PackedScene

var is_attacking: bool = false
var can_attack: bool = true

@onready var _player: Player = owner as Player
@onready var _hitbox: HitboxComponent = $SlashHitbox
@onready var _hitbox_shape: CollisionShape2D = $SlashHitbox/CollisionShape2D


func _ready() -> void:
	if slash_effect_scene == null:
		push_warning("[DashSlash] slash_effect_scene is not assigned in the scene")
	update_facing(_player.facing_direction)


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("player_skill1") and _player.is_dashing and can_attack and not is_attacking:
		_start_slash()


func update_facing(facing_direction: int) -> void:
	_hitbox.position.x = hitbox_offset * facing_direction


func _start_slash() -> void:
	is_attacking = true
	can_attack = false
	_hitbox.reset_hits()
	update_facing(_player.facing_direction)

	await get_tree().create_timer(startup_duration).timeout
	_activate_hitbox()

	await get_tree().create_timer(active_duration).timeout
	_deactivate_hitbox()

	await get_tree().create_timer(recovery_duration).timeout
	is_attacking = false
	can_attack = true


func _activate_hitbox() -> void:
	_hitbox.monitoring = true
	_hitbox_shape.disabled = false
	_spawn_slash_effect()


func _deactivate_hitbox() -> void:
	_hitbox.monitoring = false
	_hitbox_shape.disabled = true


func _spawn_slash_effect() -> void:
	if not slash_effect_scene:
		return

	var facing := _player.facing_direction
	var slash: SlashEffect = slash_effect_scene.instantiate()
	slash.facing = facing
	slash.rotation = deg_to_rad(-20.0 * facing)
	slash.position = Vector2(hitbox_offset * facing, 0.0)
	add_child(slash)
