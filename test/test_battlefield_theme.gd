# 전장 배경 테마 등록과 기본 선택을 검증한다.
extends TestCase

const _BattlefieldTheme := preload("res://scripts/battle/battlefield_theme.gd")

func test_default_theme_points_to_plain_field_background() -> void:
	var theme := _BattlefieldTheme.default_theme()
	eq(theme["id"], "plain", "기본 테마 id")
	eq(_BattlefieldTheme.background_path(theme), "res://assets/sprites/bg/plain/field.png", "평원 배경 경로")
	truthy(ResourceLoader.exists(_BattlefieldTheme.background_path(theme)), "평원 배경 텍스처 존재")

func test_mode_lookup_falls_back_to_plain_theme() -> void:
	eq(_BattlefieldTheme.theme_for_mode("plain")["id"], "plain", "plain 모드 선택")
	eq(_BattlefieldTheme.theme_for_mode("unknown")["id"], "plain", "미등록 모드는 plain 폴백")

