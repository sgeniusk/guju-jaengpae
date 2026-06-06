# 런 종료 화면에 표시할 결산 문구를 순수 계산한다.
class_name RunResultSummary
extends RefCounted

static func for_state(state: RunState, outcome: Dictionary, catalog: CardCatalog = null) -> Dictionary:
	var run_result := String(outcome.get("run_result", "ongoing"))
	var stage := int(outcome.get("stage", _state_stage(state)))
	var score := int(outcome.get("score", 0))
	var board_count := _board_count(state)
	var capacity := _board_capacity(state)
	var max_level := _max_board_level(state)
	var edict_count := _edict_count(state)
	var treasure_count := _treasure_count(state)
	var hand_count := _hand_count(state)
	var draw_count := _draw_count(state)
	var gold := _gold(state)
	var lord_name := _lord_name(state, catalog)
	var title := _title_for_result(run_result)
	var detail := "스테이지 %d · 점수 %d · 군세 %d/%d · 최고 Lv.%d · 골드 %d" % [
		stage,
		score,
		board_count,
		capacity,
		max_level,
		gold,
	]
	var progress := "칙령 %d개 · 보패 %d개 · 손패 %d장 · 드로우 %d장" % [
		edict_count,
		treasure_count,
		hand_count,
		draw_count,
	]
	var tooltip := "%s\n군주 %s\n%s\n%s" % [
		title,
		lord_name,
		detail,
		progress,
	]
	return {
		"title": title,
		"detail": detail,
		"progress": progress,
		"tooltip": tooltip,
		"run_result": run_result,
		"stage": stage,
		"score": score,
		"board_count": board_count,
		"capacity": capacity,
		"max_level": max_level,
		"edicts": edict_count,
		"treasures": treasure_count,
		"hand": hand_count,
		"draw": draw_count,
		"gold": gold,
		"lord": lord_name,
	}

static func _title_for_result(run_result: String) -> String:
	match run_result:
		"victory":
			return "런 결산 — 승리"
		"defeat":
			return "런 결산 — 패배"
		_:
			return "런 결산 — 진행 중"

static func _state_stage(state: RunState) -> int:
	return state.stage_index if state != null else 0

static func _board_count(state: RunState) -> int:
	return state.board.size() if state != null else 0

static func _board_capacity(state: RunState) -> int:
	return state.board_capacity() if state != null else 0

static func _max_board_level(state: RunState) -> int:
	if state == null:
		return 0
	var best := 0
	for key in state.board.keys():
		best = maxi(best, state.board_level(String(key)))
	return best

static func _edict_count(state: RunState) -> int:
	return state.edicts.size() if state != null else 0

static func _treasure_count(state: RunState) -> int:
	return state.treasures.size() if state != null else 0

static func _hand_count(state: RunState) -> int:
	return state.hand.size() if state != null else 0

static func _draw_count(state: RunState) -> int:
	return state.draw_pile.size() if state != null else 0

static func _gold(state: RunState) -> int:
	return state.gold if state != null else 0

static func _lord_name(state: RunState, catalog: CardCatalog) -> String:
	if state == null:
		return "미상"
	if catalog == null:
		return String(state.lord_id)
	var lord := catalog.get_lord(state.lord_id)
	return lord.display_name if lord != null else String(state.lord_id)
