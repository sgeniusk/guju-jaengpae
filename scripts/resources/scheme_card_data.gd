# 발동 후 소비되는 계략 카드 데이터.
@tool
class_name SchemeCardData
extends CardData

@export var effect_id: StringName = &""
@export_enum("none", "enemy", "ally", "board_slot") var target_policy: String = "none"
@export var value: int = 0
@export var secondary_value: int = 0
@export var duration_sec: float = 0.0

func _init() -> void:
	card_type = "scheme"
