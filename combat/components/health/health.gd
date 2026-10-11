class_name HealthComponent
extends Node

## 체력. HP 증감과 damaged / died 통지만 담당한다.
## 피격 반응(플래시, 넉백, 사망 처리)은 Actor가 시그널을 받아 처리한다.

signal damaged(amount: int)
signal died

@export var max_hp: int = 100

var hp: int


func _ready() -> void:
	hp = max_hp


func is_dead() -> bool:
	return hp <= 0


## HP가 실제로 줄었으면 true. 0 이하 데미지이거나 이미 죽은 상태면 false.
func take_damage(amount: int) -> bool:
	if amount <= 0 or hp <= 0:
		return false

	hp = max(hp - amount, 0)
	damaged.emit(amount)

	print("[Health] %s HP: %d/%d" % [owner.name, hp, max_hp])

	if hp == 0:
		died.emit()

	return true
