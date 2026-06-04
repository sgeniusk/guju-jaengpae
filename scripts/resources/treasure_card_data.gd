# 런 동안 지속되는 보패 카드 데이터.
@tool
class_name TreasureCardData
extends CardData

@export var effect_id: StringName = &""
@export var value: int = 0
@export var secondary_value: int = 0
@export var stack_limit: int = 1

func _init() -> void:
	card_type = "treasure"
