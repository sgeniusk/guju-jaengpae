# 헤드리스 플레이테스트 결과를 작게 요약하는 순수 helper.
class_name PlaytestMetrics
extends RefCounted

const BattleFeel := preload("res://scripts/battle/battle_feel.gd")
const FIRST_FIVE_MAX_COMBAT_TIME := 24.0
const FIRST_FIVE_AVERAGE_COMBAT_TIME := 20.0

static func summarize(stage: int, sim: BattleSim, board: Dictionary, board_levels: Dictionary, hand_size: int, draw_size: int) -> Dictionary:
	var visible_soldiers := 0
	var enemy_visible_soldiers := 0
	var player_units := 0
	if sim != null:
		for unit in sim.player_units:
			if unit == null or unit.is_castle:
				continue
			player_units += 1
			visible_soldiers += BattleFeel.visible_count_for_unit(unit)
		for unit in sim.enemy_units:
			if unit == null:
				continue
			enemy_visible_soldiers += BattleFeel.visible_count_for_unit(unit)
	return {
		"stage": stage,
		"result": sim.result if sim != null else BattleSim.Result.ONGOING,
		"elapsed": sim.elapsed if sim != null else 0.0,
		"board_cards": board.size(),
		"board_levels": _level_sum(board_levels),
		"hand": hand_size,
		"draw": draw_size,
		"player_units": player_units,
		"visible_soldiers": visible_soldiers,
		"enemy_visible_soldiers": enemy_visible_soldiers,
		"total_visible_soldiers": visible_soldiers + enemy_visible_soldiers,
	}

static func compact_line(metrics: Dictionary) -> String:
	return "stage %d result=%d time=%.1fs board=%d lvsum=%d hand=%d draw=%d units=%d soldiers=%d enemy=%d total=%d" % [
		int(metrics.get("stage", 0)),
		int(metrics.get("result", 0)),
		float(metrics.get("elapsed", 0.0)),
		int(metrics.get("board_cards", 0)),
		int(metrics.get("board_levels", 0)),
		int(metrics.get("hand", 0)),
		int(metrics.get("draw", 0)),
		int(metrics.get("player_units", 0)),
		int(metrics.get("visible_soldiers", 0)),
		int(metrics.get("enemy_visible_soldiers", 0)),
		int(metrics.get("total_visible_soldiers", 0)),
	]

static func first_five_ok(metrics_list: Array) -> bool:
	if metrics_list.size() < 3:
		return false
	var saw_density := false
	var elapsed_total := 0.0
	var combat_count := 0
	for metrics in metrics_list:
		if int(metrics.get("result", BattleSim.Result.ONGOING)) != BattleSim.Result.PLAYER_WIN:
			return false
		var elapsed := float(metrics.get("elapsed", 0.0))
		if elapsed <= 0.0 or elapsed > FIRST_FIVE_MAX_COMBAT_TIME:
			return false
		elapsed_total += elapsed
		combat_count += 1
		if int(metrics.get("visible_soldiers", 0)) >= 10:
			saw_density = true
	if combat_count <= 0 or elapsed_total / float(combat_count) > FIRST_FIVE_AVERAGE_COMBAT_TIME:
		return false
	return saw_density

static func _level_sum(levels: Dictionary) -> int:
	var total := 0
	for key in levels.keys():
		total += int(levels[key])
	return total
