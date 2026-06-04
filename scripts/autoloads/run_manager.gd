# 현재 런의 상태를 보관하는 싱글톤. 씬을 다시 불러도(전투 반복) 보드·손패·경제가 유지된다. 순수 로직은 RunState/RewardPool에 위임.
extends Node

const _StageCadence := preload("res://scripts/run/stage_cadence.gd")
const _EdictCatalog := preload("res://scripts/run/edict_catalog.gd")
const _SchemeCatalog := preload("res://scripts/run/scheme_catalog.gd")
const _TreasureCatalog := preload("res://scripts/run/treasure_catalog.gd")
const _PersistenceStore := preload("res://scripts/run/persistence_store.gd")

var state := RunState.new()
var profile := ProfileState.new_default()
var last_scheme_result: Dictionary = {}
var last_battle_outcome: Dictionary = {}
var _profile_load_checked := false

# 런이 아직 시작 안 됐으면 군주의 시작 덱으로 초기화한다.
func ensure_started(lord_id: StringName) -> void:
	if not state.started:
		state.start_run(CardLibrary.get_lord(lord_id), CardLibrary.catalog)
		_autosave_run()

func is_run_started() -> bool:
	return state != null and state.started

func save_run(path: String = _PersistenceStore.RUN_SAVE_PATH) -> bool:
	if not is_run_started():
		return false
	return _PersistenceStore.save_run_state(state, path) == OK

func load_run(path: String = _PersistenceStore.RUN_SAVE_PATH) -> bool:
	var result := _PersistenceStore.load_run_payload(path)
	if not bool(result.get("ok", false)):
		return false
	var loaded := RunState.new()
	if not loaded.from_dict(result.get("payload", {})):
		return false
	if not loaded.started:
		return false
	state = loaded
	last_scheme_result.clear()
	last_battle_outcome.clear()
	return true

func has_run_save(path: String = _PersistenceStore.RUN_SAVE_PATH) -> bool:
	return _PersistenceStore.run_save_exists(path)

func clear_run_save(path: String = _PersistenceStore.RUN_SAVE_PATH) -> bool:
	return _PersistenceStore.delete_run_save(path) == OK

func ensure_profile_loaded(path: String = _PersistenceStore.PROFILE_SAVE_PATH) -> bool:
	if _profile_load_checked:
		return true
	_profile_load_checked = true
	if not has_profile_save(path):
		return false
	return load_profile(path)

func save_profile(path: String = _PersistenceStore.PROFILE_SAVE_PATH) -> bool:
	if profile == null:
		return false
	_profile_load_checked = true
	return _PersistenceStore.save_profile_state(profile, path) == OK

func load_profile(path: String = _PersistenceStore.PROFILE_SAVE_PATH) -> bool:
	var result := _PersistenceStore.load_profile_payload(path)
	if not bool(result.get("ok", false)):
		return false
	var loaded := ProfileState.new()
	if not loaded.from_dict(result.get("payload", {})):
		return false
	profile = loaded
	_profile_load_checked = true
	last_battle_outcome.clear()
	return true

func has_profile_save(path: String = _PersistenceStore.PROFILE_SAVE_PATH) -> bool:
	return _PersistenceStore.profile_save_exists(path)

func clear_profile_save(path: String = _PersistenceStore.PROFILE_SAVE_PATH) -> bool:
	return _PersistenceStore.delete_profile_save(path) == OK

# 현재 시작된 군주의 진영(nation)을 반환한다. 미설정/없으면 촉(shu) 폴백.
func player_faction() -> StringName:
	var lord := CardLibrary.get_lord(state.lord_id)
	if lord == null:
		return &"shu"
	return lord.nation

func get_deck() -> Array[StringName]:
	return state.board_card_ids()

func get_board() -> Dictionary:
	return state.board.duplicate()

func add_card(id: StringName) -> void:
	acquire_card(id)

func acquire_card(id: StringName) -> bool:
	var card := CardLibrary.get_card(id)
	if card == null:
		return false
	if card is TreasureCardData:
		return add_treasure(id)
	hand_add(id)
	return true

func hand_add(id: StringName) -> void:
	state.hand_add(id)
	_autosave_run()

func get_hand() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in state.hand:
		out.append(id)
	return out

func hand_card_type(hand_index: int) -> String:
	var card := _hand_card(hand_index)
	if card == null:
		return ""
	return String(card.get("card_type"))

func can_place_hand_card(hand_index: int) -> bool:
	var card := _hand_card(hand_index)
	if card == null:
		return false
	var card_type := String(card.get("card_type"))
	return card is UnitCardData or card_type == "building"

