class_name WindblastAbility
extends Node

## 바라보는 방향으로 장풍(WindblastProjectile)을 발사한다. 발사 직후 cooldown 동안 재사용 불가.
## 발사 반동으로 플레이어에게도 아주 작은 역방향 임펄스를 준다.

@export var projectile_scene: PackedScene
@export var cooldown: float = 1.5
@export var spawn_offset: float = 30.0
@export var recoil_speed: float = 60.0  ## 발사 시 플레이어에게 가해지는 아주 작은 반동
@export var fire_shake_strength: float = 2.0
@export var fire_shake_duration: float = 0.15

var can_use: bool = true

@onready var _player: Player = owner as Player


func _ready() -> void:
	if projectile_scene == null:
		push_warning("[WindblastAbility] projectile_scene is not assigned in the scene")


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("player_skill1") and can_use and not _player.is_dashing:
		_fire()


func _fire() -> void:
	can_use = false
	var facing := _player.facing_direction
	print("[Windblast] FIRE facing=%d pos=%s" % [facing, _player.global_position])

	_spawn_projectile()
	_player.velocity.x -= facing * recoil_speed
	if _player.camera:
		_player.camera.shake(fire_shake_strength, fire_shake_duration)

	await get_tree().create_timer(cooldown).timeout
	can_use = true


func _spawn_projectile() -> void:
	if not projectile_scene:
		return

	var facing := _player.facing_direction
	var projectile: WindblastProjectile = projectile_scene.instantiate()
	projectile.attacker = _player
	projectile.travel_direction = Vector2(facing, 0.0)
	projectile.global_position = _player.global_position + Vector2(spawn_offset * facing, 0.0)
	LevelContainers.projectiles(self).add_child(projectile)
