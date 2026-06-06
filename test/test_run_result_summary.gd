extends TestCase

const _RunResultSummary := preload("res://scripts/run/run_result_summary.gd")

func test_victory_summary_reports_run_shape() -> void:
	var state := RunState.new()
	state.lord_id = &"lord_liubei"
	state.stage_index = 15
	state.board_rows = RunState.BOARD_ROWS_MAX
	state.board = {
		"0:0": &"general_guanyu",
		"1:0": &"troop_archer",
	}
	state.board_levels = {
		"0:0": 3,
		"1:0": 2,
	}
	state.edicts = [&"edict_mandate", &"edict_water"]
	state.treasures = [&"treasure_test"]
	state.hand = [&"troop_infantry"]
	state.draw_pile = [&"troop_cavalry", &"general_zhangfei"]
	state.gold = 42
	var summary := _RunResultSummary.for_state(state, {
		"run_result": "victory",
		"stage": 15,
		"score": 2048,
	}, CardLibrary.catalog)

	eq(summary.get("title"), "런 결산 — 승리", "승리 제목")
	eq(summary.get("max_level"), 3, "최고 레벨")
	eq(summary.get("board_count"), 2, "군세 수")
	eq(summary.get("capacity"), 18, "최대 보드 칸")
	truthy(String(summary.get("detail")).contains("스테이지 15"), "스테이지 문구")
	truthy(String(summary.get("detail")).contains("점수 2048"), "점수 문구")
	truthy(String(summary.get("detail")).contains("군세 2/18"), "군세 문구")
	truthy(String(summary.get("detail")).contains("최고 Lv.3"), "최고 레벨 문구")
	truthy(String(summary.get("progress")).contains("칙령 2개"), "칙령 문구")
	truthy(String(summary.get("progress")).contains("보패 1개"), "보패 문구")
	truthy(String(summary.get("tooltip")).contains("유비"), "군주명 tooltip")

func test_defeat_summary_uses_defeat_title() -> void:
	var state := RunState.new()
	state.stage_index = 7
	state.board = { "0:0": &"troop_infantry" }
	state.board_levels = { "0:0": 1 }
	var summary := _RunResultSummary.for_state(state, {
		"run_result": "defeat",
		"stage": 7,
		"score": 710,
	})

	eq(summary.get("title"), "런 결산 — 패배", "패배 제목")
	truthy(String(summary.get("detail")).contains("스테이지 7"), "패배 스테이지")
	truthy(String(summary.get("detail")).contains("군세 1/9"), "초기 보드 용량")
