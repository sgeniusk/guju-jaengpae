# 집중표적 명령의 선택 반경과 화면 문구를 계산하는 순수 helper.
class_name BattleCommandFeedback
extends RefCounted

const DEFAULT_PICK_RADIUS := 70.0

static func controllable_hero_count(units: Array) -> int:
	var count := 0
	for entry in units:
		var unit := entry as BattleUnit
		if unit != null and unit.is_alive() and unit.controllable:
			count += 1
	return count

static func nearest_enemy_to_field(field_pos: Vector2, enemies: Array, radius: float = DEFAULT_PICK_RADIUS) -> BattleUnit:
	if field_pos.x < 0.0 or field_pos.x > BattleSim.FIELD_W or field_pos.y < 0.0 or field_pos.y > BattleSim.FIELD_H:
		return null
	var best: BattleUnit = null
	var best_distance := maxf(0.0, radius)
	for entry in enemies:
		var enemy := entry as BattleUnit
		if enemy == null or not enemy.is_alive():
			continue
		var distance := enemy.position().distance_to(field_pos)
		if distance <= best_distance:
			best_distance = distance
			best = enemy
	return best

static func command_hint(target: BattleUnit, hero_count: int) -> String:
	if target == null:
		return no_target_hint()
	return "집중 표적 — %s · 장수 %d명 집중" % [target.display_name, maxi(0, hero_count)]

static func command_banner(target: BattleUnit, hero_count: int) -> String:
	if target == null:
		return "집중 표적"
	return "집중 표적\n%s · 장수 %d명" % [target.display_name, maxi(0, hero_count)]

static func marker_text(hero_count: int) -> String:
	return "집중\n%d" % maxi(0, hero_count)

static func no_target_hint() -> String:
	return "집중표적 — 범위 안 적 없음. 자동 표적"

static func no_heroes_hint() -> String:
	return "집중표적 — 지휘할 장수가 없습니다."

static func manual_clear_hint() -> String:
	return "집중표적 해제 — 자동 표적"

static func defeated_target_hint(target_name: String) -> String:
	if target_name.is_empty():
		return "집중 표적 격파 — 자동 표적"
	return "집중 표적 격파 — %s, 자동 표적" % target_name

static func focus_button_tooltip(in_battle: bool, active: bool, target: BattleUnit, hero_count: int) -> String:
	if not in_battle:
		return "집중표적 — 전투 중 적을 클릭해 장수들의 표적을 지정합니다."
	if hero_count <= 0:
		return "집중표적 — 현재 지휘할 장수가 없습니다."
	if active and target != null and target.is_alive():
		return "집중표적 — 현재 %s. 다른 적을 클릭해 변경하고 빈 곳 클릭으로 해제합니다. 장수 %d명 집중." % [target.display_name, hero_count]
	if active:
		return "집중표적 — 적을 클릭해 장수 %d명의 표적을 지정합니다. 빈 곳 클릭으로 해제합니다." % hero_count
	return "집중표적 — 켜면 적 클릭으로 장수 %d명의 표적을 지정합니다." % hero_count
