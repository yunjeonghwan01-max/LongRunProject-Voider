class_name RangedAttackAbility
extends Node

## TestEnemy의 원거리 counterable attack 발동.
## attack_interval마다 플레이어를 향해 RangedAttackProjectile을 스폰한다.

@export var projectile_scene: PackedScene
@export var attack_interval: float = 2.5

@onready var _enemy: TestEnemy = owner as TestEnemy
@onready var _attack_timer: Timer = $AttackTimer


func _ready() -> void:
	if projectile_scene == null:
		push_warning("[RangedAttackAbility] projectile_scene is not assigned in the scene")
	_attack_timer.wait_time = attack_interval
	_attack_timer.timeout.connect(_on_attack_timer_timeout)
	_attack_timer.start()


func _on_attack_timer_timeout() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	_spawn_projectile(player)


func _spawn_projectile(player: Node2D) -> void:
	if projectile_scene == null:
		return

	var projectile: RangedAttackProjectile = projectile_scene.instantiate()
	projectile.attacker = _enemy
	projectile.facing_direction = _enemy.facing_direction
	projectile.target_player = player
	projectile.global_position = _enemy.global_position
	LevelContainers.projectiles(self).add_child(projectile)
