# 집중표적 입력 피드백의 순수 문구와 선택 반경을 검증한다.
extends TestCase

const BattleCommandFeedback := preload("res://scripts/battle/battle_command_feedback.gd")

func test_nearest_enemy_to_field_uses_radius_and_ignores_dead() -> void:
	var dead := _enemy(140.0, 300.0, "죽은 표적")
	dead.take_damage(100)
	var near := _enemy(170.0, 300.0, "가까운 표적")
	var far := _enemy(260.0, 300.0, "먼 표적")
	var picked := BattleCommandFeedback.nearest_enemy_to_field(Vector2(160.0, 300.0), [dead, far, near], 70.0)
	eq(picked, near, "반경 안 생존 적 중 최근접 선택")
	eq(BattleCommandFeedback.nearest_enemy_to_field(Vector2(10.0, 10.0), [near], 5.0), null, "반경 밖 적은 선택하지 않음")

func test_nearest_enemy_to_field_rejects_out_of_field_clicks() -> void:
	var enemy := _enemy(120.0, 300.0, "표적")
	eq(BattleCommandFeedback.nearest_enemy_to_field(Vector2(-1.0, 300.0), [enemy], 200.0), null, "필드 밖 x 클릭 무시")
	eq(BattleCommandFeedback.nearest_enemy_to_field(Vector2(120.0, BattleSim.FIELD_H + 1.0), [enemy], 200.0), null, "필드 밖 y 클릭 무시")

func test_command_texts_include_target_and_hero_count() -> void:
	var enemy := _enemy(180.0, 300.0, "마군 선봉")
	eq(BattleCommandFeedback.command_hint(enemy, 2), "집중 표적 — 마군 선봉 · 장수 2명 집중", "힌트에 표적명과 장수 수 표시")
	eq(BattleCommandFeedback.marker_text(2), "집중\n2", "표적 마커는 짧은 2줄 라벨")
	truthy(BattleCommandFeedback.command_banner(enemy, 2).find("마군 선봉") >= 0, "배너에 표적명 표시")

func test_focus_button_tooltip_reflects_battle_state() -> void:
	var enemy := _enemy(180.0, 300.0, "마군 선봉")
	truthy(BattleCommandFeedback.focus_button_tooltip(false, false, null, 1).find("전투 중") >= 0, "비전투 tooltip")
	truthy(BattleCommandFeedback.focus_button_tooltip(true, false, null, 2).find("장수 2명") >= 0, "비활성 전투 tooltip")
	truthy(BattleCommandFeedback.focus_button_tooltip(true, true, enemy, 2).find("현재 마군 선봉") >= 0, "활성 tooltip 현재 표적")
	truthy(BattleCommandFeedback.focus_button_tooltip(true, true, null, 0).find("지휘할 장수") >= 0, "장수 없음 tooltip")

func test_controllable_hero_count_only_counts_alive_controllable_units() -> void:
	var hero := _unit(BattleUnit.Team.PLAYER, 100.0, 300.0, "장수", true)
	var dead_hero := _unit(BattleUnit.Team.PLAYER, 120.0, 300.0, "쓰러진 장수", true)
	dead_hero.take_damage(100)
	var troop := _unit(BattleUnit.Team.PLAYER, 140.0, 300.0, "병종", false)
	eq(BattleCommandFeedback.controllable_hero_count([hero, dead_hero, troop]), 1, "생존 장수만 집계")

func _enemy(px: float, py: float, display_name: String) -> BattleUnit:
	return _unit(BattleUnit.Team.ENEMY, px, py, display_name, false)

func _unit(team: int, px: float, py: float, display_name: String, controllable: bool) -> BattleUnit:
	var unit := BattleUnit.make(team, 0, px, display_name, 100, 10, 1.0, "melee", 0.0, &"", &"", "infantry", -1, py)
	unit.controllable = controllable
	return unit
