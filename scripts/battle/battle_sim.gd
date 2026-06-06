# 오픈필드 2D 오토배틀의 순수 시뮬레이션. 렌더링 없이 step(delta)로 진행되며 결정적이다.
class_name BattleSim
extends RefCounted

enum Result { ONGOING, PLAYER_WIN, PLAYER_LOSE }

const COL_COUNT := 3
const ROW_COUNT := 6
const LANE_COUNT := COL_COUNT
const FIELD_W := 1000.0
const FIELD_H := 600.0
const LANE_LENGTH := FIELD_W
const CASTLE_X := 40.0
const CASTLE_HP := 1200
# row 0~2 = 기본 진형(성 앞 360~120), row 3~5 = 확장 행(480~720, 적 쪽 전방). 성 공간(x40~120)이 좁아 후방 증설은 타일이 겹쳐 불가 → 확장 = 전열 전진(공세) 의도(feat-020).
const ROW_X := [360.0, 240.0, 120.0, 480.0, 600.0, 720.0]
const COL_Y := [150.0, 300.0, 450.0]
const MELEE_REACH := 48.0
const RANGED_REACH := 340.0
const _SkillSystem := preload("res://scripts/battle/skill_system.gd")
const _TargetRules := preload("res://scripts/battle/target_rules.gd")

var player_units: Array[BattleUnit] = []
var enemy_units: Array[BattleUnit] = []
var pending_waves: Array = []
var wave_index := 0
var wave_total := 0
var result: int = Result.ONGOING
var elapsed: float = 0.0
var last_skill_casts: Array = []
var last_damage_events: Array = []
var castle: BattleUnit = null

static func depth_for_row(row: int) -> float:
	return start_x_for_row(row)

static func start_x_for_row(row: int) -> float:
	return ROW_X[clampi(row, 0, ROW_COUNT - 1)]

static func start_y_for_col(col: int) -> float:
	return COL_Y[clampi(col, 0, COL_COUNT - 1)]

static func position_for_tile(col: int, row: int) -> Vector2:
	return Vector2(start_x_for_row(row), start_y_for_col(col))

static func castle_position() -> Vector2:
	return Vector2(CASTLE_X, FIELD_H * 0.5)

func add_castle(hp: int = CASTLE_HP, display_name: String = "성") -> BattleUnit:
	if castle != null and castle.is_alive():
		return castle
	var p := castle_position()
	return add_castle_at(p.x, p.y, hp, display_name)

func add_castle_at(px: float, py: float, hp: int = CASTLE_HP, display_name: String = "성") -> BattleUnit:
	if castle != null and castle.is_alive():
		return castle
	var u := BattleUnit.make_castle(px, py, hp, display_name)
	add_unit(u)
	return u

func add_unit(u: BattleUnit) -> void:
	if u == null:
		return
	if u.is_castle:
		if castle != null and castle != u:
			player_units.erase(castle)
		u.team = BattleUnit.Team.PLAYER
		castle = u
	u.set_position(clampf(u.px, 0.0, FIELD_W), clampf(u.py, 0.0, FIELD_H))
	if _SkillSystem.has_skill(u.skill_id):
		u.skill_cooldown = _SkillSystem.cooldown_for(u.skill_id)
	if u.team == BattleUnit.Team.PLAYER:
		player_units.append(u)
	else:
		enemy_units.append(u)

func set_waves(waves: Array) -> void:
	pending_waves = waves.duplicate()
	wave_total = pending_waves.size()
	wave_index = 0
	result = Result.ONGOING
	if not pending_waves.is_empty():
		_spawn_next_wave()

func is_over() -> bool:
	return result != Result.ONGOING

func step(delta: float) -> void:
	last_skill_casts.clear()
	last_damage_events.clear()
	if is_over():
		return
	elapsed += delta
	for u in player_units + enemy_units:
		if u.is_alive():
			u.tick_statuses(delta)
	# player + enemy를 한 번에 순회(안정적 순서 → 결정적)
	for u in player_units + enemy_units:
		if not u.is_alive():
			continue
		if u.is_castle:
			continue
		_process_skill(u, delta)
		if u.cooldown > 0.0:
			u.cooldown -= delta
		var target := _pick_target(u)
		if target != null and u.distance_to(target) <= _reach_of(u):
			if u.cooldown <= 0.0:
				var type_multiplier := TypeChart.multiplier(u.troop_type, target.troop_type)
				var dmg := int(round(u.effective_attack() * type_multiplier))
				target.take_damage(dmg)
				last_damage_events.append({
					"attacker": u,
					"attacker_team": u.team,
					"attacker_px": u.px,
					"attacker_py": u.py,
					"attack_range": u.attack_range,
					"target": target,
					"amount": dmg,
					"px": target.px,
					"py": target.py,
					"team": target.team,
					"is_crit": type_multiplier >= 1.5,
					"kind": "attack",
				})
				u.cooldown = u.attack_interval
		else:
			_move_toward(u, target, delta)
	_cleanup_dead()
	_update_result()

