extends TestCase

const BattleFeel := preload("res://scripts/battle/battle_feel.gd")

func test_visible_count_counts_squad_not_sim_object() -> void:
	var unit := BattleUnit.make(BattleUnit.Team.ENEMY, 1, BattleSim.FIELD_W, "사령 선봉", 80, 10, 1.0, "melee", 34.0)
	unit.squad_count = 9
	eq(BattleFeel.visible_count_for_unit(unit), 9, "분대 1개는 보이는 병사 수로 환산")
	unit.squad_count = 20
	eq(BattleFeel.visible_count_for_unit(unit), BattleFeel.TROOP_VISIBLE_CAP, "성장 분대 렌더 상한 적용")

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
	eq(BattleFeel.rally_sfx_id(1, wave), &"rally", "교전 시작 함성 cue")

func test_retinue_visible_cap_allows_larger_guard() -> void:
	var unit := BattleUnit.make(BattleUnit.Team.PLAYER, 1, 120.0, "장수", 100, 10, 1.0, "melee", 34.0)
	unit.retinue_count = 13
	eq(BattleFeel.visible_count_for_unit(unit), 1 + BattleFeel.RETINUE_VISIBLE_CAP, "장수 본체+호위 cap")

func test_advance_dust_markers_cover_both_armies_and_lanes() -> void:
	var markers := BattleFeel.advance_dust_markers()
	var side_counts := { "player": 0, "enemy": 0 }
	var lanes := {}
	var player_on_left := true
	var enemy_on_right := true
	for marker in markers:
		var side := String(marker.get("side", ""))
		var field: Vector2 = marker.get("field", Vector2.ZERO)
		lanes[int(marker.get("lane", -1))] = true
		if side_counts.has(side):
			side_counts[side] = int(side_counts[side]) + 1
		if side == "player":
			player_on_left = player_on_left and field.x < 520.0
		elif side == "enemy":
			enemy_on_right = enemy_on_right and field.x > 580.0
	eq(markers.size(), BattleFeel.ADVANCE_DUST_TOTAL, "진군 먼지는 3레인 양쪽 모두 생성")
	eq(side_counts.get("player"), BattleSim.COL_COUNT * BattleFeel.ADVANCE_DUST_PER_SIDE_LANE, "아군 진군 먼지 수")
	eq(side_counts.get("enemy"), BattleSim.COL_COUNT * BattleFeel.ADVANCE_DUST_PER_SIDE_LANE, "적군 진군 먼지 수")
	eq(lanes.size(), BattleSim.COL_COUNT, "진군 먼지는 모든 레인에 분포")
	truthy(player_on_left, "아군 진군 먼지는 아군 진영에서 시작")
	truthy(enemy_on_right, "적군 진군 먼지는 적 진영에서 시작")

func test_ground_clash_markers_anchor_center_lanes() -> void:
	var markers := BattleFeel.ground_clash_markers()
	eq(markers.size(), BattleFeel.GROUND_CLASH_TOTAL, "지면 충돌선은 레인별 1개")
	for lane in BattleSim.COL_COUNT:
		var marker := markers[lane]
		var field: Vector2 = marker.get("field", Vector2.ZERO)
		eq(int(marker.get("lane", -1)), lane, "지면 충돌선 lane 유지")
		almost(field.x, 555.0, 0.001, "지면 충돌선은 중앙 교전선에 고정")
		almost(field.y, BattleSim.start_y_for_col(lane), 0.001, "지면 충돌선은 해당 레인 y에 고정")

func _enemy(lane: int, name: String, squad_count: int, attack_range: String) -> BattleUnit:
	var unit := BattleUnit.make(BattleUnit.Team.ENEMY, lane, BattleSim.FIELD_W, name, 80, 10, 1.0, attack_range, 34.0, &"", &"", "infantry", -1, BattleSim.start_y_for_col(lane))
	unit.squad_count = squad_count
	return unit
