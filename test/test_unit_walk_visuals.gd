# 전투 뷰의 유닛 walk 스프라이트 시트 분기와 정적 폴백을 검증한다.
extends TestCase

const BattleView := preload("res://scripts/battle/battle.gd")

func test_shu_infantry_walk_sheet_builds_animated_sprite_frames() -> void:
	var view := BattleView.new()
	var unit := _player_unit("infantry")
	var texture := load("res://assets/sprites/units/shu/infantry.png") as Texture2D

	var body := view._create_unit_body(unit, texture, Vector2(140.0, 130.0))

	truthy(body is AnimatedSprite2D, "walk 시트가 있으면 AnimatedSprite2D 생성")
	var animated := body as AnimatedSprite2D
	eq(animated.animation, &"walk", "walk 애니메이션 선택")
	eq(animated.sprite_frames.get_frame_count(&"walk"), 4, "walk 4프레임")
	almost(animated.sprite_frames.get_animation_speed(&"walk"), 8.0, 0.001, "walk fps")
	truthy(animated.sprite_frames.get_animation_loop(&"walk"), "walk loop")
	for i in range(4):
		var frame := animated.sprite_frames.get_frame_texture(&"walk", i) as AtlasTexture
		not_null(frame, "프레임 AtlasTexture")
		eq(frame.region, Rect2(256.0 * float(i), 0.0, 256.0, 512.0), "프레임 region")
	falsy(animated.flip_h, "아군은 좌우반전 없음")
	eq(animated.position, Vector2(0.0, -65.0), "발밑 앵커")
	body.free()
	view.free()

func test_unit_without_walk_sheet_keeps_static_sprite() -> void:
	var view := BattleView.new()
	var unit := _player_unit("archer")
	var texture := load("res://assets/sprites/units/shu/archer.png") as Texture2D

	var body := view._create_unit_body(unit, texture, Vector2(140.0, 130.0))

	truthy(body is Sprite2D, "walk 시트가 없으면 Sprite2D 유지")
	var sprite := body as Sprite2D
	eq(sprite.texture, texture, "정적 텍스처 유지")
	falsy(sprite.flip_h, "아군 정적 스프라이트 좌우반전 없음")
	eq(sprite.position, Vector2(0.0, -65.0), "정적 폴백도 같은 발밑 앵커")
	body.free()
	view.free()

func test_enemy_static_sprite_keeps_flip_h() -> void:
	var view := BattleView.new()
	var unit := BattleUnit.make(BattleUnit.Team.ENEMY, 0, 900.0, "사령병", 100, 1, 1.0, "melee", 0.0, &"", &"", "infantry", -1, 300.0)
	var texture := load("res://assets/sprites/units/demon/infantry.png") as Texture2D

	var body := view._create_unit_body(unit, texture, Vector2(140.0, 130.0))

	truthy(body is Sprite2D, "시트 없는 적은 Sprite2D 유지")
	truthy((body as Sprite2D).flip_h, "적 정적 스프라이트 좌우반전")
	body.free()
	view.free()

func _player_unit(troop_type: String) -> BattleUnit:
	return BattleUnit.make(BattleUnit.Team.PLAYER, 0, 300.0, "검증", 100, 1, 1.0, "melee", 0.0, &"", &"", troop_type, -1, 300.0)
