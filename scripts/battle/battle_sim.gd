# 레인 오토배틀의 순수 시뮬레이션. 렌더링 없이 step(delta)로 진행되며 결정적이다 — 헤드리스 테스트 가능.
class_name BattleSim
extends RefCounted

enum Result { ONGOING, PLAYER_WIN, PLAYER_LOSE }

const LANE_COUNT := 3
const LANE_LENGTH := 1000.0
const MELEE_REACH := 36.0
const RANGED_REACH := 280.0
const _SkillSystem := preload("res://scripts/battle/skill_system.gd")

var player_units: Array[BattleUnit] = []
var enemy_units: Array[BattleUnit] = []
var pending_waves: Array = []
var wave_index := 0
var wave_total := 0
var result: int = Result.ONGOING
var elapsed: float = 0.0
var last_skill_casts: Array = []

func add_unit(u: BattleUnit) -> void:
	if u == null:
		return
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
	if is_over():
		return
	elapsed += delta
	# player + enemy를 한 번에 순회(안정적 순서 → 결정적)
	for u in player_units + enemy_units:
		if not u.is_alive():
			continue
		_process_skill(u, delta)
		if u.cooldown > 0.0:
			u.cooldown -= delta
		var target := _nearest_enemy(u)
		if target != null and absf(target.x - u.x) <= _reach_of(u):
			if u.cooldown <= 0.0:
				target.take_damage(u.attack)
				u.cooldown = u.attack_interval
		else:
			_advance(u, delta)
	_cleanup_dead()
	_update_result()

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

func _reach_of(u: BattleUnit) -> float:
	return RANGED_REACH if u.attack_range == "ranged" else MELEE_REACH

func _nearest_enemy(u: BattleUnit) -> BattleUnit:
	var foes := enemy_units if u.team == BattleUnit.Team.PLAYER else player_units
	var best: BattleUnit = null
	var best_d := INF
	for f in foes:
		if not f.is_alive() or f.lane != u.lane:
			continue
		var d := absf(f.x - u.x)
		if d < best_d:
			best_d = d
			best = f
	return best

func _advance(u: BattleUnit, delta: float) -> void:
	var dir := 1.0 if u.team == BattleUnit.Team.PLAYER else -1.0
	u.x = clampf(u.x + dir * u.move_speed * delta, 0.0, LANE_LENGTH)

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
		})

func _cleanup_dead() -> void:
	player_units = player_units.filter(func(u: BattleUnit) -> bool: return u.is_alive())
	enemy_units = enemy_units.filter(func(u: BattleUnit) -> bool: return u.is_alive())

func _update_result() -> void:
	# 패배 — 적이 플레이어 기지(x<=0)에 도달
	for e in enemy_units:
		if e.x <= 0.0:
			result = Result.PLAYER_LOSE
			return
	# 승리 — 적 전멸
	if enemy_units.is_empty():
		if not pending_waves.is_empty():
			_spawn_next_wave()
			return
		result = Result.PLAYER_WIN
		return
	# 패배 — 아군 전멸(적 잔존)
	if player_units.is_empty():
		result = Result.PLAYER_LOSE
