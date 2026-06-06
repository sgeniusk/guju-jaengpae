# 전투 뷰의 유닛 walk 스프라이트 시트 분기와 정적 폴백을 검증한다.
extends TestCase

const BattleView := preload("res://scripts/battle/battle.gd")

func before_each() -> void:
	RunManager.reset_run()

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

func test_priority_general_walk_sheets_cover_three_factions() -> void:
	var cases: Array[Dictionary] = [
		{"lord": &"lord_liubei", "card_id": &"general_guanyu", "path": "res://assets/sprites/units/shu/general_guanyu.png"},
		{"lord": &"lord_caocao", "card_id": &"general_caocao", "path": "res://assets/sprites/units/wei/general_caocao.png"},
		{"lord": &"lord_sunquan", "card_id": &"general_sunquan", "path": "res://assets/sprites/units/wu/general_sunquan.png"},
	]
	for data in cases:
		RunManager.reset_run()
		RunManager.ensure_started(StringName(data["lord"]))
		var view := BattleView.new()
		var unit := _player_general(StringName(data["card_id"]))
		var texture_path := view._unit_texture_path(unit)
		eq(texture_path, String(data["path"]), "장수 정적 텍스처 경로")
		var body := view._create_unit_body(unit, load(texture_path) as Texture2D, Vector2(162.0, 172.0))
		truthy(body is AnimatedSprite2D, "%s walk 시트 사용" % String(data["card_id"]))
		if body is AnimatedSprite2D:
			eq((body as AnimatedSprite2D).sprite_frames.get_frame_count(&"walk"), 4, "장수 walk 4프레임")
		body.free()
		view.free()

func test_boss_walk_sheets_use_boss_specific_assets() -> void:
	var cases: Array[Dictionary] = [
		{"name": "마왕 동탁", "path": "res://assets/sprites/units/luoyang/boss_dongzhuo.png"},
		{"name": "천공 장각", "path": "res://assets/sprites/units/huangtian/boss_zhangjue.png"},
		{"name": "귀신 여포", "path": "res://assets/sprites/units/wanyao/boss_lvbu.png"},
	]
	for data in cases:
		var view := BattleView.new()
		var unit := _enemy_boss(String(data["name"]))
		var texture_path := view._unit_texture_path(unit)
		eq(texture_path, String(data["path"]), "보스별 정적 텍스처 경로")
		var body := view._create_unit_body(unit, load(texture_path) as Texture2D, Vector2(204.0, 244.0))
		truthy(body is AnimatedSprite2D, "%s walk 시트 사용" % String(data["name"]))
		if body is AnimatedSprite2D:
			truthy((body as AnimatedSprite2D).flip_h, "적 보스 walk 좌우반전")
			eq((body as AnimatedSprite2D).sprite_frames.get_frame_count(&"walk"), 4, "보스 walk 4프레임")
		body.free()
		view.free()

func test_generated_walk_sheets_keep_four_frame_strip_contract() -> void:
	for path in [
		"res://assets/sprites/units/shu/general_guanyu_walk.png",
		"res://assets/sprites/units/wei/general_caocao_walk.png",
		"res://assets/sprites/units/wu/general_sunquan_walk.png",
		"res://assets/sprites/units/luoyang/boss_dongzhuo_walk.png",
		"res://assets/sprites/units/huangtian/boss_zhangjue_walk.png",
		"res://assets/sprites/units/wanyao/boss_lvbu_walk.png",
	]:
		truthy(ResourceLoader.exists(path), "%s 존재" % path)
		var texture := load(path) as Texture2D
		not_null(texture, "%s 로드" % path)
		if texture != null:
			eq(int(texture.get_size().x) % 4, 0, "%s 가로 4분할 가능" % path)
			truthy(texture.get_size().y > 0.0, "%s 높이 양수" % path)

func test_unit_without_walk_sheet_keeps_static_sprite() -> void:
	var view := BattleView.new()
	var unit := BattleUnit.make(BattleUnit.Team.PLAYER, 0, 300.0, "검증", 100, 1, 1.0, "melee", 0.0, &"missing_card_probe", &"", "fantasy", -1, 300.0)
	var texture := view._placeholder_texture(140, 130, Color(0.25, 0.70, 0.55))

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

func test_ability_buttons_use_texture_icons_when_available() -> void:
	var view := BattleView.new()
	view._build_hud_theme()

	var button := view._make_ability_button("우", "검증", "res://assets/sprites/ui/ability_well.png")

	eq(button.text, "", "아이콘이 있으면 글자 fallback 제거")
	truthy(_has_texture_icon(button), "능력 버튼에 TextureRect 아이콘")
	button.free()
	view.free()

