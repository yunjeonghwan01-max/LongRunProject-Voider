class_name RangedAttackProjectile
extends CounterableAttack

## 원거리 counterable attack.
## 발동 시점에 방향(내적) + 시야(raycast)를 검사해 counter 후보로 삼을지 결정한다.
## 후보가 되면 counter window를 열고(flash 포함) 창이 닫힐 때까지 제자리에서 대기한 뒤,
## 카운터되지 않았다면 그때부터 플레이어를 향해 날아간다.
##
## 명중은 Hitbox(HitboxComponent → 플레이어 Hurtbox)로 판정하고, Collision은 지형에 닿으면 소멸시킨다.
## 둘 다 비행 중에만 켠다 (카운터 대기 중 근처의 플레이어가 맞지 않도록). 데미지는 Hitbox의 damage.
## Collision은 layer 0 + monitorable 유지 (monitorable을 끄면 TileMap 바디를 감지하지 못한다).

@export var speed: float = 350.0
@export var max_lifetime: float = 4.0
@export var direction_dot_threshold: float = 0.4
@export_flags_2d_physics var los_collision_mask: int = CollisionLayers.WORLD  # 시야는 지형만 가린다

@export_group("Pre-Signal")
@export var pre_signal_duration: float = 0.35
@export var pre_signal_dark_color: Color = Color(0.35, 0.35, 0.35, 1)

var facing_direction: Vector2 = Vector2.LEFT
var target_player: Node2D = null

var _has_valid_counter_opportunity: bool = false
var _travel_direction: Vector2 = Vector2.ZERO
var _is_flying: bool = false
var _lifetime_elapsed: float = 0.0

@onready var _visual: Node2D = $Visual
@onready var _hitbox: HitboxComponent = $Hitbox
@onready var _collision: Area2D = $Collision

var _glow_tween: Tween = null
var _pre_signal_tween: Tween = null


func _ready() -> void:
	attack_type = "ranged_shot"
	counterable = true
	set_physics_process(false)

	_hitbox.source = attacker
	_hitbox.hit_landed.connect(_on_hitbox_hit_landed)
	_collision.body_entered.connect(_on_terrain_entered)

	_travel_direction = facing_direction.normalized()
	_has_valid_counter_opportunity = _check_direction_valid() and _check_line_of_sight_valid()

	print("[Attack] counterable attack START type=%s attacker=%s valid_candidate=%s" % [
		attack_type, attacker, _has_valid_counter_opportunity
	])

	if _has_valid_counter_opportunity:
		_start_pre_signal()
	else:
		_begin_flight()


func _check_direction_valid() -> bool:
	if target_player == null:
		return false
	var to_player := (target_player.global_position - global_position).normalized()
	return _travel_direction.dot(to_player) >= direction_dot_threshold


func _check_line_of_sight_valid() -> bool:
	if target_player == null:
		return false
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, target_player.global_position)
	query.collision_mask = los_collision_mask
	var result := space_state.intersect_ray(query)
	return result.is_empty()


## counter window가 열리기 전, 어두운 기본 상태에서 서서히 밝아지며 다가올 타이밍을 예고한다.
func _start_pre_signal() -> void:
	if not _visual:
		_open_counter_window()
		return

	_visual.modulate = pre_signal_dark_color

	_pre_signal_tween = create_tween()
	_pre_signal_tween.tween_property(_visual, "modulate", Color(1, 1, 1, 1), pre_signal_duration).set_trans(Tween.TRANS_SINE)
	_pre_signal_tween.finished.connect(_open_counter_window)


func _open_counter_window() -> void:
	counter_window_open = true
	_start_window_glow()
	print("[Counter] window OPEN type=%s attacker=%s" % [attack_type, attacker])

	if target_player and target_player.has_method("set_counter_target"):
		target_player.set_counter_target(self)

	await get_tree().create_timer(counter_window_duration).timeout
	_close_counter_window()


func _close_counter_window() -> void:
	if not counter_window_open:
		# 이미 카운터 성공으로 닫혔거나 공격이 무효화됨.
		return

	counter_window_open = false
	_stop_window_glow()
	print("[Counter] window CLOSE type=%s was_countered=%s" % [attack_type, was_countered])

	if target_player and target_player.has_method("clear_counter_target"):
		target_player.clear_counter_target(self)

	if is_valid and not was_countered:
		_begin_flight()


func _begin_flight() -> void:
	_is_flying = true
	set_physics_process(true)
	_hitbox.set_deferred("monitoring", true)
	_collision.set_deferred("monitoring", true)


func _physics_process(delta: float) -> void:
	if not is_valid:
		return

	_lifetime_elapsed += delta
	global_position += _travel_direction * speed * delta

	if _lifetime_elapsed >= max_lifetime:
		queue_free()


func _on_hitbox_hit_landed(_hurtbox: HurtboxComponent) -> void:
	print("[Attack] HIT player (not countered) type=%s attacker=%s" % [attack_type, attacker])
	_despawn()


func _on_terrain_entered(body: Node) -> void:
	print("[Attack] hit terrain(%s), despawn type=%s" % [body.name, attack_type])
	_despawn()


func _despawn() -> void:
	is_valid = false
	_hitbox.set_deferred("monitoring", false)
	queue_free()


## counter window가 열려 있는 동안 강렬하게 빛나며(overbright modulate) 반복 확대/축소되는
## 임시 이펙트. 타이밍을 놓치기 어려울 정도로 눈에 띄게 만드는 것이 목적이며,
## window가 닫히는 즉시 _stop_window_glow()로 정지/원상복구된다.
func _start_window_glow() -> void:
	if not _visual:
		return
	_visual.modulate = Color(1, 1, 1, 1)
	_visual.scale = Vector2.ONE

	_glow_tween = create_tween()
	_glow_tween.set_loops()
	_glow_tween.tween_property(_visual, "modulate", Color(3.0, 2.6, 0.4, 1), 0.09).set_trans(Tween.TRANS_SINE)
	_glow_tween.parallel().tween_property(_visual, "scale", Vector2(1.7, 1.7), 0.09).set_trans(Tween.TRANS_SINE)
	_glow_tween.tween_property(_visual, "modulate", Color(1, 0.2, 0.2, 1), 0.09).set_trans(Tween.TRANS_SINE)
	_glow_tween.parallel().tween_property(_visual, "scale", Vector2(1.0, 1.0), 0.09).set_trans(Tween.TRANS_SINE)


func _stop_window_glow() -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	_glow_tween = null
	if _visual:
		_visual.modulate = Color(1, 1, 1, 1)
		_visual.scale = Vector2.ONE


func _on_countered() -> void:
	print("[Attack] neutralized by counter, type=%s" % attack_type)
	_stop_window_glow()
	set_physics_process(false)
	queue_free()