func apply_battle_effect(effect: Dictionary) -> Dictionary:
	var applied := {
		"castle_hp_delta": 0,
		"damage_enemy": 0,
		"target": null,
	}
	var castle_delta := maxi(0, int(effect.get("castle_hp_delta", 0)))
	if castle_delta > 0 and castle != null and castle.is_alive():
		castle.max_hp = maxi(1, castle.max_hp + castle_delta)
		castle.hp = mini(castle.max_hp, castle.hp + castle_delta)
		applied["castle_hp_delta"] = castle_delta
	var damage: Dictionary = effect.get("damage_enemy", {})
	var damage_amount := maxi(0, int(damage.get("amount", 0)))
	var target := _first_alive_enemy()
	if damage_amount > 0 and target != null:
		target.take_damage(damage_amount)
		last_damage_events.append({
			"target": target,
			"amount": damage_amount,
			"px": target.px,
			"py": target.py,
			"team": target.team,
			"is_crit": false,
			"kind": "scheme",
		})
		applied["damage_enemy"] = damage_amount
		applied["target"] = target
		_cleanup_dead()
		_update_result()
	return applied

func run_to_completion(dt: float = 0.1, max_time: float = 120.0) -> int:
	var t := 0.0
	while not is_over() and t < max_time:
		step(dt)
		t += dt
	return result

func _spawn_next_wave() -> void:
	if pending_waves.is_empty():
		return
	var next_wave: Array = pending_waves.pop_front()
	for u in next_wave:
		add_unit(u)
	wave_index += 1

func _first_alive_enemy() -> BattleUnit:
	for enemy in enemy_units:
		if enemy != null and enemy.is_alive():
			return enemy
	return null

func _reach_of(u: BattleUnit) -> float:
	return RANGED_REACH if u.attack_range == "ranged" else MELEE_REACH

func _pick_target(u: BattleUnit) -> BattleUnit:
	var foes := enemy_units if u.team == BattleUnit.Team.PLAYER else player_units
	if u.controllable:
		var commanded := u.commanded_target
		if commanded != null and commanded.is_alive() and foes.has(commanded):
			return commanded
	var taunt := u.taunt_source()
	if taunt != null and taunt.is_alive() and foes.has(taunt):
		return taunt
	return _TargetRules.pick(u.target_rule, u, foes)

func _move_toward(u: BattleUnit, target: BattleUnit, delta: float) -> void:
	if target == null or u.move_speed <= 0.0:
		return
	var delta_pos := target.position() - u.position()
	var distance := delta_pos.length()
	if distance <= 0.000001:
		return
	var travel := minf(u.move_speed * delta, maxf(0.0, distance - _reach_of(u)))
	if travel <= 0.0:
		return
	var next := u.position() + delta_pos.normalized() * travel
	u.set_position(clampf(next.x, 0.0, FIELD_W), clampf(next.y, 0.0, FIELD_H))

func _process_skill(u: BattleUnit, delta: float) -> void:
	if not _SkillSystem.has_skill(u.skill_id):
		return
	u.skill_cooldown -= delta
	if u.skill_cooldown <= 0.0 and _SkillSystem.has_target(u, self):
		_SkillSystem.cast(u, self)
		u.skill_cooldown = _SkillSystem.cooldown_for(u.skill_id)
		last_skill_casts.append({
			"caster": u,
			"skill_id": u.skill_id,
			"lane": u.lane,
			"col": u.lane,
			"row": u.row,
			"px": u.px,
			"py": u.py,
		})

func _cleanup_dead() -> void:
	player_units = player_units.filter(func(u: BattleUnit) -> bool: return u.is_alive())
	enemy_units = enemy_units.filter(func(u: BattleUnit) -> bool: return u.is_alive())

func _update_result() -> void:
	if castle != null:
		if not castle.is_alive():
			result = Result.PLAYER_LOSE
			return
		if enemy_units.is_empty():
			if not pending_waves.is_empty():
				_spawn_next_wave()
				return
			result = Result.PLAYER_WIN
		return
	# 패배 — 아군 군세 전멸
	if player_units.is_empty():
		result = Result.PLAYER_LOSE
		return
	# 승리 — 적 군세 전멸과 대기 파도 없음
	if enemy_units.is_empty():
		if not pending_waves.is_empty():
			_spawn_next_wave()
			return
		result = Result.PLAYER_WIN
