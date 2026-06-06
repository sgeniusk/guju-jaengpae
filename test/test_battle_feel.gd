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

func test_clash_profile_scales_with_visible_force() -> void:
	var player := [
		_player(0, "보병", 12, "melee"),
		_player(1, "궁병", 12, "ranged"),
	]
	var enemy := [
		_enemy(0, "사령병", 9, "melee"),
		_enemy(1, "사령 선봉", 9, "melee"),
		_enemy(2, "요사 궁수", 7, "ranged"),
	]
	var profile := BattleFeel.clash_profile(player, enemy)
	eq(profile.get("player_visible"), 24, "아군 visible soldiers 집계")
	eq(profile.get("enemy_visible"), 25, "적군 visible soldiers 집계")
	eq(profile.get("total_visible"), 49, "양측 군세 총합")
	eq(profile.get("lanes"), 3, "충돌 레인 수")
	truthy(float(profile.get("intensity", 0.0)) > 0.65, "군세가 많으면 충돌 강도 상승")
	truthy(int(profile.get("pressure_count", 0)) > BattleFeel.CLASH_PRESSURE_MIN, "군세가 많으면 pressure marker 증가")
	truthy(BattleFeel.rally_line(1, player, enemy).contains("아군 24 · 적 25"), "rally line에 양측 군세 표시")

func test_clash_pressure_markers_follow_profile_count_and_lanes() -> void:
	var profile := {
		"intensity": 0.90,
		"pressure_count": 12,
	}
	var markers := BattleFeel.clash_pressure_markers(profile)
	var lanes := {}
	eq(markers.size(), 12, "pressure marker 수는 profile 계약을 따른다")
	for marker in markers:
		var field: Vector2 = marker.get("field", Vector2.ZERO)
		var lane := int(marker.get("lane", -1))
		lanes[lane] = true
		truthy(field.x >= 520.0 and field.x <= 590.0, "pressure marker는 중앙 충돌선 주변")
		truthy(float(marker.get("radius_x", 0.0)) > 30.0, "강한 충돌은 넓은 pressure 반경")
		truthy(float(marker.get("alpha", 0.0)) > 0.35, "강한 충돌은 더 진한 pressure")
	eq(lanes.size(), BattleSim.COL_COUNT, "pressure marker는 모든 레인에 분포")

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

func _player(lane: int, name: String, squad_count: int, attack_range: String) -> BattleUnit:
	var unit := BattleUnit.make(BattleUnit.Team.PLAYER, lane, 120.0, name, 80, 10, 1.0, attack_range, 34.0, &"", &"", "infantry", -1, BattleSim.start_y_for_col(lane))
	unit.squad_count = squad_count
	return unit
