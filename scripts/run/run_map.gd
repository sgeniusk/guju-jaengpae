# 로그라이크 런의 막별 노드 맵을 보관하는 순수 로직.
class_name RunMap
extends RefCounted

enum NodeType { BATTLE, ELITE, REWARD, SUPPLY, BOSS }

var layers: Array = []
var layer_idx: int = 0
var active_node: Dictionary = {}

func generate(seed_value: int, normal_layers: int = 3) -> void:
	layers = []
	layer_idx = 0
	active_node = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for layer in maxi(0, normal_layers):
		var nodes: Array[Dictionary] = []
		for node_idx in 2:
			var node_type := _roll_node_type(rng)
			nodes.append({
				"type": node_type,
				"id": "L%dN%d" % [layer, node_idx],
			})
		layers.append(nodes)
	layers.append([{
		"type": NodeType.BOSS,
		"id": "L%dN0" % maxi(0, normal_layers),
	}])

func available() -> Array:
	if finished():
		return []
	return layers[layer_idx]

func choose(index: int) -> void:
	if finished():
		active_node = {}
		return
	var nodes: Array = layers[layer_idx]
	if index < 0 or index >= nodes.size():
		active_node = {}
		return
	active_node = nodes[index]

func complete() -> void:
	layer_idx += 1
	active_node = {}

func finished() -> bool:
	return layer_idx >= layers.size()

func active_type() -> int:
	if not active_node.has("type"):
		return -1
	return int(active_node["type"])

func total_layers() -> int:
	return layers.size()

static func is_battle(node_type: int) -> bool:
	return node_type == NodeType.BATTLE or node_type == NodeType.ELITE or node_type == NodeType.BOSS

static func _roll_node_type(rng: RandomNumberGenerator) -> int:
	var roll := rng.randf()
	if roll < 0.5:
		return NodeType.BATTLE
	if roll < 0.7:
		return NodeType.ELITE
	if roll < 0.9:
		return NodeType.REWARD
	return NodeType.SUPPLY