func test_battle_root_does_not_swallow_tile_mouse_input() -> void:
	var scene := load("res://scenes/battle/battle.tscn") as PackedScene
	var battle := scene.instantiate() as Control

	eq(battle.mouse_filter, Control.MOUSE_FILTER_IGNORE, "전투 루트 Control은 타일 클릭을 먹지 않음")
	battle.free()

func test_deploy_click_maps_visible_tile_to_board_key() -> void:
	RunManager.reset_run()
	RunManager.ensure_started(&"lord_liubei")
	var view := BattleView.new()
	var center := view.field_to_screen_position(BattleSim.position_for_tile(1, 0))

	eq(view._tile_key_at_screen_position(center), "1:0", "타일 중심 클릭은 해당 보드 키")
	eq(view._tile_key_at_screen_position(center + Vector2(40.0, 0.0)), "1:0", "가로 가장자리 클릭 허용")
	eq(view._tile_key_at_screen_position(center + Vector2(0.0, 30.0)), "1:0", "세로 가장자리 클릭 허용")
	eq(view._tile_key_at_screen_position(Vector2(10.0, 10.0)), "", "전장 밖 클릭은 배치 타일 아님")
	view.free()

func test_battlefield_projection_keeps_board_on_ground_plane() -> void:
	RunManager.ensure_started(&"lord_liubei")
	var view := BattleView.new()
	var ys: Array = []
	var min_y := INF
	var max_y := -INF
	for col in BattleSim.COL_COUNT:
		for row in RunManager.get_board_rows():
			var center := view.field_to_screen_position(BattleSim.position_for_tile(col, row))
			min_y = minf(min_y, center.y)
			max_y = maxf(max_y, center.y)
			if not ys.has(center.y):
				ys.append(center.y)
	truthy(min_y >= 630.0, "보드 상단은 산/하늘이 아니라 전경 지면에 위치")
	truthy(max_y <= 835.0, "보드 하단은 HUD와 겹치지 않음")
	ys.sort()
	for i in range(1, ys.size()):
		truthy(float(ys[i]) - float(ys[i - 1]) <= 104.0, "타일 세로 간격은 시각 타일 높이에 맞음")
	var center := view.field_to_screen_position(BattleSim.position_for_tile(1, 0))
	truthy(view._is_screen_position_on_tile(center + Vector2(0.0, 58.0), center), "확장된 타일 클릭 영역은 시각 다이아몬드 하단을 포함")
	falsy(view._is_screen_position_on_tile(center + Vector2(0.0, 70.0), center), "타일 밖 클릭은 여전히 거부")
	view.free()

func test_battlefield_floor_context_draws_persistent_band_and_lanes() -> void:
	RunManager.reset_run()
	RunManager.ensure_started(&"lord_liubei")
	var view := BattleView.new()
	view._bind_scene_nodes()
	view._build_field()

	truthy(_count_bool_meta(view._background_layer, &"battlefield_floor_band") >= 1, "배경 레이어에 전장 바닥 밴드")
	eq(_count_bool_meta(view._background_layer, &"battlefield_depth_lane"), BattleSim.COL_COUNT, "배경 레이어에 3레인 진군 바닥선")
	truthy(_count_bool_meta(view._iso_base_layer, &"battlefield_tile_contact") >= BattleSim.COL_COUNT * RunManager.get_board_rows(), "보드 타일마다 접지 shadow")
	eq(_count_bool_meta(view._iso_base_layer, &"battlefield_tile_outline"), BattleSim.COL_COUNT * RunManager.get_board_rows(), "보드 타일은 지면 outline으로 표시")
	truthy(_max_tile_sprite_alpha(view) <= 0.08, "타일 fill은 공중 plate처럼 보이지 않도록 낮은 alpha")
	truthy(_max_tile_outline_alpha(view) <= 0.08, "기본 타일 outline은 공중 격자처럼 보이지 않도록 낮은 alpha")
	view.free()

func test_deploy_unit_feet_share_ground_grid_and_draw_above_it() -> void:
	RunManager.reset_run()
	RunManager.ensure_started(&"lord_liubei")
	var view := BattleView.new()
	view._bind_scene_nodes()
	view._build_field()
	var tile_pos := BattleSim.position_for_tile(1, 1)
	var unit := BattleUnit.make(BattleUnit.Team.PLAYER, 1, tile_pos.x, "검증 보병", 100, 10, 1.0, "melee", 0.0, &"troop_infantry", &"", "infantry", 1, tile_pos.y)

	view._sim.add_unit(unit)
	view._spawn_visual(unit)

	var root := view._vis[unit].get("root", null) as Node2D
	not_null(root, "배치 유닛 visual root 생성")
	if root != null:
		var ground_center := view.field_to_screen_position(tile_pos)
		var foot_center := view._field_foot_screen_position(tile_pos)
		almost(root.position.y, foot_center.y, 0.001, "유닛 발밑 y는 선택 타일 앞쪽 foot 지점과 일치")
		truthy(root.position.y >= ground_center.y + 66.0, "유닛은 타일 하단보다 앞쪽 footline에 선다")
		var unit_total_z := int(view._units_layer.z_index) + root.z_index
		var field_total_z := int(view._iso_base_layer.z_index) + _max_tile_canvas_z(view)
		truthy(unit_total_z > field_total_z, "배치 유닛은 같은 지면 격자 뒤가 아니라 위에 그려짐")
	view.free()

