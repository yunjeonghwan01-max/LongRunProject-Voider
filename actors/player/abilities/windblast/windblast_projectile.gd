class_name WindblastProjectile
extends Node2D

## Hollow Knight의 Vengeful Spirit과 유사한 전방 직선 관통 투사체.
## 여러 적을 관통하며, 적 하나당 최대 max_hits_per_target회까지 hit_interval 간격으로
## 다단히트를 적용한다. 다단히트는 물리적으로 계속 겹쳐 있는지와 무관하게, 최초 접촉
## 시점부터 독립적인 타이머로 진행되어 max_hits_per_target을 절대 넘지 않는다.
##
## Hitbox는 접촉만 알리고(apply_on_contact = false, 대상당 1회), 다단히트는 이 스크립트가 직접 건다.
## Collision은 지형(WORLD)만 감지해 닿으면 소멸한다 (layer 0. monitorable을 끄면 TileMap 바디를 감지하지 못하므로 켜 둔다).

@export var speed: float = 900.0
@export var max_lifetime: float = 2.0

@export_group("Multi Hit")
@export var max_hits_per_target: int = 3
@export var hit_interval: float = 0.1
@export var total_damage: int = 20  ## 플레이어 기본 공격 총 데미지(10)의 약 2배

@export_group("Knockback")
@export var enemy_knockback_per_hit: float = 14.0

@export_group("Screen Shake")
@export var hit_shake_strength: float = 2.5
@export var hit_shake_duration: float = 0.1

var attacker: Node = null
var travel_direction: Vector2 = Vector2.RIGHT

var _hit_damages: Array[int] = []
var _lifetime_elapsed: float = 0.0

@onready var _visual: Node2D = $Visual
@onready var _hitbox: HitboxComponent = $Hitbox
@onready var _collision: Area2D = $Collision


func _ready() -> void:
	_compute_hit_damages()

	if travel_direction.x != 0.0:
		_visual.scale.x = sign(travel_direction.x)

	_hitbox.source = attacker
	_hitbox.hurtbox_entered.connect(_on_hurtbox_entered)
	_collision.body_entered.connect(_on_terrain_entered)

	print("[Windblast] SPAWN attacker=%s travel_direction=%s pos=%s hit_damages=%s" % [
		attacker, travel_direction, global_position, _hit_damages
	])


func _physics_process(delta: float) -> void:
	_lifetime_elapsed += delta
	global_position += travel_direction * speed * delta

	if _lifetime_elapsed >= max_lifetime:
		queue_free()


## total_damage를 max_hits_per_target개로 최대한 고르게 나눈다.
## 정수 나눗셈으로 나누어떨어지지 않는 나머지는 앞쪽 히트부터 1씩 더 배분한다.
## 예: total=20, max_hits=3 -> [7, 7, 6]
func _compute_hit_damages() -> void:
	_hit_damages.clear()
	var base := total_damage / max_hits_per_target
	var remainder := total_damage % max_hits_per_target
	for i in max_hits_per_target:
		_hit_damages.append(base + (1 if i < remainder else 0))


func _on_terrain_entered(body: Node) -> void:
	# Collision의 mask가 WORLD만 포함하므로 여기로 들어오는 바디는 지형뿐이다. 벽/지형 충돌 시 자연스럽게 소멸.
	print("[Windblast] hit terrain(%s), despawn" % body.name)
	queue_free()


## 대상별 다단히트 시퀀스. 투사체나 대상이 중간에 사라지거나 대상이 더 맞을 수 없으면 즉시 중단한다.
func _on_hurtbox_entered(hurtbox: HurtboxComponent) -> void:
	for i in max_hits_per_target:
		if not is_instance_valid(hurtbox) or hurtbox.is_queued_for_deletion():
			return

		var damage: int = _hit_damages[i]
		if not hurtbox.receive_hit(damage, attacker, travel_direction * enemy_knockback_per_hit):
			return
		print("[Windblast] HIT target=%s hit_index=%d/%d damage=%d" % [
			hurtbox.owner.name, i + 1, max_hits_per_target, damage
		])
		_notify_hit_shake()

		if i < max_hits_per_target - 1:
			await get_tree().create_timer(hit_interval).timeout


func _notify_hit_shake() -> void:
	var camera := get_tree().get_first_node_in_group("player_camera")
	if camera and camera.has_method("shake"):
		camera.shake(hit_shake_strength, hit_shake_duration)
