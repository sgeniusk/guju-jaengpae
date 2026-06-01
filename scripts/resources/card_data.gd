# 모든 카드(장수·병종·계략·보패)의 공통 데이터 베이스 Resource
@tool
class_name CardData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export_enum("mortal", "heaven", "demon") var realm: String = "mortal"
@export var nation: StringName = &"shu"
@export_enum("general", "troop", "scheme", "treasure", "building") var card_type: String = "troop"
@export var cost: int = 1
@export_enum("historical", "romance", "mythic") var fantasy_tier: String = "romance"
@export_multiline var description: String = ""
