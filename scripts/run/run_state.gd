# 한 런의 변경 가능한 상태 — 군주, 현재 덱(시작 덱 + 전리 보상), 파도 진행도, 노드 맵. 순수 로직(헤드리스 테스트 가능).
class_name RunState
extends RefCounted

var lord_id: StringName = &""
var deck: Array[StringName] = []
var wave_index: int = 0
var started: bool = false
var map := RunMap.new()
var command_points: int = 12

func start_run(lord: LordData, catalog: CardCatalog) -> void:
	lord_id = lord.id if lord != null else &""
	deck = catalog.get_lord_deck(lord)
	wave_index = 0
	command_points = 12
	started = true

func has_card(id: StringName) -> bool:
	return deck.has(id)

func add_card(id: StringName) -> void:
	deck.append(id)

func add_command_points(n: int) -> void:
	command_points += n
