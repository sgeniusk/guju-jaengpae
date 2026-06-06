extends TestCase

const PlaytestMetrics := preload("res://scripts/run/playtest_metrics.gd")

var cat: CardCatalog
var lord: LordData

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()
	lord = cat.get_lord(&"lord_liubei")

func test_mvp_loop_requires_castle_then_one_card() -> void:
	CardLibrary.catalog.load_all()
	RunManager.reset_run()
	RunManager.ensure_started(&"lord_liubei")
	eq(RunManager.get_hand().size(), RunState.HAND_DRAW_COUNT, "전투 전 선택지는 3장")
	truthy(RunManager.get_hand().has(&"troop_infantry") or RunManager.get_hand().has(&"troop_archer"), "첫 손패부터 병사 분대 선택지가 있음")
	falsy(RunManager.place_from_hand(0, "0:0"), "성 위치 전에는 카드 플레이 불가")
	truthy(RunManager.set_castle_key("1:1"), "성 위치 먼저 선택")
	truthy(RunManager.place_from_hand(0, "0:0"), "성 이후 한 장 플레이")
	falsy(RunManager.place_from_hand(0, "2:0"), "같은 교전에서 두 번째 카드 플레이 불가")
	falsy(RunManager.discard_from_hand(0), "우물도 같은 교전의 두 번째 손패 행동으로는 불가")

func test_well_is_a_castle_gated_one_card_action() -> void:
	CardLibrary.catalog.load_all()
	RunManager.reset_run()
	RunManager.state.hand_add(&"troop_archer")
	RunManager.state.hand_add(&"scheme_raid")
	falsy(RunManager.discard_from_hand(0), "성 전 우물 불가")
	truthy(RunManager.set_castle_key("1:1"), "성 위치 선택")
	falsy(RunManager.discard_from_hand(0), "보드 군세 전 우물 불가")
	truthy(RunManager.place_from_hand(0, "1:0"), "전투할 군세 배치")
	RunManager.state.deploy_cards_played = 0
	truthy(RunManager.discard_from_hand(0), "보드 군세가 있으면 우물이 한 수로 가능")
	eq(RunManager.get_gold(), RunState.WELL_GOLD, "우물 골드 지급")
	falsy(RunManager.can_place_deploy_card(), "우물도 이번 교전 한 장 행동으로 계산")

func test_duplicate_unit_card_becomes_reinforcement_not_extra_slot() -> void:
	CardLibrary.catalog.load_all()
	RunManager.reset_run()
	RunManager.state.hand_add(&"troop_archer")
	RunManager.state.hand_add(&"troop_archer")
	truthy(RunManager.set_castle_key("1:1"), "성 위치 선택")
	truthy(RunManager.place_from_hand(0, "0:0"), "궁병 배치")
	RunManager.state.deploy_cards_played = 0
	truthy(RunManager.place_from_hand(0, "2:0"), "중복 궁병은 증원으로 소비")
	eq(RunManager.get_board().size(), 1, "증원은 새 칸을 차지하지 않음")
	eq(RunManager.get_board_level("0:0"), 2, "기존 궁병 Lv.2")

func test_first_encounter_has_visible_squad_density_and_fast_result() -> void:
	var run := RunState.new()
	run.start_run(lord, cat)
	truthy(run.set_castle_key("1:1"), "성 위치")
	truthy(run.place_from_hand(0, "0:0"), "첫 장수 배치")
	run.hand_add(&"troop_archer")
	truthy(run.place_from_hand(run.hand.size() - 1, "2:0"), "밀도 확인용 궁병 배치")
	var sim := BattleSim.new()
	var castle_pos := BattleSim.position_for_tile(1, 1)
	sim.add_castle_at(castle_pos.x, castle_pos.y)
	var army := cat.build_board_army(run.board, lord, run.board_rows, run.edicts, run.castle_key, run.terrain_perk_id, run.board_levels_copy())
	for unit in army:
		sim.add_unit(unit)
	sim.set_waves(WaveFactory.stage_encounter_waves(1))
	var result := sim.run_to_completion(0.1, 35.0)
	var metrics := PlaytestMetrics.summarize(1, sim, run.board, run.board_levels_copy(), run.hand.size(), run.draw_pile.size())
	eq(result, BattleSim.Result.PLAYER_WIN, "첫 교전 승리")
	truthy(float(metrics.get("elapsed", 0.0)) <= 25.0, "초반 교전은 25초 안에 끝")
	truthy(int(metrics.get("visible_soldiers", 0)) >= 20, "장수 호위+병종 분대로 군세 밀도 확보")

