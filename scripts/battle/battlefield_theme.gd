# 전장 배경 테마 슬롯을 등록하고 선택한다.
extends RefCounted
class_name BattlefieldTheme

const DEFAULT_ID := "plain"
const DEFAULT_TILE_PATH := "res://assets/sprites/iso/tile_grass.png"

const THEMES := {
	"plain": {
		"id": "plain",
		"label": "평원",
		"realm": "mortal",
		"background_texture_path": "res://assets/sprites/bg/plain/field.png",
		"tile_texture_path": DEFAULT_TILE_PATH,
		"ambient": Color(1.0, 0.96, 0.86, 1.0),
	},
	"forest": {
		"id": "forest",
		"label": "숲길",
		"realm": "mortal",
		"background_texture_path": "res://assets/sprites/bg/forest/field.png",
		"tile_texture_path": DEFAULT_TILE_PATH,
		"ambient": Color(0.92, 1.0, 0.84, 1.0),
	},
	"river": {
		"id": "river",
		"label": "강안",
		"realm": "mortal",
		"background_texture_path": "res://assets/sprites/bg/river/field.png",
		"tile_texture_path": DEFAULT_TILE_PATH,
		"ambient": Color(0.88, 0.96, 1.0, 1.0),
	},
	"heaven": {
		"id": "heaven",
		"label": "천계",
		"realm": "heaven",
		"background_texture_path": "res://assets/sprites/bg/heaven/field.png",
		"tile_texture_path": DEFAULT_TILE_PATH,
		"ambient": Color(0.88, 0.94, 1.0, 1.0),
	},
	"demon": {
		"id": "demon",
		"label": "마계",
		"realm": "demon",
		"background_texture_path": "res://assets/sprites/bg/demon/field.png",
		"tile_texture_path": "res://assets/sprites/iso/tile_cave.png",
		"ambient": Color(1.0, 0.78, 0.82, 1.0),
	},
	"luoyang": {
		"id": "luoyang",
		"label": "낙양마궁",
		"realm": "demon",
		"background_texture_path": "res://assets/sprites/bg/luoyang/field.png",
		"tile_texture_path": "res://assets/sprites/iso/tile_magma.png",
		"ambient": Color(1.0, 0.72, 0.62, 1.0),
	},
	"plague": {
		"id": "plague",
		"label": "황천 역병진",
		"realm": "demon",
		"background_texture_path": "res://assets/sprites/bg/plague/field.png",
		"tile_texture_path": "res://assets/sprites/iso/tile_cave.png",
		"ambient": Color(0.9, 0.98, 0.72, 1.0),
	},
	"wanyao": {
		"id": "wanyao",
		"label": "만요동천",
		"realm": "demon",
		"background_texture_path": "res://assets/sprites/bg/wanyao/field.png",
		"tile_texture_path": "res://assets/sprites/iso/tile_magma.png",
		"ambient": Color(0.98, 0.72, 1.0, 1.0),
	},
}

const REALM_THEME_IDS := {
	"mortal": "plain",
	"heaven": "heaven",
	"demon": "demon",
}

const BOSS_STAGE_THEME_IDS := {
	5: "luoyang",
	10: "plague",
	15: "wanyao",
}

static func default_theme() -> Dictionary:
	return theme_for_id(DEFAULT_ID)

static func theme_for_mode(mode_key: String = "") -> Dictionary:
	var normalized := mode_key.strip_edges()
	if normalized.is_empty():
		return default_theme()
	if THEMES.has(normalized):
		return theme_for_id(normalized)
	if REALM_THEME_IDS.has(normalized):
		return theme_for_realm(normalized)
	if normalized.begins_with("realm_"):
		return theme_for_realm(normalized.substr(6))
	return default_theme()

static func theme_for_realm(realm: String = "mortal") -> Dictionary:
	var theme_id := String(REALM_THEME_IDS.get(realm, DEFAULT_ID))
	return theme_for_id(theme_id)

static func theme_for_stage(stage: int, player_realm: String = "mortal") -> Dictionary:
	var current_stage := maxi(1, stage)
	if BOSS_STAGE_THEME_IDS.has(current_stage):
		return theme_for_id(String(BOSS_STAGE_THEME_IDS[current_stage]))
	if current_stage > 15 and current_stage % 5 == 0:
		return theme_for_id("wanyao")
	if current_stage >= 11:
		return theme_for_id("wanyao")
	if current_stage >= 6:
		return theme_for_id("demon")
	return theme_for_realm(player_realm)

static func theme_for_id(id: String) -> Dictionary:
	var theme: Dictionary = THEMES.get(id, THEMES[DEFAULT_ID])
	return theme.duplicate(true)

static func theme_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in THEMES.keys():
		ids.append(String(id))
	ids.sort()
	return ids

static func background_path(theme: Dictionary) -> String:
	return String(theme.get("background_texture_path", ""))

static func tile_path(theme: Dictionary) -> String:
	return String(theme.get("tile_texture_path", DEFAULT_TILE_PATH))
