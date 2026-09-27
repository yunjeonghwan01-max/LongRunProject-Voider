class_name LevelContainers

## Level 씬의 런타임 스폰 컨테이너(Projectiles / Effects)를 찾는 최소 헬퍼.
## 이 역할만 담당한다. Level 로딩/전환 같은 범용 Level API로 확장하지 않는다.
##
## Level은 컨테이너 노드를 아래 그룹에 넣어 표시한다 (예: levels/combat_test/combat_test.tscn).
## 컨테이너가 없으면(예: Actor 씬 단독 F6 실행) 기존 방식대로 호출자의 부모를 fallback으로 쓰고,
## 구조 오류가 조용히 숨지 않도록 디버그 실행에서 그룹별로 한 번 경고를 남긴다.

const PROJECTILES_GROUP := &"level_projectiles"
const EFFECTS_GROUP := &"level_effects"

static var _warned_groups: Dictionary = {}


static func projectiles(from: Node) -> Node:
	return _find(from, PROJECTILES_GROUP, "Projectiles")


static func effects(from: Node) -> Node:
	return _find(from, EFFECTS_GROUP, "Effects")


static func _find(from: Node, group: StringName, label: String) -> Node:
	var container := from.get_tree().get_first_node_in_group(group)
	if container:
		return container

	if OS.is_debug_build() and not _warned_groups.has(group):
		_warned_groups[group] = true
		push_warning("%s container not found; using fallback parent." % label)
	return from.get_parent()