func test_first_five_metrics_enforce_tempo_budget() -> void:
	var fast_metrics := [
		{"result": BattleSim.Result.PLAYER_WIN, "elapsed": 21.0, "visible_soldiers": 12, "enemy_visible_soldiers": 25, "total_visible_soldiers": 37},
		{"result": BattleSim.Result.PLAYER_WIN, "elapsed": 18.0, "visible_soldiers": 20, "enemy_visible_soldiers": 16, "total_visible_soldiers": 36},
		{"result": BattleSim.Result.PLAYER_WIN, "elapsed": 14.0, "visible_soldiers": 32, "enemy_visible_soldiers": 10, "total_visible_soldiers": 42},
	]
	truthy(PlaytestMetrics.first_five_ok(fast_metrics), "빠른 첫 5스테이지 메트릭 통과")
	var slow_stage := [
		{"result": BattleSim.Result.PLAYER_WIN, "elapsed": PlaytestMetrics.FIRST_FIVE_MAX_COMBAT_TIME + 0.1, "visible_soldiers": 12, "total_visible_soldiers": 37},
		{"result": BattleSim.Result.PLAYER_WIN, "elapsed": 18.0, "visible_soldiers": 20, "total_visible_soldiers": 36},
		{"result": BattleSim.Result.PLAYER_WIN, "elapsed": 14.0, "visible_soldiers": 32, "total_visible_soldiers": 42},
	]
	falsy(PlaytestMetrics.first_five_ok(slow_stage), "개별 전투가 예산을 넘으면 실패")
	var slow_average := [
		{"result": BattleSim.Result.PLAYER_WIN, "elapsed": 19.5, "visible_soldiers": 12, "total_visible_soldiers": 37},
		{"result": BattleSim.Result.PLAYER_WIN, "elapsed": 19.5, "visible_soldiers": 20, "total_visible_soldiers": 36},
		{"result": BattleSim.Result.PLAYER_WIN, "elapsed": 19.5, "visible_soldiers": 32, "total_visible_soldiers": 42},
	]
	falsy(PlaytestMetrics.first_five_ok(slow_average), "평균 전투 시간이 예산을 넘으면 실패")
	var thin_first := [
		{"result": BattleSim.Result.PLAYER_WIN, "elapsed": 21.0, "visible_soldiers": PlaytestMetrics.FIRST_FIVE_MIN_PLAYER_SOLDIERS - 1, "total_visible_soldiers": 36},
		{"result": BattleSim.Result.PLAYER_WIN, "elapsed": 18.0, "visible_soldiers": 20, "total_visible_soldiers": 36},
		{"result": BattleSim.Result.PLAYER_WIN, "elapsed": 14.0, "visible_soldiers": 32, "total_visible_soldiers": 42},
	]
	falsy(PlaytestMetrics.first_five_ok(thin_first), "매 교전 최소 아군 군세가 부족하면 실패")
	var no_peak := [
		{"result": BattleSim.Result.PLAYER_WIN, "elapsed": 21.0, "visible_soldiers": 12, "total_visible_soldiers": 37},
		{"result": BattleSim.Result.PLAYER_WIN, "elapsed": 18.0, "visible_soldiers": 20, "total_visible_soldiers": 36},
		{"result": BattleSim.Result.PLAYER_WIN, "elapsed": 14.0, "visible_soldiers": PlaytestMetrics.FIRST_FIVE_PEAK_PLAYER_SOLDIERS - 1, "total_visible_soldiers": 42},
	]
	falsy(PlaytestMetrics.first_five_ok(no_peak), "초반 피크 군세가 부족하면 실패")

func test_card_ui_action_label_explains_player_intent() -> void:
	var troop := cat.get_card(&"troop_archer")
	var building := cat.get_card(&"building_mangru")
	var scheme := cat.get_card(&"scheme_raid")
	truthy(CardUiText.deploy_action_label(troop, false).contains("배치"), "새 병종은 배치 라벨")
	truthy(CardUiText.deploy_action_label(troop, true).contains("증원"), "중복 병종은 증원 라벨")
	truthy(CardUiText.deploy_action_label(building, false).contains("건물"), "건물 라벨")
	truthy(CardUiText.deploy_action_label(scheme, false).contains("계략"), "계략 라벨")
