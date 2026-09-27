class_name Windblast
extends Area2D

## Hollow Knight의 Vengeful Spirit과 유사한 전방 직선 관통 투사체.
## 여러 적을 관통하며, 적 하나당 최대 max_hits_per_target회까지 hit_interval 간격으로
## 다단히트를 적용한다. 다단히트는 물리적으로 계속 겹쳐 있는지와 무관하게, 최초 접촉
## 시점부터 독립적인 타이머로 진행되어 max_hits_per_target을 절대 넘지 않는다.

@export var speed: float = 900.0
@export var max_lifetime: float = 2.0

@export_group("Multi Hit")
@export var max_hits_per_target: int = 3
@export var hit_interval: float = 0.1
@export var total_damage: int = 2  ## 플레이어 기본 공격 총 데미지(1)의 약 2배

@export_group("Knockback")
@export var enemy_knockback_per_hit: float = 14.0

@export_group("Screen Shake")
@export var hit_shake_strength: float = 2.5
@export var hit_shake_duration: float = 0.1

var attacker: Node = null
var travel_direction: Vector2 = Vector2.RIGHT

var _hit_damages: Array[int] = []
var _hit_targets: Dictionary = {}  # target -> true (진행 중이거나 이미 완료된 대상)
var _lifetime_elapsed: float = 0.0

@onready var _visual: Node2D = $visual


func _ready() -> void:
	_compute_hit_damages()

	if travel_direction.x != 0.0:
		_visual.scale.x = sign(travel_direction.x)

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

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
## 예: total=2, max_hits=3 -> [1, 1, 0]
func _compute_hit_damages() -> void:
	_hit_damages.clear()
	var base := total_damage / max_hits_per_target
	var remainder := total_damage % max_hits_per_target
	for i in max_hits_per_target:
		_hit_damages.append(base + (1 if i < remainder else 0))


func _on_area_entered(area: Area2D) -> void:
	_try_register_hit(area.get_parent())


func _on_body_entered(body: Node) -> void:
	# mask가 WORLD만 포함하므로 여기로 들어오는 바디는 지형뿐이다. 벽/지형 충돌 시 자연스럽게 소멸.
	print("[Windblast] hit terrain(%s), despawn" % body.name)
	queue_free()


func _try_register_hit(target: Node) -> void:
	if target == null or not target.has_method("take_damage"):
		return
	if _hit_targets.has(target):
		return

	_hit_targets[target] = true
	_run_hit_sequence(target)


## 대상별 다단히트 시퀀스. 투사체나 대상이 중간에 사라지면 즉시 중단한다.
func _run_hit_sequence(target: Node) -> void:
	for i in max_hits_per_target:
		if not is_instance_valid(target) or target.is_queued_for_deletion():
			return

		var damage: int = _hit_damages[i]
		target.take_damage(damage, attacker, travel_direction * enemy_knockback_per_hit)
		print("[Windblast] HIT target=%s hit_index=%d/%d damage=%d" % [
			target.name, i + 1, max_hits_per_target, damage
		])
		_notify_hit_shake()

		if i < max_hits_per_target - 1:
			await get_tree().create_timer(hit_interval).timeout


func _notify_hit_shake() -> void:
	var camera := get_tree().get_first_node_in_group("player_camera")
	if camera and camera.has_method("shake"):
		camera.shake(hit_shake_strength, hit_shake_duration)