func test_occupied_tiles_hide_field_labels_but_keep_state_tooltips() -> void:
	RunManager.reset_run()
	RunManager.ensure_started(&"lord_liubei")
	RunManager.state.castle_key = "1:1"
	RunManager.state.board = {"0:0": &"troop_infantry"}
	RunManager.state.board_levels = {"0:0": 1}
	var view := BattleView.new()
	view._bind_scene_nodes()
	view._build_field()
	view._refresh_board_tiles()

	var occupied: Dictionary = view._tile_buttons.get("0:0", {})
	var occupied_label := occupied.get("label", null) as Label
	not_null(occupied_label, "점유 타일 label 노드 존재")
	if occupied_label != null:
		falsy(occupied_label.visible, "점유 타일 field label은 유닛 앞을 덮지 않도록 숨김")
		eq(occupied_label.text, "", "점유 타일 field label 텍스트 제거")
	truthy(String(occupied.get("state_label", "")).find("보병") >= 0, "점유 타일 state label은 유지")
	truthy(String(occupied.get("tooltip", "")).find("보드 배치") >= 0, "점유 타일 tooltip은 유지")

	var castle_tile: Dictionary = view._tile_buttons.get("1:1", {})
	var castle_label := castle_tile.get("label", null) as Label
	not_null(castle_label, "성 타일 label 노드 존재")
	if castle_label != null:
		falsy(castle_label.visible, "성 field label은 성 visual 앞을 덮지 않도록 숨김")
	truthy(String(castle_tile.get("state_label", "")).find("성") >= 0, "성 타일 state label은 유지")
	view.free()

func _player_unit(troop_type: String) -> BattleUnit:
	return BattleUnit.make(BattleUnit.Team.PLAYER, 0, 300.0, "검증", 100, 1, 1.0, "melee", 0.0, &"", &"", troop_type, -1, 300.0)

func _player_general(card_id: StringName) -> BattleUnit:
	return BattleUnit.make(BattleUnit.Team.PLAYER, 0, 300.0, "검증 장수", 200, 10, 1.0, "melee", 40.0, card_id, &"skill_probe", "infantry", -1, 300.0)

func _enemy_boss(display_name: String) -> BattleUnit:
	return BattleUnit.make(BattleUnit.Team.ENEMY, 0, 900.0, display_name, 800, 20, 1.0, "melee", 25.0, &"", &"skill_boss_probe", "infantry", -1, 300.0)

func _has_texture_icon(node: Node) -> bool:
	if node is TextureRect and (node as TextureRect).texture != null:
		return true
	for child in node.get_children():
		if _has_texture_icon(child):
			return true
	return false

func _count_bool_meta(node: Node, key: StringName) -> int:
	if node == null:
		return 0
	var count := 1 if bool(node.get_meta(key, false)) else 0
	for child in node.get_children():
		count += _count_bool_meta(child, key)
	return count

func _max_tile_sprite_alpha(view: Node) -> float:
	var max_alpha := 0.0
	for value in view._tile_buttons.values():
		if not (value is Dictionary):
			continue
		var sprite := (value as Dictionary).get("sprite", null) as Sprite2D
		if sprite != null:
			max_alpha = maxf(max_alpha, sprite.modulate.a)
		var poly := (value as Dictionary).get("poly", null) as Polygon2D
		if poly != null:
			max_alpha = maxf(max_alpha, poly.color.a)
	return max_alpha

func _max_tile_outline_alpha(view: Node) -> float:
	var max_alpha := 0.0
	for value in view._tile_buttons.values():
		if not (value is Dictionary):
			continue
		var outline := (value as Dictionary).get("outline", null) as Line2D
		if outline != null:
			max_alpha = maxf(max_alpha, outline.default_color.a)
	return max_alpha

func _max_tile_canvas_z(view: Node) -> int:
	var max_z := -4096
	for value in view._tile_buttons.values():
		if not (value is Dictionary):
			continue
		var tile := value as Dictionary
		for key in ["sprite", "poly", "outline", "label"]:
			var item := tile.get(key, null) as CanvasItem
			if item != null:
				max_z = maxi(max_z, item.z_index)
	return max_z
