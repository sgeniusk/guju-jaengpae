# 카드 카탈로그 싱글톤. 게임 실행 시 모든 카드·군주를 로드해 id 조회를 제공한다. 순수 로직은 CardCatalog에 위임.
extends Node

var catalog := CardCatalog.new()

func _ready() -> void:
	catalog.load_all()

func get_card(id: StringName) -> CardData:
	return catalog.get_card(id)

func get_lord(id: StringName) -> LordData:
	return catalog.get_lord(id)

func lord_ids() -> Array[StringName]:
	return catalog.lord_ids()

func lord_list() -> Array[LordData]:
	return catalog.lord_list()

func get_lord_deck(lord: LordData) -> Array[StringName]:
	return catalog.get_lord_deck(lord)

func build_player_unit(card_id: StringName, lane: int, x: float, lord: LordData, edicts: Array = []) -> BattleUnit:
	return catalog.build_player_unit(card_id, lane, x, lord, edicts)
