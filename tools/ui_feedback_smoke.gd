# 핵심 UI 피드백 스모크 — 주요 화면의 tooltip_text와 배치 피드백 문구를 헤드리스 씬으로 검증한다.
# 실행 — godot --headless --path . --script res://tools/ui_feedback_smoke.gd
extends SceneTree

const LORD_ID := &"lord_liubei"
const LORD_SELECT_SCENE_PATH := "res://scenes/screens/lord_select.tscn"
const RUN_MAP_SCENE_PATH := "res://scenes/screens/run_map.tscn"
const BATTLE_SCENE_PATH := "res://scenes/battle/battle.tscn"
const BATTLE_PHASE_BATTLE := 1
const _BattleFeel := preload("res://scripts/battle/battle_feel.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors := 0
	errors += await _lord_select_case()
	errors += await _run_map_first_combat_case()
	errors += await _run_map_shop_case()
	errors += await _run_map_shop_low_gold_case()
	errors += await _run_map_edict_case()
	errors += await _run_map_event_case()
	errors += await _battle_deploy_case()
	errors += await _battle_manual_first_play_case()
	errors += await _battle_formation_preview_case()
	errors += await _battle_command_feedback_case()
	errors += await _battle_reward_case()
	if errors == 0:
		print("✅ UI 툴팁/피드백 스모크 통과")
		quit(0)
	else:
		printerr("❌ UI 툴팁/피드백 스모크 실패: %d건" % errors)
		quit(1)

func _lord_select_case() -> int:
	var run_manager := root.get_node_or_null("/root/RunManager")
	if run_manager == null:
		return _fail("RunManager autoload 조회 실패")
	run_manager.reset_run()
	run_manager.reset_profile()
	var screen = _instantiate_scene(LORD_SELECT_SCENE_PATH)
	if screen == null:
		return _fail("lord_select.tscn 인스턴스 생성 실패")
	root.add_child(screen)
	await _frames(8)
	var errors := 0
	errors += _assert_any_tooltip(screen, "선택하면 새 런", "군주 선택 버튼 tooltip")
	errors += _assert_any_tooltip(screen, "잠김. 보스 승리", "잠긴 군주 tooltip")
	screen.queue_free()
	await _frames(2)
	if errors == 0:
		print("  군주 선택 tooltip OK")
	return errors

func _run_map_first_combat_case() -> int:
	if _prepare_run_map_stage(1) == null:
		return _fail("RunManager autoload 조회 실패")
	var screen = _instantiate_scene(RUN_MAP_SCENE_PATH)
	if screen == null:
		return _fail("run_map.tscn 첫 전투 인스턴스 생성 실패")
	root.add_child(screen)
	await _frames(8)
	var errors := 0
	errors += _assert_any_text(screen, "첫 전투입니다", "첫 전투 안내 문구")
	errors += _assert_any_text(screen, "진행 리듬 — 현재 1 전투", "첫 전투 진행 리듬")
	errors += _assert_any_text(screen, "다음 흐름: 2 전투 -> 3 칙령 -> 4 상점", "첫 전투 다음 흐름")
	errors += _assert_any_text(screen, "빈 타일에 배치", "첫 배치 행동 안내")
	errors += _assert_any_text(screen, "전투 준비 — 손패 3장 중 1장", "첫 전투 준비 요약")
	errors += _assert_any_text(screen, "성 위치: 미선택", "첫 전투 성 위치 요약")
	errors += _assert_any_text(screen, "증원 후보", "첫 전투 손패 후보 요약")
	errors += _assert_any_tooltip(screen, "런맵에서 전투 시작", "첫 전투 진행 리듬 tooltip")
	errors += _assert_any_tooltip(screen, "성 위치는 아직", "첫 전투 준비 tooltip")
	errors += _assert_button_tooltip(screen, "전투 시작", "손패 1장", "첫 전투 시작 버튼 tooltip")
	screen.queue_free()
	await _frames(2)
	if errors == 0:
		print("  런맵 첫 전투 안내 OK")
	return errors

func _run_map_shop_case() -> int:
	var run_manager = _prepare_run_map_stage(4)
	if run_manager == null:
		return _fail("RunManager autoload 조회 실패")
	run_manager.state.gold = 999
	run_manager.state.hand.append(&"scheme_raid")
	run_manager.state.hand.append(&"building_dunjeon")
	run_manager.state.board["0:0"] = &"troop_infantry"
	var screen = _instantiate_scene(RUN_MAP_SCENE_PATH)
	if screen == null:
		return _fail("run_map.tscn 상점 인스턴스 생성 실패")
	root.add_child(screen)
	await _frames(8)
	var errors := 0
	errors += _assert_any_text(screen, "진행 리듬 — 현재 4 상점", "상점 진행 리듬")
	errors += _assert_any_text(screen, "다음 흐름: 5 보스 -> 6 칙령 -> 7 정예", "상점 다음 흐름")
	errors += _assert_any_tooltip(screen, "상점 떠나기", "상점 진행 리듬 tooltip")
	errors += _assert_button_tooltip(screen, "상점 떠나기", "다음 스테이지", "상점 떠나기 tooltip")
	errors += _assert_any_text(screen, "구매 가능", "상점 구매 가능 문구")
	errors += _assert_any_tooltip(screen, "구매하면 남은 자금", "상점 구매 후 자금 tooltip")
	errors += _assert_any_text(screen, "다음 전투 손패", "상점 다음 전투 손패 요약")
	errors += _assert_any_tooltip(screen, "드로우 더미", "상점 손패 정리 tooltip")
	errors += _assert_any_tooltip(screen, "손패 구매", "상점 카드 구매 경로 tooltip")
	errors += _assert_any_text(screen, "추천 —", "상점 전략 추천 문구")
	errors += _assert_any_tooltip(screen, "추천 —", "상점 전략 추천 tooltip")
	errors += _assert_first_recommended_button(screen, "추천 — 증원 후보", "상점 추천순 첫 카드")
	errors += _assert_any_tooltip(screen, "보드 배치", "보드 요약 카드 tooltip")
	if screen.has_method("_on_shop_card_pressed"):
		screen._on_shop_card_pressed(&"troop_infantry")
		await _frames(4)
		errors += _assert_any_text(screen, "구매 완료", "상점 구매 완료 문구")
		errors += _assert_any_text(screen, "남은 자금", "상점 구매 후 남은 자금 문구")
		errors += _assert_any_text(screen, "상점 손패 4장 → 전투 후보 3장", "구매 후 상점 손패 정리 문구")
		errors += _assert_any_tooltip(screen, "현재 손패 4장", "구매 후 상점 손패 tooltip")
	else:
		errors += _fail("run_map._on_shop_card_pressed 없음")
	screen.queue_free()
	await _frames(2)
	if errors == 0:
		print("  런맵 상점 tooltip OK")
	return errors

func _run_map_shop_low_gold_case() -> int:
	var run_manager = _prepare_run_map_stage(4)
	if run_manager == null:
		return _fail("RunManager autoload 조회 실패")
	run_manager.state.gold = 0
	var screen = _instantiate_scene(RUN_MAP_SCENE_PATH)
	if screen == null:
		return _fail("run_map.tscn 저자금 상점 인스턴스 생성 실패")
	root.add_child(screen)
	await _frames(8)
	var errors := 0
	errors += _assert_any_text(screen, "자금 부족", "상점 자금 부족 문구")
	errors += _assert_any_text(screen, "현재 0금", "상점 현재 자금 문구")
	errors += _assert_any_tooltip(screen, "현재 자금 0금", "상점 자금 부족 tooltip")
	errors += _assert_any_tooltip(screen, "더 필요", "상점 부족 금액 tooltip")
	screen.queue_free()
	await _frames(2)
	if errors == 0:
		print("  런맵 저자금 상점 안내 OK")
	return errors

func _run_map_edict_case() -> int:
	if _prepare_run_map_stage(3) == null:
		return _fail("RunManager autoload 조회 실패")
	var screen = _instantiate_scene(RUN_MAP_SCENE_PATH)
	if screen == null:
		return _fail("run_map.tscn 칙령 인스턴스 생성 실패")
	root.add_child(screen)
	await _frames(8)
	var errors := 0
	errors += _assert_any_tooltip(screen, "선택하면 즉시 적용", "칙령 즉시 적용 tooltip")
	errors += _assert_any_tooltip(screen, "다음 스테이지", "칙령 다음 스테이지 tooltip")
	screen.queue_free()
	await _frames(2)
	if errors == 0:
		print("  런맵 칙령 tooltip OK")
	return errors

func _run_map_event_case() -> int:
	if _prepare_run_map_stage(11) == null:
		return _fail("RunManager autoload 조회 실패")
	var screen = _instantiate_scene(RUN_MAP_SCENE_PATH)
	if screen == null:
		return _fail("run_map.tscn 사건 인스턴스 생성 실패")
	root.add_child(screen)
	await _frames(8)
	var errors := 0
	errors += _assert_button_tooltip(screen, "군량 징발", "+20금", "사건 보상 tooltip")
	errors += _assert_button_tooltip(screen, "군량 징발", "다음 스테이지", "사건 이동 tooltip")
	screen.queue_free()
	await _frames(2)
	if errors == 0:
		print("  런맵 사건 tooltip OK")
	return errors

func _battle_deploy_case() -> int:
	var run_manager := root.get_node_or_null("/root/RunManager")
	if run_manager == null:
		return _fail("RunManager autoload 조회 실패")
	run_manager.reset_run()
	run_manager.ensure_started(LORD_ID)
	run_manager.state.stage_index = 1
	run_manager.state.board.clear()
	run_manager.state.hand.clear()
	run_manager.state.hand.append(&"scheme_raid")
	run_manager.state.hand.append(&"troop_infantry")
	run_manager.state.hand.append(&"building_dunjeon")
	var battle = _instantiate_scene(BATTLE_SCENE_PATH)
	if battle == null:
		return _fail("battle.tscn 인스턴스 생성 실패")
	root.add_child(battle)
	await _frames(8)
	var errors := 0
	errors += _assert_button_tooltip(battle, "계략 발동", "손패에서 계략", "계략 버튼 기본 tooltip")
	errors += _assert_any_text(battle, "전황 — 배치 준비", "전투 배치 전황 요약")
	errors += _assert_any_tooltip(battle, "병력 수 기준", "전투 배치 전황 tooltip")
	errors += _assert_tile_state_hidden_and_tooltip(battle, "1:1", "성 후보", "성 위치가 됩니다", "첫 전투 성 후보 타일")
	errors += _assert_tile_hover_hint(battle, "1:1", "성 후보", "첫 전투 성 후보 hover hint")
	errors += _assert_button_tooltip(battle, "우물", "+10골드", "우물 버튼 tooltip")
	errors += _assert_button_tooltip(battle, "교전 시작", "성 위치", "교전 시작 비활성 tooltip")
	errors += _assert_button_tooltip(battle, "계략 발동", "계략 발동 버튼", "계략 손패 tooltip")
	errors += _assert_button_tooltip(battle, "12명 분대", "빈 타일", "병종 손패 tooltip")
	errors += _assert_default_speed_fast(battle)
	errors += _assert_battlefield_ground_plane(battle)
	if battle.has_method("_select_hand"):
		battle._select_hand(0)
		await _frames(2)
		errors += _assert_button_tooltip(battle, "계략 발동", "선택한 계략", "선택 계략 tooltip")
		battle._select_hand(1)
		await _frames(2)
		errors += _assert_button_tooltip(battle, "우물", "먼저 성", "선택 우물 tooltip")
	battle.queue_free()
	await _frames(2)
	if errors == 0:
		print("  전투 배치 tooltip OK")
	return errors

func _battle_manual_first_play_case() -> int:
	var run_manager := root.get_node_or_null("/root/RunManager")
	if run_manager == null:
		return _fail("RunManager autoload 조회 실패")
	run_manager.reset_run()
	run_manager.ensure_started(LORD_ID)
	run_manager.state.stage_index = 1
	run_manager.state.castle_key = ""
	run_manager.state.board.clear()
	run_manager.state.board_levels.clear()
	run_manager.state.hand.clear()
	run_manager.state.draw_pile.clear()
	run_manager.state.hand.append(&"scheme_raid")
	run_manager.state.hand.append(&"troop_infantry")
	run_manager.state.hand.append(&"building_dunjeon")
	run_manager.state.deploy_cards_played = 0
	run_manager.state.deploy_stage_index = 1
	var battle = _instantiate_scene(BATTLE_SCENE_PATH)
	if battle == null:
		return _fail("battle.tscn 수동 첫 플레이 인스턴스 생성 실패")
	root.add_child(battle)
	await _frames(8)
	battle._paused = true
	var errors := 0
	battle._on_tile_pressed("1:1")
	await _frames(2)
	if run_manager.get_castle_key() != "1:1":
		errors += _fail("수동 첫 플레이 성 선택 실패: %s" % run_manager.get_castle_key())
	if battle._hint_label.text.find("성 위치") < 0:
		errors += _fail("수동 첫 플레이 성 선택 힌트 누락: %s" % battle._hint_label.text)
	errors += _assert_tile_state_hidden_and_tooltip(battle, "0:0", "손패 선택", "손패 3장", "성 선택 후 손패 선택 타일")
	battle._select_hand(0)
	await _frames(2)
	errors += _assert_tile_state_hidden_and_tooltip(battle, "0:0", "계략 버튼", "계략은 타일", "계략 선택 후 타일 안내")
	battle._on_tile_pressed("0:0")
	await _frames(2)
	if run_manager.state.board.size() != 0:
		errors += _fail("계략 타일 배치 거부 실패: board=%s" % str(run_manager.state.board))
	if run_manager.state.deploy_cards_played != 0:
		errors += _fail("계략 타일 거부 후 교전 카드 소모됨: %d" % run_manager.state.deploy_cards_played)
	if battle._hint_label.text.find("계략은 타일") < 0:
		errors += _fail("계략 타일 거부 힌트 누락: %s" % battle._hint_label.text)
	battle._select_hand(1)
	await _frames(2)
	errors += _assert_tile_state_hidden_and_tooltip(battle, "0:0", "배치 가능", "보병 배치", "병종 선택 후 배치 가능 타일")
	errors += _assert_tile_hover_hint(battle, "0:0", "보병 배치", "병종 선택 후 배치 hover hint")
	errors += _assert_deploy_preview_ghost_on_hover(battle, "0:0", "병종 배치 hover ghost")
	battle._on_tile_pressed("0:0")
	await _frames(8)
	errors += _assert_manual_first_play_started(battle, run_manager)
	errors += _assert_any_text(battle, "전황 — 교전", "전투 교전 전황 요약")
	errors += _assert_any_text(battle, "아군 12", "전투 교전 아군 병력 요약")
	errors += _assert_any_text(battle, "적 25", "전투 교전 적 병력 요약")
	errors += _assert_any_tooltip(battle, "파도는 이번 교전", "전투 교전 전황 tooltip")
	battle.queue_free()
	await _frames(2)
	if errors == 0:
		print("  전투 수동 첫 플레이 OK")
	return errors

func _battle_formation_preview_case() -> int:
	var run_manager := root.get_node_or_null("/root/RunManager")
	if run_manager == null:
		return _fail("RunManager autoload 조회 실패")
	run_manager.reset_run()
	run_manager.ensure_started(LORD_ID)
	run_manager.state.stage_index = 1
	run_manager.state.castle_key = "0:2"
	run_manager.state.board = {"1:0": &"troop_infantry"}
	run_manager.state.board_levels = {"1:0": 1}
	run_manager.state.hand.clear()
	run_manager.state.hand.append(&"troop_archer")
	run_manager.state.hand.append(&"troop_cavalry")
	run_manager.state.hand.append(&"building_dunjeon")
	var battle = _instantiate_scene(BATTLE_SCENE_PATH)
	if battle == null:
		return _fail("battle.tscn 전술 미리보기 인스턴스 생성 실패")
	root.add_child(battle)
	await _frames(8)
	var errors := 0
	if battle.has_method("_select_hand"):
		battle._select_hand(0)
		await _frames(2)
		errors += _assert_occupied_tile_label_hidden(battle, "1:0", "보병", "기존 보병 field label 숨김")
		errors += _assert_tile_label_and_tooltip(battle, "1:1", "엄호 +15%", "궁병 배치", "궁병 엄호 미리보기")
		errors += _assert_deploy_preview_ghost_on_hover(battle, "1:1", "전술 preview hover ghost")
		errors += _assert_deploy_unit_visuals_above_field(battle)
	else:
		errors += _fail("battle._select_hand 없음")
	battle.queue_free()
	await _frames(2)
	if errors == 0:
		print("  전투 전술 미리보기 OK")
	return errors

func _battle_command_feedback_case() -> int:
	var run_manager := root.get_node_or_null("/root/RunManager")
	if run_manager == null:
		return _fail("RunManager autoload 조회 실패")
	run_manager.reset_run()
	run_manager.ensure_started(LORD_ID)
	run_manager.state.stage_index = 1
	run_manager.state.castle_key = "1:1"
	run_manager.state.board = {"0:0": &"general_guanyu"}
	run_manager.state.board_levels = {"0:0": 1}
	run_manager.state.hand.clear()
	run_manager.state.deploy_cards_played = 1
	run_manager.state.deploy_stage_index = 1
	var battle = _instantiate_scene(BATTLE_SCENE_PATH)
	if battle == null:
		return _fail("battle.tscn 집중표적 인스턴스 생성 실패")
	root.add_child(battle)
	await _frames(8)
	var errors := 0
	if battle.has_method("_on_start_pressed"):
		battle._on_start_pressed()
	else:
		errors += _fail("battle._on_start_pressed 없음")
	await _frames(2)
	battle._paused = true
	if battle._sim.enemy_units.is_empty():
		errors += _fail("집중표적 검증용 적 없음")
	elif battle._ability_buttons.size() < 2:
		errors += _fail("집중표적 버튼 없음")
	else:
		var target: BattleUnit = battle._sim.enemy_units[0]
		var focus_button := battle._ability_buttons[1] as Button
		focus_button.button_pressed = true
		battle._on_focus_toggled()
		battle._apply_hero_command_at(battle.field_to_screen(target.px, target.py))
		await _frames(2)
		errors += _assert_command_feedback(battle, target)
		battle._apply_hero_command_at(Vector2(0.0, 0.0))
		await _frames(2)
		if battle._commanded_target != null:
			errors += _fail("빈 곳 클릭 후 집중표적 해제 실패")
		if battle._hint_label.text.find("범위 안 적 없음") < 0:
			errors += _fail("빈 곳 클릭 자동 표적 문구 누락: %s" % battle._hint_label.text)
	battle.queue_free()
	await _frames(2)
	if errors == 0:
		print("  전투 집중표적 피드백 OK")
	return errors

func _battle_reward_case() -> int:
	var run_manager := root.get_node_or_null("/root/RunManager")
	if run_manager == null:
		return _fail("RunManager autoload 조회 실패")
	run_manager.reset_run()
	run_manager.ensure_started(LORD_ID)
	run_manager.state.stage_index = 1
	run_manager.state.board = {
		"0:0": &"troop_infantry",
		"1:0": &"troop_archer",
		"2:0": &"troop_cavalry",
	}
	var battle = _instantiate_scene(BATTLE_SCENE_PATH)
	if battle == null:
		return _fail("battle.tscn 보상 인스턴스 생성 실패")
	root.add_child(battle)
	await _frames(8)
	battle._sim.result = BattleSim.Result.PLAYER_WIN
	battle._end_battle()
	await _frames(8)
	var errors := 0
	errors += _assert_any_text(battle, "결과 — 전투 승리", "보상 화면 결과 배너")
	errors += _assert_any_text(battle, "다음 행동 — 전리품 선택 후 런맵 복귀", "보상 화면 다음 행동")
	errors += _assert_any_text(battle, "런 계속 — 전리품을 고르고 런맵으로 복귀", "보상 화면 런 계속 안내")
	errors += _assert_any_text(battle, "전리품 — 한 장을 고르세요", "보상 선택 제목")
	errors += _assert_any_text(battle, "카드 버튼을 누르면", "보상 선택 행동 안내")
	errors += _assert_button_text(battle, "선택 —", "보상 선택 버튼")
	errors += _assert_button_text(battle, "추천 —", "보상 선택 전략 추천")
	errors += _assert_button_text(battle, "비교 —", "보상 선택 비교 문구")
	errors += _assert_any_tooltip(battle, "이 전리품을 선택합니다", "보상 선택 tooltip")
	errors += _assert_any_tooltip(battle, "추천 —", "보상 전략 추천 tooltip")
	errors += _assert_any_tooltip(battle, "비교 —", "보상 비교 tooltip")
	errors += _press_first_button(battle, "선택 —", "보상 선택 실행")
	await _frames(4)
	errors += _assert_any_text(battle, "다음 준비 — 스테이지 2 — 전투", "보상 후 다음 준비 제목")
	errors += _assert_any_text(battle, "손패 3장 중 1장", "보상 후 다음 전투 준비 문구")
	errors += _assert_any_text(battle, "다음 배치 손패", "보상 후 다음 배치 손패 안내")
	errors += _assert_button_text(battle, "다음 스테이지로 — 스테이지 2 — 전투", "보상 후 다음 스테이지 버튼")
	errors += _assert_any_tooltip(battle, "현재 런을 유지한 채", "보상 후 다음 스테이지 유지 tooltip")
	errors += _assert_any_tooltip(battle, "런맵에서 전투 시작", "보상 후 다음 스테이지 tooltip")
	errors += _assert_any_tooltip(battle, "드로우 더미", "보상 후 다음 배치 손패 tooltip")
	errors += _assert_any_tooltip(battle, "현재 런을 포기", "보상 후 새 런 tooltip")
	battle.queue_free()
	await _frames(2)
	if errors == 0:
		print("  전투 보상 안내 OK")
	return errors

func _prepare_run_map_stage(stage: int):
	var run_manager := root.get_node_or_null("/root/RunManager")
	if run_manager == null:
		return null
	run_manager.reset_run()
	run_manager.ensure_started(LORD_ID)
	run_manager.state.stage_index = stage
	run_manager.state.board.clear()
	return run_manager

func _instantiate_scene(path: String):
	var scene := load(path)
	if scene == null:
		return null
	return scene.instantiate()

func _assert_button_tooltip(node: Node, text_needle: String, tooltip_needle: String, msg: String) -> int:
	for button in _buttons(node):
		if _control_text_contains(button, text_needle) and button.tooltip_text.find(tooltip_needle) >= 0:
			return 0
	return _fail("%s 누락: text=%s tooltip~=%s" % [msg, text_needle, tooltip_needle])

func _assert_any_tooltip(node: Node, tooltip_needle: String, msg: String) -> int:
	for control in _controls(node):
		if control.tooltip_text.find(tooltip_needle) >= 0:
			return 0
	return _fail("%s 누락: tooltip~=%s" % [msg, tooltip_needle])

func _assert_any_text(node: Node, text_needle: String, msg: String) -> int:
	for text in _collect_texts(node):
		if text.find(text_needle) >= 0:
			return 0
	return _fail("%s 누락: text~=%s" % [msg, text_needle])

func _assert_button_text(node: Node, text_needle: String, msg: String) -> int:
	for button in _buttons(node):
		if button.text.find(text_needle) >= 0:
			return 0
	return _fail("%s 누락: button text~=%s" % [msg, text_needle])

func _press_first_button(node: Node, text_needle: String, msg: String) -> int:
	for button in _buttons(node):
		if button.text.find(text_needle) >= 0:
			button.emit_signal("pressed")
			return 0
	return _fail("%s 누락: button text~=%s" % [msg, text_needle])

func _assert_first_recommended_button(node: Node, text_needle: String, msg: String) -> int:
	for button in _buttons(node):
		if not _control_text_contains(button, "추천 —"):
			continue
		if _control_text_contains(button, text_needle):
			return 0
		return _fail("%s 실패: first=%s expected~=%s" % [msg, _joined_texts(button), text_needle])
	return _fail("%s 누락: 추천 카드 버튼 없음" % msg)

func _assert_tile_label_and_tooltip(battle: Node, block_key: String, text_needle: String, tooltip_needle: String, msg: String) -> int:
	var tiles: Dictionary = battle._tile_buttons
	if not tiles.has(block_key):
		return _fail("%s 누락: tile=%s" % [msg, block_key])
	var tile: Dictionary = tiles[block_key]
	var label := tile.get("label", null) as Label
	if label == null:
		return _fail("%s 누락: label 없음" % msg)
	if not label.visible:
		return _fail("%s 실패: visible label 아님" % msg)
	if label.text.find(text_needle) < 0:
		return _fail("%s 누락: text=%s expected~=%s" % [msg, label.text, text_needle])
	if label.tooltip_text.find(tooltip_needle) < 0:
		return _fail("%s 누락: tooltip=%s expected~=%s" % [msg, label.tooltip_text, tooltip_needle])
	return 0

func _assert_tile_state_hidden_and_tooltip(battle: Node, block_key: String, state_needle: String, tooltip_needle: String, msg: String) -> int:
	var tiles: Dictionary = battle._tile_buttons
	if not tiles.has(block_key):
		return _fail("%s 누락: tile=%s" % [msg, block_key])
	var tile: Dictionary = tiles[block_key]
	var label := tile.get("label", null) as Label
	if label == null:
		return _fail("%s 누락: label 없음" % msg)
	if label.visible and not label.text.strip_edges().is_empty():
		return _fail("%s 실패: 숨길 generic label이 보임: %s" % [msg, label.text])
	var state_label := String(tile.get("state_label", ""))
	if state_label.find(state_needle) < 0:
		return _fail("%s 누락: state=%s expected~=%s" % [msg, state_label, state_needle])
	var tooltip := String(tile.get("tooltip", ""))
	if tooltip.find(tooltip_needle) < 0:
		return _fail("%s 누락: tooltip=%s expected~=%s" % [msg, tooltip, tooltip_needle])
	var area := tile.get("area", null) as Area2D
	if area != null and String(area.get_meta(&"tile_tooltip", "")).find(tooltip_needle) < 0:
		return _fail("%s 누락: area tooltip=%s expected~=%s" % [msg, String(area.get_meta(&"tile_tooltip", "")), tooltip_needle])
	return 0

func _assert_occupied_tile_label_hidden(battle: Node, block_key: String, state_needle: String, msg: String) -> int:
	var tiles: Dictionary = battle._tile_buttons
	if not tiles.has(block_key):
		return _fail("%s 누락: tile=%s" % [msg, block_key])
	var tile: Dictionary = tiles[block_key]
	var label := tile.get("label", null) as Label
	if label == null:
		return _fail("%s 누락: label 없음" % msg)
	if label.visible or not label.text.strip_edges().is_empty():
		return _fail("%s 실패: 점유 field label이 유닛 앞에 남음: %s" % [msg, label.text])
	var state_label := String(tile.get("state_label", ""))
	if state_label.find(state_needle) < 0:
		return _fail("%s 누락: state=%s expected~=%s" % [msg, state_label, state_needle])
	var tooltip := String(tile.get("tooltip", ""))
	if tooltip.strip_edges().is_empty():
		return _fail("%s 누락: 점유 tile tooltip 없음" % msg)
	return 0

func _assert_tile_hover_hint(battle: Node, block_key: String, hint_needle: String, msg: String) -> int:
	if not battle.has_method("_on_tile_area_hovered"):
		return _fail("%s 누락: hover handler 없음" % msg)
	battle._on_tile_area_hovered(block_key)
	if battle._hint_label.text.find(hint_needle) < 0:
		return _fail("%s 누락: hint=%s expected~=%s" % [msg, battle._hint_label.text, hint_needle])
	battle._on_tile_area_unhovered(block_key)
	return 0

func _assert_deploy_unit_visuals_above_field(battle: Node) -> int:
	if battle._iso_base_layer == null or battle._units_layer == null:
		return _fail("배치 유닛 depth 검증용 레이어 누락")
	var field_total_z: int = int(battle._iso_base_layer.z_index) + _max_field_visual_z(battle)
	var checked := false
	for unit in battle._vis.keys():
		var battle_unit := unit as BattleUnit
		if battle_unit == null or battle_unit.is_castle:
			continue
		var visual: Dictionary = battle._vis[unit]
		var root := visual.get("root", null) as Node2D
		if root == null:
			continue
		checked = true
		var unit_total_z: int = int(battle._units_layer.z_index) + root.z_index
		if unit_total_z <= field_total_z:
			return _fail("배치 유닛이 필드 뒤에 그려짐: unit=%d field=%d" % [unit_total_z, field_total_z])
	if not checked:
		return _fail("배치 유닛 depth 검증 대상 없음")
	return _assert_deploy_unit_foot_forward_of_tile(battle)

func _assert_deploy_preview_ghost_on_hover(battle: Node, block_key: String, msg: String) -> int:
	if not battle.has_method("_on_tile_area_hovered") or not battle.has_method("_on_tile_area_unhovered"):
		return _fail("%s 누락: hover handler 없음" % msg)
	if battle._deploy_preview_layer == null:
		return _fail("%s 누락: DeployPreviewLayer 없음" % msg)
	battle._on_tile_area_hovered(block_key)
	var errors := 0
	if battle._deploy_preview_ghost_count() != 1:
		errors += _fail("%s 실패: hover ghost count=%d" % [msg, battle._deploy_preview_ghost_count()])
	else:
		var ghost := _first_deploy_preview_ghost(battle)
		if ghost == null:
			errors += _fail("%s 실패: ghost root 없음" % msg)
		else:
			var tile_parts := block_key.split(":")
			if tile_parts.size() == 2 and tile_parts[0].is_valid_int() and tile_parts[1].is_valid_int():
				var tile_pos := BattleSim.position_for_tile(int(tile_parts[0]), int(tile_parts[1]))
				var tile_center: Vector2 = battle.field_to_screen_position(tile_pos)
				if ghost.position.y < tile_center.y + 66.0:
					errors += _fail("%s 실패: ghost footline이 타일 뒤에 있음" % msg)
			if battle._formation_member_nodes(ghost).size() < 4:
				errors += _fail("%s 실패: ghost가 분대 실루엣을 만들지 않음" % msg)
	battle._on_tile_area_unhovered(block_key)
	if battle._deploy_preview_ghost_count() != 0:
		errors += _fail("%s 실패: hover 해제 뒤 ghost 잔존" % msg)
	return errors

func _assert_deploy_unit_foot_forward_of_tile(battle: Node) -> int:
	var bounds := _battlefield_tile_y_bounds(battle)
	var checked := false
	for unit in battle._vis.keys():
		var battle_unit := unit as BattleUnit
		if battle_unit == null or battle_unit.is_castle:
			continue
		if battle_unit.team != BattleUnit.Team.PLAYER:
			continue
		var visual: Dictionary = battle._vis[unit]
		var root := visual.get("root", null) as Node2D
		if root == null:
			continue
		checked = true
		if battle_unit.row >= 0:
			var tile_center: Vector2 = battle.field_to_screen_position(BattleSim.position_for_tile(battle_unit.lane, battle_unit.row))
			if root.position.y < tile_center.y + 66.0:
				return _fail("배치 유닛 발 위치가 타일 하단보다 뒤에 있음: y=%.1f tile=%.1f" % [root.position.y, tile_center.y])
		elif not bounds.is_empty():
			var min_y := float(bounds.get("min_y", 0.0))
			if root.position.y < min_y + 66.0:
				return _fail("배치 유닛 발 위치가 전장 지면보다 뒤에 있음: y=%.1f min=%.1f" % [root.position.y, min_y])
	if not checked:
		return _fail("배치 유닛 foot 검증 대상 없음")
	return 0

func _assert_command_feedback(battle: Node, target: BattleUnit) -> int:
	var errors := 0
	if battle._commanded_target != target:
		errors += _fail("집중표적 대상 저장 실패")
	if battle._hint_label.text.find(target.display_name) < 0 or battle._hint_label.text.find("장수 1명") < 0:
		errors += _fail("집중표적 힌트 문구 누락: %s" % battle._hint_label.text)
	var focus_button := battle._ability_buttons[1] as Button
	if focus_button.tooltip_text.find("현재 %s" % target.display_name) < 0:
		errors += _fail("집중표적 현재 target tooltip 누락: %s" % focus_button.tooltip_text)
	if not battle._vis.has(target):
		return errors + _fail("집중표적 target visual 없음")
	var visual: Dictionary = battle._vis[target]
	var marker := visual.get("command_marker", null) as Polygon2D
	if marker == null or not marker.visible:
		errors += _fail("집중표적 marker 표시 실패")
	var label := visual.get("command_label", null) as Label
	if label == null or not label.visible or label.text.find("집중") < 0:
		errors += _fail("집중표적 label 표시 실패")
	return errors

func _first_deploy_preview_ghost(battle: Node) -> Node2D:
	for child in battle._deploy_preview_layer.get_children():
		if bool(child.get_meta(&"deploy_preview_ghost", false)):
			return child as Node2D
	return null

func _assert_manual_first_play_started(battle: Node, run_manager) -> int:
	var errors := 0
	if run_manager.get_castle_key() != "1:1":
		errors += _fail("수동 첫 플레이 성 위치 유지 실패: %s" % run_manager.get_castle_key())
	var board: Dictionary = run_manager.get_board()
	if StringName(board.get("0:0", &"")) != &"troop_infantry":
		errors += _fail("수동 첫 플레이 보병 배치 실패: %s" % str(board))
	if run_manager.state.deploy_cards_played != 1:
		errors += _fail("수동 첫 플레이 교전당 1장 카운트 실패: %d" % run_manager.state.deploy_cards_played)
	if run_manager.can_place_deploy_card():
		errors += _fail("수동 첫 플레이 후 추가 배치 가능 상태")
	if run_manager.get_hand().size() != 2:
		errors += _fail("수동 첫 플레이 손패 감소 실패: %d" % run_manager.get_hand().size())
	if int(battle._phase) != BATTLE_PHASE_BATTLE:
		errors += _fail("수동 첫 플레이 전투 phase 진입 실패: %d" % int(battle._phase))
	if battle._selected_hand_index != -1:
		errors += _fail("수동 첫 플레이 선택 손패 해제 실패: %d" % battle._selected_hand_index)
	if battle._sim.castle == null or not battle._sim.castle.is_alive():
		errors += _fail("수동 첫 플레이 성 유닛 생성 실패")
	if battle._sim.enemy_units.is_empty():
		errors += _fail("수동 첫 플레이 적 유닛 생성 실패")
	var has_infantry := false
	for unit in battle._sim.player_units:
		var battle_unit := unit as BattleUnit
		if battle_unit != null and battle_unit.card_id == &"troop_infantry":
			has_infantry = true
			break
	if not has_infantry:
		errors += _fail("수동 첫 플레이 아군 보병 유닛 생성 실패")
	if battle._hint_label.text.find("전군 돌격") < 0:
		errors += _fail("수동 첫 플레이 시작 함성 힌트 누락: %s" % battle._hint_label.text)
	if battle._hint_label.text.find("아군 12") < 0 or battle._hint_label.text.find("적 25") < 0:
		errors += _fail("수동 첫 플레이 군세 숫자 힌트 누락: %s" % battle._hint_label.text)
	var rally_count := _count_vfx_meta(battle._vfx_layer, "rally")
	var force_roar_count := _count_vfx_meta(battle._vfx_layer, "force_roar")
	var charge_count := _count_vfx_meta(battle._vfx_layer, "charge")
	var dust_count := _count_vfx_meta(battle._vfx_layer, "advance_dust")
	var ground_clash_count := _count_vfx_meta(battle._vfx_layer, "ground_clash")
	var pressure_count := _count_vfx_meta(battle._vfx_layer, "pressure")
	var pulse_count := _count_vfx_meta(battle._vfx_layer, "pulse")
	if rally_count < 1:
		errors += _fail("수동 첫 플레이 rally banner VFX 누락")
	if force_roar_count < 1:
		errors += _fail("수동 첫 플레이 force roar VFX 누락")
	if charge_count < 6:
		errors += _fail("수동 첫 플레이 charge line VFX 부족: %d" % charge_count)
	if dust_count < _BattleFeel.ADVANCE_DUST_TOTAL:
		errors += _fail("수동 첫 플레이 advance dust VFX 부족: %d" % dust_count)
	if ground_clash_count < _BattleFeel.GROUND_CLASH_TOTAL:
		errors += _fail("수동 첫 플레이 ground clash VFX 부족: %d" % ground_clash_count)
	if pressure_count < _BattleFeel.CLASH_PRESSURE_MIN:
		errors += _fail("수동 첫 플레이 pressure VFX 부족: %d" % pressure_count)
	if pulse_count < 3:
		errors += _fail("수동 첫 플레이 clash pulse VFX 부족: %d" % pulse_count)
	var ground_shadow_count := _count_bool_meta(battle._units_layer, &"ground_shadow")
	if ground_shadow_count < 10:
		errors += _fail("수동 첫 플레이 ground shadow 부족: %d" % ground_shadow_count)
	errors += _assert_battlefield_depth_order(battle)
	errors += _assert_hit_impact_vfx(battle)
	return errors

func _assert_battlefield_depth_order(battle: Node) -> int:
	var errors := 0
	if battle._iso_base_layer == null or battle._units_layer == null:
		return _fail("전장 depth 검증용 레이어 누락")
	if battle._iso_base_layer.visible or battle._iso_base_layer.modulate.a > 0.01:
		errors += _fail("교전 시작 후 배치 필드 숨김 실패: visible=%s alpha=%.2f" % [str(battle._iso_base_layer.visible), battle._iso_base_layer.modulate.a])
	if battle._iso_base_layer.z_index >= battle._units_layer.z_index:
		errors += _fail("전장 depth 순서 오류: field=%d units=%d" % [battle._iso_base_layer.z_index, battle._units_layer.z_index])
	var plate_count := _count_bool_meta(battle._iso_base_layer, &"battlefield_ground_plate")
	if plate_count < 2:
		errors += _fail("전장 지면 plate/shadow 부족: %d" % plate_count)
	var unit_root := _first_visual_root(battle)
	if unit_root == null:
		errors += _fail("전장 depth 검증용 유닛 visual 누락")
	else:
		var unit_total_z: int = int(battle._units_layer.z_index) + unit_root.z_index
		var field_total_z: int = int(battle._iso_base_layer.z_index) + _max_field_visual_z(battle)
		if unit_total_z <= field_total_z:
			errors += _fail("전장 depth 총 z 오류: unit=%d field=%d" % [unit_total_z, field_total_z])
	errors += _assert_unit_roots_share_battlefield_y(battle)
	return errors

func _assert_battlefield_ground_plane(battle: Node) -> int:
	var errors := 0
	if battle._iso_base_layer == null:
		return _fail("전장 지면 검증용 필드 레이어 누락")
	if battle._tile_buttons.is_empty():
		return _fail("전장 지면 검증용 타일 누락")
	var min_y := INF
	var max_y := -INF
	var y_values: Array = []
	for key in battle._tile_buttons.keys():
		var parts := String(key).split(":")
		if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
			continue
		var center: Vector2 = battle.field_to_screen_position(BattleSim.position_for_tile(int(parts[0]), int(parts[1])))
		min_y = minf(min_y, center.y)
		max_y = maxf(max_y, center.y)
		if not y_values.has(center.y):
			y_values.append(center.y)
	var contact_count := _count_bool_meta(battle._iso_base_layer, &"battlefield_tile_contact")
	if contact_count < battle._tile_buttons.size():
		errors += _fail("전장 타일 접지 shadow 부족: %d/%d" % [contact_count, battle._tile_buttons.size()])
	var outline_count := _count_bool_meta(battle._iso_base_layer, &"battlefield_tile_outline")
	if outline_count < battle._tile_buttons.size():
		errors += _fail("전장 타일 지면 outline 부족: %d/%d" % [outline_count, battle._tile_buttons.size()])
	var seam_count := _count_bool_meta(battle._iso_base_layer, &"battlefield_tile_floor_seam")
	if seam_count < battle._tile_buttons.size() * 2:
		errors += _fail("전장 타일 바닥 seam 부족: %d/%d" % [seam_count, battle._tile_buttons.size() * 2])
	var max_tile_fill_alpha := _max_tile_fill_alpha(battle)
	if max_tile_fill_alpha > 0.08:
		errors += _fail("전장 타일 fill이 너무 진해 공중 판처럼 보임: alpha=%.2f" % max_tile_fill_alpha)
	var max_tile_outline_alpha := _max_tile_outline_alpha(battle)
	if max_tile_outline_alpha > 0.10:
		errors += _fail("전장 타일 outline이 너무 밝아 공중 격자처럼 보임: alpha=%.2f" % max_tile_outline_alpha)
	var max_seam_alpha := _max_line_meta_alpha(battle._iso_base_layer, &"battlefield_tile_floor_seam")
	if max_seam_alpha < 0.11:
		errors += _fail("전장 타일 바닥 seam이 너무 약해 칸이 안 보임: alpha=%.2f" % max_seam_alpha)
	if max_seam_alpha > 0.18:
		errors += _fail("전장 타일 바닥 seam이 너무 강해 공중 격자처럼 보임: alpha=%.2f" % max_seam_alpha)
	var floor_band_count := _count_bool_meta(battle._background_layer, &"battlefield_floor_band")
	if floor_band_count < 1:
		errors += _fail("전장 배경 지면 밴드 누락")
	var max_floor_alpha := _max_polygon_meta_alpha(battle._background_layer, &"battlefield_floor_band")
	if max_floor_alpha > 0.025:
		errors += _fail("전장 지면 밴드가 너무 진해 공중 plate처럼 보임: alpha=%.2f" % max_floor_alpha)
	var max_plate_alpha := _max_polygon_meta_alpha(battle._iso_base_layer, &"battlefield_ground_plate")
	if max_plate_alpha > 0.03:
		errors += _fail("전장 지면 plate가 너무 진해 필드판처럼 보임: alpha=%.2f" % max_plate_alpha)
	var depth_lane_count := _count_bool_meta(battle._background_layer, &"battlefield_depth_lane")
	if depth_lane_count < BattleSim.COL_COUNT:
		errors += _fail("전장 진군 레인 부족: %d/%d" % [depth_lane_count, BattleSim.COL_COUNT])
	var max_lane_alpha := _max_polygon_meta_alpha(battle._background_layer, &"battlefield_depth_lane")
	if max_lane_alpha > 0.06:
		errors += _fail("전장 진군 레인이 너무 진해 공중 판처럼 보임: alpha=%.2f" % max_lane_alpha)
	if min_y < 630.0:
		errors += _fail("전장 보드가 지면 밴드보다 위에 있음: min_y=%.1f" % min_y)
	if max_y > 835.0:
		errors += _fail("전장 보드가 하단 HUD와 겹칠 위험: max_y=%.1f" % max_y)
	y_values.sort()
	for i in range(1, y_values.size()):
		var gap := float(y_values[i]) - float(y_values[i - 1])
		if gap > 104.0:
			errors += _fail("전장 타일 세로 간격 과다: gap=%.1f" % gap)
	return errors

func _assert_unit_roots_share_battlefield_y(battle: Node) -> int:
	var bounds := _battlefield_tile_y_bounds(battle)
	if bounds.is_empty():
		return _fail("전장 유닛 y 검증용 타일 bounds 없음")
	var min_y := float(bounds.get("min_y", 0.0))
	var max_y := float(bounds.get("max_y", 0.0))
	var errors := 0
	var checked := 0
	for value in battle._vis.values():
		if not (value is Dictionary):
			continue
		var root := (value as Dictionary).get("root", null) as Node2D
		if root == null:
			continue
		checked += 1
		if root.position.y < min_y + 8.0:
			errors += _fail("유닛이 전장 지면보다 위에 떠 있음: y=%.1f min=%.1f" % [root.position.y, min_y])
		if root.position.y > max_y + 96.0:
			errors += _fail("유닛이 전장 지면 하단을 벗어남: y=%.1f max=%.1f" % [root.position.y, max_y])
	if checked <= 0:
		errors += _fail("전장 유닛 y 검증 대상 없음")
	return errors

func _battlefield_tile_y_bounds(battle: Node) -> Dictionary:
	if battle == null or battle._tile_buttons.is_empty():
		return {}
	var min_y := INF
	var max_y := -INF
	for key in battle._tile_buttons.keys():
		var parts := String(key).split(":")
		if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
			continue
		var center: Vector2 = battle.field_to_screen_position(BattleSim.position_for_tile(int(parts[0]), int(parts[1])))
		min_y = minf(min_y, center.y)
		max_y = maxf(max_y, center.y)
	if min_y == INF or max_y == -INF:
		return {}
	return {"min_y": min_y, "max_y": max_y}

func _first_visual_root(battle: Node) -> Node2D:
	for value in battle._vis.values():
		if value is Dictionary:
			var root := (value as Dictionary).get("root", null) as Node2D
			if root != null:
				return root
	return null

func _max_field_visual_z(battle: Node) -> int:
	var max_z := -4096
	for value in battle._tile_buttons.values():
		if not (value is Dictionary):
			continue
		var tile := value as Dictionary
		for key in ["sprite", "poly", "outline", "label"]:
			var item := tile.get(key, null) as CanvasItem
			if item != null:
				max_z = maxi(max_z, item.z_index)
	return max_z

func _max_tile_fill_alpha(battle: Node) -> float:
	var max_alpha := 0.0
	for value in battle._tile_buttons.values():
		if not (value is Dictionary):
			continue
		var tile := value as Dictionary
		var sprite := tile.get("sprite", null) as Sprite2D
		if sprite != null:
			max_alpha = maxf(max_alpha, sprite.modulate.a)
		var poly := tile.get("poly", null) as Polygon2D
		if poly != null:
			max_alpha = maxf(max_alpha, poly.color.a)
	return max_alpha

func _max_tile_outline_alpha(battle: Node) -> float:
	var max_alpha := 0.0
	for value in battle._tile_buttons.values():
		if not (value is Dictionary):
			continue
		var outline := (value as Dictionary).get("outline", null) as Line2D
		if outline != null:
			max_alpha = maxf(max_alpha, outline.default_color.a)
	return max_alpha

func _max_line_meta_alpha(node: Node, key: StringName) -> float:
	if node == null:
		return 0.0
	var max_alpha := 0.0
	if bool(node.get_meta(key, false)) and node is Line2D:
		max_alpha = maxf(max_alpha, (node as Line2D).default_color.a)
	for child in node.get_children():
		max_alpha = maxf(max_alpha, _max_line_meta_alpha(child, key))
	return max_alpha

func _assert_hit_impact_vfx(battle: Node) -> int:
	var enemy := _first_alive_enemy(battle)
	if enemy == null:
		return _fail("hit impact 검증용 적 유닛 없음")
	battle._sim.last_damage_events = [
		{
			"target": enemy,
			"amount": 12,
			"px": enemy.px,
			"py": enemy.py,
			"team": enemy.team,
			"is_crit": true,
			"kind": "attack",
		},
		{
			"target": enemy,
			"amount": 40,
			"px": enemy.px,
			"py": enemy.py,
			"team": enemy.team,
			"is_crit": false,
			"kind": "skill",
		},
	]
	battle._play_damage_events()
	var errors := 0
	var spark_count := _count_hit_vfx_meta(battle._vfx_layer, "spark")
	var crit_count := _count_hit_vfx_meta(battle._vfx_layer, "crit")
	var burst_count := _count_hit_vfx_meta(battle._vfx_layer, "burst")
	var ground_dust_count := _count_hit_vfx_meta(battle._vfx_layer, "ground_dust")
	var ground_ring_count := _count_hit_vfx_meta(battle._vfx_layer, "ground_ring")
	if spark_count < 2:
		errors += _fail("hit impact spark VFX 부족: %d" % spark_count)
	if crit_count < 1:
		errors += _fail("hit impact crit VFX 누락")
	if burst_count < 1:
		errors += _fail("hit impact skill burst VFX 누락")
	if ground_dust_count < 2:
		errors += _fail("hit impact ground dust VFX 부족: %d" % ground_dust_count)
	if ground_ring_count < 2:
		errors += _fail("hit impact ground ring VFX 부족: %d" % ground_ring_count)
	if float(battle._impact_camera_cooldown) <= 0.0:
		errors += _fail("hit impact camera 반응 cooldown 누락")
	return errors

func _first_alive_enemy(battle: Node) -> BattleUnit:
	for unit in battle._sim.enemy_units:
		var enemy := unit as BattleUnit
		if enemy != null and enemy.is_alive():
			return enemy
	return null

func _assert_default_speed_fast(battle: Node) -> int:
	var errors := 0
	if not is_equal_approx(float(battle._speed), 3.0):
		errors += _fail("전투 기본 속도 x3 아님: %.1f" % float(battle._speed))
	var found_selected := false
	for entry in battle._speed_buttons:
		var button := entry as Button
		if button != null and button.text == "×3" and button.button_pressed:
			found_selected = true
			break
	if not found_selected:
		errors += _fail("전투 기본 속도 x3 버튼 선택 표시 누락")
	return errors

func _buttons(node: Node) -> Array[Button]:
	var out: Array[Button] = []
	if node is Button:
		out.append(node as Button)
	for child in node.get_children():
		out.append_array(_buttons(child))
	return out

func _count_vfx_meta(node: Node, kind: String) -> int:
	if node == null:
		return 0
	var count := 1 if String(node.get_meta("battle_start_vfx", "")) == kind else 0
	for child in node.get_children():
		count += _count_vfx_meta(child, kind)
	return count

func _count_hit_vfx_meta(node: Node, kind: String) -> int:
	if node == null:
		return 0
	var count := 1 if String(node.get_meta("hit_impact_vfx", "")) == kind else 0
	for child in node.get_children():
		count += _count_hit_vfx_meta(child, kind)
	return count

func _count_bool_meta(node: Node, key: StringName) -> int:
	if node == null:
		return 0
	var count := 1 if bool(node.get_meta(key, false)) else 0
	for child in node.get_children():
		count += _count_bool_meta(child, key)
	return count

func _max_polygon_meta_alpha(node: Node, key: StringName) -> float:
	if node == null:
		return 0.0
	var max_alpha := 0.0
	if bool(node.get_meta(key, false)) and node is Polygon2D:
		max_alpha = maxf(max_alpha, (node as Polygon2D).color.a)
	for child in node.get_children():
		max_alpha = maxf(max_alpha, _max_polygon_meta_alpha(child, key))
	return max_alpha

func _controls(node: Node) -> Array[Control]:
	var out: Array[Control] = []
	if node is Control:
		out.append(node as Control)
	for child in node.get_children():
		out.append_array(_controls(child))
	return out

func _control_text_contains(node: Node, needle: String) -> bool:
	if node is Button and (node as Button).text.find(needle) >= 0:
		return true
	if node is Label and (node as Label).text.find(needle) >= 0:
		return true
	for child in node.get_children():
		if _control_text_contains(child, needle):
			return true
	return false

func _collect_texts(node: Node) -> Array[String]:
	var out: Array[String] = []
	if node is Label:
		out.append((node as Label).text)
	elif node is Button:
		out.append((node as Button).text)
	for child in node.get_children():
		out.append_array(_collect_texts(child))
	return out

func _joined_texts(node: Node) -> String:
	var texts := _collect_texts(node)
	var parts: Array[String] = []
	for text in texts:
		if not text.is_empty():
			parts.append(text)
	return " | ".join(parts)

func _frames(n: int) -> void:
	for _i in n:
		await process_frame

func _fail(msg: String) -> int:
	printerr("  ", msg)
	return 1
