# 보드 타일에 남아 경제·오라 효과를 제공하는 건물 카드 데이터.
@tool
class_name BuildingCardData
extends CardData

@export var gold_per_sec: int = 0
@export var aura_attack_pct: float = 0.0
@export var aura_radius: int = 1

func _init() -> void:
	card_type = "building"
