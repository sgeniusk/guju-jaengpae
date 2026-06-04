# 전장 배경 테마 등록과 기본 선택을 검증한다.
extends TestCase

const _BattlefieldTheme := preload("res://scripts/battle/battlefield_theme.gd")

func test_default_theme_points_to_plain_field_background() -> void:
	var theme := _BattlefieldTheme.default_theme()
	eq(theme["id"], "plain", "기본 테마 id")
	eq(_BattlefieldTheme.background_path(theme), "res://assets/sprites/bg/plain/field.png", "평원 배경 경로")
	eq(_BattlefieldTheme.tile_path(theme), "res://assets/sprites/iso/tile_grass.png", "평원 타일 경로")
	truthy(ResourceLoader.exists(_BattlefieldTheme.background_path(theme)), "평원 배경 텍스처 존재")
	truthy(ResourceLoader.exists(_BattlefieldTheme.tile_path(theme)), "평원 타일 텍스처 존재")

func test_mode_lookup_falls_back_to_plain_theme() -> void:
	eq(_BattlefieldTheme.theme_for_mode("plain")["id"], "plain", "plain 모드 선택")
	eq(_BattlefieldTheme.theme_for_mode("realm_mortal")["id"], "plain", "realm_mortal 모드 선택")
	eq(_BattlefieldTheme.theme_for_mode("realm_heaven")["id"], "heaven", "realm_heaven 모드 선택")
	eq(_BattlefieldTheme.theme_for_mode("demon")["id"], "demon", "demon 모드 선택")
	eq(_BattlefieldTheme.theme_for_mode("unknown")["id"], "plain", "미등록 모드는 plain 폴백")

func test_realm_theme_lookup_has_backgrounds() -> void:
	eq(_BattlefieldTheme.theme_for_realm("mortal")["id"], "plain", "현세는 평원 테마")
	eq(_BattlefieldTheme.theme_for_realm("heaven")["id"], "heaven", "천계 테마")
	eq(_BattlefieldTheme.theme_for_realm("demon")["id"], "demon", "마계 테마")
	eq(_BattlefieldTheme.theme_for_realm("unknown")["id"], "plain", "미등록 realm 폴백")
	for id in _BattlefieldTheme.theme_ids():
		var theme := _BattlefieldTheme.theme_for_id(id)
		truthy(ResourceLoader.exists(_BattlefieldTheme.background_path(theme)), "%s 배경 텍스처 존재" % id)
		truthy(ResourceLoader.exists(_BattlefieldTheme.tile_path(theme)), "%s 타일 텍스처 존재" % id)

func test_stage_theme_lookup_uses_boss_and_realm_context() -> void:
	eq(_BattlefieldTheme.theme_for_stage(1, "mortal")["id"], "plain", "stage 1 현세 평원")
	eq(_BattlefieldTheme.theme_for_stage(1, "heaven")["id"], "heaven", "stage 1 천계 realm")
	eq(_BattlefieldTheme.theme_for_stage(5, "mortal")["id"], "luoyang", "stage 5 동탁 배경")
	eq(_BattlefieldTheme.theme_for_stage(6, "mortal")["id"], "demon", "stage 6 마계 act 배경")
	eq(_BattlefieldTheme.theme_for_stage(10, "mortal")["id"], "plague", "stage 10 장각 배경")
	eq(_BattlefieldTheme.theme_for_stage(15, "mortal")["id"], "wanyao", "stage 15 여포 배경")
	eq(_BattlefieldTheme.theme_for_stage(20, "mortal")["id"], "wanyao", "후반 보스는 만요동천 폴백")
