extends TestCase

const BattleFeel := preload("res://scripts/battle/battle_feel.gd")

func test_visible_count_counts_squad_not_sim_object() -> void:
	var unit := BattleUnit.make(BattleUnit.Team.ENEMY, 1, BattleSim.FIELD_W, "사령 선봉", 80, 10, 1.0, "melee", 34.0)
	unit.squad_count = 9
	eq(BattleFeel.visible_count_for_unit(unit), 9, "분대 1개는 보이는 병사 수로 환산")
	unit.squad_count = 20
	eq(BattleFeel.visible_count_for_unit(unit), 14, "가독성을 위해 렌더 상한 적용")

func test_force_metrics_tracks_lanes_and_visible_soldiers() -> void:
	var units := [
		_enemy(0, "사령병", 9, "melee"),
		_enemy(1, "사령 선봉", 9, "melee"),
		_enemy(2, "요사 궁수", 7, "ranged"),
	]
	var metrics := BattleFeel.force_metrics(units)
	eq(metrics.get("units"), 3, "세 분대")
	eq(metrics.get("lanes"), 3, "세 전열")
	eq(metrics.get("visible_soldiers"), 25, "적도 군세 밀도에 집계")
	truthy(bool(metrics.get("has_ranged", false)), "원거리 분대 포함")
	truthy(BattleFeel.has_army_front(units), "초반 전투 전열 계약 충족")

func test_stage_one_encounter_has_enemy_front() -> void:
	var wave: Array = WaveFactory.stage_encounter_waves(1)[0]
	truthy(BattleFeel.has_army_front(wave), "첫 전투부터 적 전열이 보임")
	eq(BattleFeel.rally_text(1, wave), "전군 돌격!", "첫 전투 rally")

func _enemy(lane: int, name: String, squad_count: int, attack_range: String) -> BattleUnit:
	var unit := BattleUnit.make(BattleUnit.Team.ENEMY, lane, BattleSim.FIELD_W, name, 80, 10, 1.0, attack_range, 34.0, &"", &"", "infantry", -1, BattleSim.start_y_for_col(lane))
	unit.squad_count = squad_count
	return unit
