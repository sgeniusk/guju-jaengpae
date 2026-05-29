# 전장에 배치되어 자동 교전하는 유닛 카드(장수·병종)의 데이터
@tool
class_name UnitCardData
extends CardData

@export_enum("infantry", "archer", "cavalry", "crossbow", "navy", "fantasy") var troop_type: String = "infantry"
@export var max_hp: int = 100
@export var attack: int = 10
@export var attack_interval: float = 1.0   # 공격 간격(초)
@export_enum("melee", "ranged") var attack_range: String = "melee"
@export var move_speed: float = 40.0       # 레인 이동 속도(px/s)
@export var skill_id: StringName = &""     # 장수면 고유 스킬 id, 일반 병종이면 비움
@export_multiline var skill_text: String = ""
