# 전투 HUD 표시용 순수 계산을 검증한다.
extends TestCase

const _HudState := preload("res://scripts/battle/hud_state.gd")
const _StageCadence := preload("res://scripts/run/stage_cadence.gd")

func test_stage_node_kind_prioritizes_boss_over_shop_and_expand() -> void:
	eq(_StageCadence.node_kind(1), "combat", "1스테이지는 전투")
	eq(_StageCadence.node_kind(4), "shop", "4스테이지는 상점")
	eq(_StageCadence.node_kind(5), "boss", "5스테이지는 보스")
	eq(_StageCadence.node_kind(7), "elite", "7스테이지는 정예")
	eq(_StageCadence.node_kind(11), "event", "11스테이지는 사건")
	eq(_StageCadence.node_kind(10), "boss", "보스와 확장이 겹치면 보스가 우선")
	eq(_StageCadence.node_kind(20), "boss", "보스와 상점이 겹치면 보스가 우선")
	eq(_StageCadence.node_kind(21), "edict", "칙령과 정예가 겹치면 칙령이 우선")

func test_stage_nodes_span_current_plus_six_with_year_flavor() -> void:
	var nodes := _HudState.stage_nodes(3)
	eq(nodes.size(), 7, "현재 포함 7개 노드")
	eq(nodes[0]["stage"], 3, "첫 노드는 현재 스테이지")
	truthy(nodes[0]["is_current"], "첫 노드 현재 하이라이트")
	eq(nodes[0]["label"], "35년", "32 + stage 연도")
	eq(nodes[1]["kind"], "shop", "4스테이지는 상점 노드")
	eq(nodes[2]["kind"], "boss", "5스테이지는 보스 노드")
	eq(nodes[4]["kind"], "elite", "7스테이지는 정예 노드")
	eq(nodes[4]["icon"], "정", "정예 아이콘")
	eq(nodes[6]["stage"], 9, "현재+6까지 표시")

	var later_nodes := _HudState.stage_nodes(7)
	eq(later_nodes[0]["kind"], "elite", "현재 정예 노드")
	eq(later_nodes[4]["kind"], "event", "11스테이지는 사건 노드")
	eq(later_nodes[4]["icon"], "?", "사건 아이콘")

func test_stage_ladder_node_kinds_have_texture_icons() -> void:
	for kind in ["combat", "shop", "boss", "expand", "edict", "elite", "event"]:
		var path := "res://assets/sprites/ui/node_%s.png" % kind
		truthy(ResourceLoader.exists(path), "%s 노드 아이콘 에셋 존재" % kind)

func test_speed_delta_applies_multiplier_only_while_running_battle() -> void:
	almost(_HudState.speed_delta(0.5, 1.0, false, true), 0.5, 0.0001, "1배속")
	almost(_HudState.speed_delta(0.5, 3.0, false, true), 1.5, 0.0001, "3배속")
	almost(_HudState.speed_delta(0.5, 2.0, true, true), 0.0, 0.0001, "일시정지")
	almost(_HudState.speed_delta(0.5, 2.0, false, false), 0.0, 0.0001, "전투 밖")

func test_bottom_bar_ratios_track_castle_champion_and_enemy_force() -> void:
	var castle := BattleUnit.make_castle(40.0, 300.0, 1000, "성")
	castle.take_damage(250)
	almost(_HudState.castle_ratio(castle), 0.75, 0.0001, "성 HP 비율")

	var boss := BattleUnit.make(BattleUnit.Team.ENEMY, 1, 1000.0, "마왕 동탁", 2000, 40, 1.0, "melee", 30.0)
	var minion := BattleUnit.make(BattleUnit.Team.ENEMY, 0, 1000.0, "사령병", 100, 10, 1.0, "melee", 30.0)
	boss.take_damage(500)
	var champion := _HudState.champion_state([minion, boss])
	truthy(champion["active"], "보스가 있으면 챔피언 바 활성")
	eq(champion["label"], "마왕 동탁", "마왕 동탁 우선")
	almost(champion["ratio"], 0.75, 0.0001, "챔피언 HP 비율")

	var lubu := BattleUnit.make(BattleUnit.Team.ENEMY, 1, 1000.0, "귀신 여포", 1800, 60, 1.0, "melee", 30.0)
	var giant := BattleUnit.make(BattleUnit.Team.ENEMY, 0, 1000.0, "마군 정예", 3000, 20, 1.0, "melee", 30.0)
	var later_boss := _HudState.champion_state([giant, lubu])
	eq(later_boss["label"], "귀신 여포", "등록된 후속 보스는 더 큰 미니언보다 우선")

	var empty := _HudState.champion_state([])
	falsy(empty["active"], "적이 없으면 챔피언 바 비활성")
	almost(_HudState.enemy_force_ratio(3, 6, 1, 3), 0.5, 0.0001, "현재 적 수 / 최대 관측 적 수")
	almost(_HudState.enemy_force_ratio(0, 0, 2, 4), 0.75, 0.0001, "최대값 전에는 파도 진행 폴백")

func test_combat_summary_compacts_phase_wave_force_and_speed() -> void:
	var deploy := _HudState.combat_summary("deploy", 1, 0, 0, 0, 0, 3.0, false, false)
	truthy(String(deploy.get("text")).contains("전황 — 배치 준비"), "배치 단계")
	truthy(String(deploy.get("text")).contains("1스테이지"), "stage 표시")
	truthy(String(deploy.get("text")).contains("×3"), "속도 표시")
	truthy(String(deploy.get("tooltip")).contains("병력 수 기준"), "병력 기준 tooltip")

	var battle := _HudState.combat_summary("battle", 5, 2, 3, 32, 17, 2.0, true, true)
	truthy(String(battle.get("text")).contains("전황 — 교전"), "교전 단계")
	truthy(String(battle.get("text")).contains("파도 2/3"), "파도 표시")
	truthy(String(battle.get("text")).contains("아군 32"), "아군 표시")
	truthy(String(battle.get("text")).contains("적 17"), "적 표시")
	truthy(String(battle.get("text")).contains("정지"), "일시정지 표시")
	truthy(String(battle.get("text")).contains("auto"), "auto 표시")
