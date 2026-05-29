# 한 런을 시작하는 군주(君主)의 데이터 — 시작 덱과 특성을 정의
@tool
class_name LordData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export_enum("mortal", "heaven", "demon") var realm: String = "mortal"
@export var nation: StringName = &"shu"
@export var trait_id: StringName = &""    # 전투에서 적용되는 특성 식별자 (예: trait_rende)
@export var trait_name: String = ""
@export_multiline var trait_text: String = ""
@export var starting_general_ids: PackedStringArray = PackedStringArray()
@export var starting_troop_ids: PackedStringArray = PackedStringArray()
