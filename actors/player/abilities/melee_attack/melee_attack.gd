class_name MeleeAttack
extends Node2D

## 플레이어 근접 기본 공격 1타의 startup -> active -> recovery 흐름.
## 카운터 시스템과 결합하지 않으며, 진행 중 취소 없이 끝까지 흐른다.

@export var startup_duration: float = 0.08
@export var active_duration: float = 0.12
@export var recovery_duration: float = 0.25
@export var damage: int = 1
@export var hitbox_offset: float = 28.0
@export var move_speed_scale: float = 1.0  ## 공격 중 Player 이동 속도 배율

@export_group("Effects")
@export var slash_effect_scene: PackedScene
@export var hit_spark_scene: PackedScene
@export var hit_shake_strength: float = 1.8
@export var hit_shake_duration: float = 0.08

var is_attacking: bool = false
var can_attack: bool = true
var _hit_targets: Array = []

@onready var _player: Player = owner as Player
@onready var _hitbox: Area2D = $AttackHitbox
@onready var _hitbox_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D


func _ready() -> void:
	for scene_name in ["slash_effect_scene", "hit_spark_scene"]:
		if get(scene_name) == null:
			push_warning("[MeleeAttack] %s is not assigned in the scene" % scene_name)
	_hitbox.area_entered.connect(_on_hitbox_area_entered)
	update_facing(_player.facing_direction)


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("player_attack") and can_attack and not is_attacking:
		_start_attack()


## AttackHitbox는 플레이어 collision/visual scale과 독립적으로,
## 바라보는 방향에 따라 자신의 position.x만 좌우로 반전한다.
func update_facing(facing_direction: int) -> void:
	_hitbox.position.x = hitbox_offset * facing_direction


func _start_attack() -> void:
	is_attacking = true
	can_attack = false
	_hit_targets.clear()
	print("ATTACK START")

	await get_tree().create_timer(startup_duration).timeout
	_activate_hitbox()

	await get_tree().create_timer(active_duration).timeout
	_deactivate_hitbox()

	await get_tree().create_timer(recovery_duration).timeout
	is_attacking = false
	can_attack = true
	print("ATTACK END")


func _activate_hitbox() -> void:
	_hitbox.monitoring = true
	_hitbox_shape.disabled = false
	_spawn_slash_effect()
	print("ATTACK ACTIVE")


## 공격 판정이 켜지는 순간, 바라보는 방향으로 보라색 초승달 참격 이펙트를 스폰한다.
## 레벨 Effects 컨테이너가 아니라 이 노드(Player를 따라 움직이고 스스로는 반전되지 않음)의 자식으로 붙여
## 이동 중에도 플레이어에 붙어 다니게 한다. 좌우 반전은 SlashEffect.facing으로 전달한다.
func _spawn_slash_effect() -> void:
	if not slash_effect_scene:
		return

	var facing := _player.facing_direction
	var slash: SlashEffect = slash_effect_scene.instantiate()
	slash.facing = facing
	slash.rotation = deg_to_rad(-20.0 * facing)
	slash.position = Vector2(hitbox_offset * facing, 0.0)
	add_child(slash)


func _deactivate_hitbox() -> void:
	_hitbox.monitoring = false
	_hitbox_shape.disabled = true


## 한 번의 공격 active time 동안 같은 대상은 한 번만 타격한다.
## Hurtbox는 Actor의 Combat/ 아래에 있으므로 씬 루트(owner)를 피격 대상으로 본다.
## (Structure Refactor V0의 동작 보존용 최소 수정. Hurtbox 컴포넌트화 전까지의 임시 조회 방식)
func _on_hitbox_area_entered(area: Area2D) -> void:
	var target := area.owner
	if target == null or target in _hit_targets:
		return

	_hit_targets.append(target)

	print("PLAYER ATTACK HIT")
	print("Target: %s" % target.name)
	print("Damage: %d" % damage)

	_spawn_hit_spark(area.global_position)
	if _player.camera:
		_player.camera.shake(hit_shake_strength, hit_shake_duration)

	if target.has_method("take_damage"):
		target.take_damage(damage, _player)


## 타격 지점에 보라색 히트 스파크를 스폰해 타격감을 명확히 드러낸다.
func _spawn_hit_spark(spawn_position: Vector2) -> void:
	if not hit_spark_scene:
		return

	var spark: Node2D = hit_spark_scene.instantiate()
	spark.global_position = spawn_position
	LevelContainers.effects(self).add_child(spark)
