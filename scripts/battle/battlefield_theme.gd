# 전장 배경 테마 슬롯을 등록하고 선택한다.
extends RefCounted
class_name BattlefieldTheme

const DEFAULT_ID := "plain"

const THEMES := {
	"plain": {
		"id": "plain",
		"background_texture_path": "res://assets/sprites/bg/plain/field.png",
		"ambient": Color(1.0, 0.96, 0.86, 1.0),
	},
}

static func default_theme() -> Dictionary:
	return theme_for_id(DEFAULT_ID)

static func theme_for_mode(mode_key: String = "") -> Dictionary:
	if mode_key.is_empty() or not THEMES.has(mode_key):
		return default_theme()
	return theme_for_id(mode_key)

static func theme_for_id(id: String) -> Dictionary:
	var theme: Dictionary = THEMES.get(id, THEMES[DEFAULT_ID])
	return theme.duplicate(true)

static func background_path(theme: Dictionary) -> String:
	return String(theme.get("background_texture_path", ""))