func can_cast_scheme_from_hand(hand_index: int) -> bool:
	var card := _hand_card(hand_index)
	if card == null or not (card is SchemeCardData):
		return false
	return String(card.get("card_type")) == "scheme" and _SchemeCatalog.has_effect(card.effect_id)

func scheme_result_from_hand(hand_index: int, context: Dictionary = {}) -> Dictionary:
	var card := _hand_card(hand_index)
	if card == null or not (card is SchemeCardData):
		return {
			"ok": false,
			"effect_id": &"",
			"reason": "not_scheme",
			"battle": {},
			"run": {},
		}
	return _SchemeCatalog.resolve(card, context)

func get_gold() -> int:
	return state.gold

func place_from_hand(hand_index: int, block_key: String) -> bool:
	if not can_place_hand_card(hand_index):
		return false
	if not state.place_from_hand(hand_index, block_key):
		return false
	_autosave_run()
	return true

func cast_scheme_from_hand(hand_index: int) -> bool:
	var result := scheme_result_from_hand(hand_index)
	if not bool(result.get("ok", false)):
		return false
	if state.consume_from_hand(hand_index) == &"":
		return false
	last_scheme_result = result.duplicate(true)
	_apply_scheme_run_result(last_scheme_result.get("run", {}))
	_autosave_run()
	return true

func get_last_scheme_result() -> Dictionary:
	return last_scheme_result.duplicate(true)

func can_add_treasure(id: StringName) -> bool:
	var card := CardLibrary.get_card(id)
	if card == null or not (card is TreasureCardData):
		return false
	if not _TreasureCatalog.has_effect(card.effect_id):
		return false
	var count := 0
	for owned_id in state.treasures:
		if owned_id == id:
			count += 1
	return count < maxi(1, card.stack_limit)

func add_treasure(id: StringName) -> bool:
	if not can_add_treasure(id):
		return false
	state.add_treasure(id)
	_autosave_run()
	return true

func get_treasures() -> Array[StringName]:
	return state.treasure_ids()

func get_treasure_modifiers() -> Dictionary:
	return _TreasureCatalog.modifiers(state.treasure_ids(), CardLibrary.catalog)

func treasure_attack_pct() -> float:
	var battle: Dictionary = get_treasure_modifiers().get("battle", {})
	return float(battle.get("attack_pct", 0.0))

func gold_reward_pct() -> float:
	var economy: Dictionary = get_treasure_modifiers().get("economy", {})
	return float(economy.get("gold_pct", 0.0))

func reward_choice_count(base_n: int) -> int:
	var reward: Dictionary = get_treasure_modifiers().get("reward", {})
	return maxi(0, base_n) + maxi(0, int(reward.get("bonus_choices", 0)))

func apply_treasure_battle_modifiers(units: Array) -> void:
	var attack_pct := treasure_attack_pct()
	if attack_pct <= 0.0:
		return
	for unit in units:
		if unit == null or not (unit is BattleUnit):
			continue
		if unit.is_castle:
			continue
		unit.attack = maxi(0, int(round(unit.attack * (1.0 + attack_pct))))

func discard_from_hand(hand_index: int) -> bool:
	if not state.discard_from_hand(hand_index):
		return false
	_autosave_run()
	return true

func add_gold(n: int) -> void:
	state.add_gold(n)
	_autosave_run()

func spend_gold(n: int) -> bool:
	if not state.spend_gold(n):
		return false
	_autosave_run()
	return true

func board_full() -> bool:
	return state.board_full()

func expand_board() -> bool:
	if not state.expand_board():
		return false
	_autosave_run()
	return true

func get_board_rows() -> int:
	return state.board_rows

func get_board_capacity() -> int:
	return state.board_capacity()

func get_command_points() -> int:
	return state.command_points if state != null else 12

func stage_index() -> int:
	return state.stage_index

func is_boss_stage() -> bool:
	return _StageCadence.is_boss(state.stage_index)

func stage_node_kind() -> String:
	return _StageCadence.node_kind(state.stage_index)

func is_final_boss_stage() -> bool:
	return _StageCadence.is_final_boss(state.stage_index)

func is_shop_stage() -> bool:
	return _StageCadence.is_shop(state.stage_index)

func is_edict_stage() -> bool:
	return _StageCadence.is_edict(state.stage_index)

func is_elite_stage() -> bool:
	return _StageCadence.is_elite(state.stage_index)

func is_event_stage() -> bool:
	return _StageCadence.is_event(state.stage_index)

func add_edict(id: StringName) -> bool:
	if not _EdictCatalog.EDICTS.has(id):
		return false
	state.add_edict(id)
	_autosave_run()
	return true

