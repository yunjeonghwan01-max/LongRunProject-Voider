extends Node2D

## 카운터 시스템 검증용 최소 테스트 적.
## 이동/체력/AI 없이, 일정 주기로 원거리 counterable attack만 발동한다.

const RANGED_ATTACK_SCENE := preload("res://systems/combat/ranged_attack.tscn")

@export var attack_interval: float = 2.5
@export var facing_direction: Vector2 = Vector2.LEFT
@export var max_health: int = 3

var health: int

@onready var _attack_timer: Timer = $attack_timer


func _ready() -> void:
	health = max_health
	_attack_timer.wait_time = attack_interval
	_attack_timer.timeout.connect(_on_attack_timer_timeout)
	_attack_timer.start()


## 플레이어 근접 공격 HitBox가 hurtbox에 닿았을 때 호출된다.
## 별도의 체력 시스템이 없으므로 최소한의 health 감소 + 로그만 처리한다.
func take_damage(amount: int, _source: Node) -> void:
	health -= amount
	print("[Enemy] %s took %d damage (health=%d/%d)" % [name, amount, health, max_health])

	if health <= 0:
		print("[Enemy] %s defeated" % name)
		queue_free()


func _on_attack_timer_timeout() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	_spawn_ranged_attack(player)


func _spawn_ranged_attack(player: Node2D) -> void:
	var attack: RangedAttack = RANGED_ATTACK_SCENE.instantiate()
	attack.attacker = self
	attack.facing_direction = facing_direction
	attack.target_player = player
	attack.global_position = global_position
	get_parent().add_child(attack)