func get_edicts() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in state.edicts:
		out.append(id)
	return out

func shop_card_ids() -> Array[StringName]:
	return CardLibrary.catalog.purchasable_ids()

func shop_purchase(id: StringName) -> bool:
	var card := CardLibrary.get_card(id)
	if card == null:
		return false
	if card is TreasureCardData and not can_add_treasure(id):
		return false
	if get_gold() < card.cost:
		return false
	if not spend_gold(card.cost):
		return false
	if acquire_card(id):
		return true
	add_gold(card.cost)
	return false

func is_expand_stage() -> bool:
	return _StageCadence.is_expand(state.stage_index)

func difficulty_scale() -> float:
	return _StageCadence.difficulty_scale(state.stage_index)

func current_waves() -> Array:
	return WaveFactory.stage_waves(state.stage_index)

func advance_stage() -> void:
	state.advance_stage()
	_autosave_run()

# 보상 후보 최대 n장.
func reward_candidates(n: int, allowed_types: Array = []) -> Array[StringName]:
	return RewardPool.roll_for_profile(CardLibrary.catalog, state.owned_card_ids(), profile, n, allowed_types)

func record_battle_outcome(win: bool) -> Dictionary:
	var score := _battle_score(win)
	var run_result := _battle_run_result_for_stage(state.stage_index, win)
	var profile_changed := profile.record_result(state.stage_index, score)
	var unlocked_lords: Array[StringName] = []
	var unlocked_cards: Array[StringName] = []
	if win:
		for rule in _lord_unlock_rules():
			if state.stage_index >= int(rule.get("stage", 0)):
				var lord_id := StringName(rule.get("lord_id", &""))
				if profile.unlock_lord(lord_id):
					unlocked_lords.append(lord_id)
					profile_changed = true
	last_battle_outcome = {
		"win": win,
		"stage": state.stage_index,
		"node_kind": stage_node_kind(),
		"is_final_boss": _StageCadence.is_final_boss(state.stage_index),
		"run_result": run_result,
		"run_victory": run_result == "victory",
		"run_complete": run_result != "ongoing",
		"score": score,
		"profile_changed": profile_changed,
		"unlocked_lords": unlocked_lords,
		"unlocked_cards": unlocked_cards,
	}
	if profile_changed:
		_autosave_profile()
	return get_last_battle_outcome()

func get_last_battle_outcome() -> Dictionary:
	return last_battle_outcome.duplicate(true)

func get_profile() -> ProfileState:
	return profile

func is_lord_unlocked(id: StringName) -> bool:
	return profile != null and profile.is_lord_unlocked(id)

func is_card_unlocked(id: StringName) -> bool:
	return profile != null and profile.is_card_unlocked(id)

func get_unlocked_lord_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	if profile == null:
		return out
	for id in profile.unlocked_lord_ids:
		out.append(id)
	return out

func get_unlocked_card_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	if profile == null:
		return out
	for id in profile.unlocked_card_ids:
		out.append(id)
	return out

func reset_run() -> void:
	state = RunState.new()
	last_scheme_result.clear()
	last_battle_outcome.clear()
	clear_run_save()

func reset_profile() -> void:
	profile = ProfileState.new_default()
	_profile_load_checked = true
	last_battle_outcome.clear()
	_autosave_profile()

func reset() -> void:
	reset_run()

func _apply_scheme_run_result(run_result: Dictionary) -> void:
	var gold_delta := int(run_result.get("gold_delta", 0))
	if gold_delta > 0:
		add_gold(gold_delta)

func _autosave_run() -> void:
	if is_run_started():
		save_run()

func _autosave_profile() -> void:
	if profile != null:
		save_profile()

func _battle_score(win: bool) -> int:
	var win_bonus := 500 if win else 0
	return maxi(0, state.stage_index) * 100 + maxi(0, state.gold) + state.board.size() * 10 + state.hand.size() * 3 + state.treasures.size() * 25 + win_bonus

func _battle_run_result_for_stage(stage: int, win: bool) -> String:
	if not win:
		return "defeat"
	if _StageCadence.is_final_boss(stage):
		return "victory"
	return "ongoing"

func _lord_unlock_rules() -> Array[Dictionary]:
	return [
		{"stage": 5, "lord_id": &"lord_caocao"},
		{"stage": 10, "lord_id": &"lord_sunquan"},
	]

func _hand_card(hand_index: int) -> CardData:
	if hand_index < 0 or hand_index >= state.hand.size():
		return null
	return CardLibrary.get_card(StringName(state.hand[hand_index]))
