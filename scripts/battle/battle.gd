# 전투 화면 — 영속 보드 배치에서 군세를 스폰하고 "전투 시작"을 누르면 2D 오픈필드 오토배틀이 진행된다.
# 순수 전투 로직은 BattleSim에 있다. 이 스크립트는 입력·보드 표시·유닛 시각화만 담당한다.
extends Control

enum Phase { DEPLOY, BATTLE, DONE }

const LORD_ID := &"lord_liubei"

const FIELD_LEFT := 560.0
const FIELD_RIGHT := 1840.0
const FIELD_TOP := 120.0
const FIELD_BOTTOM := 900.0
const TILE_W := 150.0
const TILE_H := 82.0
const UNIT_W := 70.0
const UNIT_H := 52.0
const COMMAND_PICK_RADIUS := 70.0

var _phase: int = Phase.DEPLOY
var _sim := BattleSim.new()
var _lord: LordData
var _vis: Dictionary = {}            # BattleUnit -> { root: Control, hp: ColorRect }
var _tile_buttons: Dictionary = {}   # "col:row" -> Button
var _node_completed := false
var _command_hold_active := false
var _commanded_target: BattleUnit = null

var _units_layer: Control
var _wave_label: Label
var _hint_label: Label
var _start_button: Button
var _result_label: Label
var _overlay: Control            # 승리 보상 / 패배 재시도 패널

func _ready() -> void:
	_lord = CardLibrary.get_lord(LORD_ID)
	RunManager.ensure_started(LORD_ID)
	_build_field()
	_ensure_castle()
	_spawn_board_army()
	_build_panel()
	if _lord == null:
		_hint_label.text = "오류 — 군주(%s)를 불러오지 못했습니다." % LORD_ID

func _process(delta: float) -> void:
	if _phase != Phase.BATTLE:
		return
	if _command_hold_active:
		_apply_hero_command_at(get_global_mouse_position())
	_sim.step(delta)
	_prune_command_target()
	_sync_visuals()
	_flash_skill_casts()
	if _sim.is_over():
		_end_battle()

func _input(event: InputEvent) -> void:
	if _phase != Phase.BATTLE:
		return
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		_command_hold_active = mouse_button.pressed
		if mouse_button.pressed:
			_apply_hero_command_at(mouse_button.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _command_hold_active:
		var motion := event as InputEventMouseMotion
		_apply_hero_command_at(motion.position)
		get_viewport().set_input_as_handled()

# ── 화면 구성 ───────────────────────────────────────────────
func _build_field() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.08, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var field := ColorRect.new()
	field.color = Color(0.12, 0.15, 0.10)
	field.position = Vector2(FIELD_LEFT, FIELD_TOP)
	field.size = Vector2(FIELD_RIGHT - FIELD_LEFT, FIELD_BOTTOM - FIELD_TOP)
	add_child(field)
	for col in BattleSim.COL_COUNT:
		var guide := ColorRect.new()
		guide.color = Color(0.20, 0.24, 0.16, 0.45)
		guide.position = Vector2(FIELD_LEFT, _map_py(BattleSim.start_y_for_col(col)) - 2.0)
		guide.size = Vector2(FIELD_RIGHT - FIELD_LEFT, 4.0)
		add_child(guide)
	var p_base := ColorRect.new()
	p_base.color = Color(0.25, 0.4, 0.75)
	p_base.position = Vector2(FIELD_LEFT - 16.0, FIELD_TOP)
	p_base.size = Vector2(8.0, FIELD_BOTTOM - FIELD_TOP)
	add_child(p_base)
	var e_base := ColorRect.new()
	e_base.color = Color(0.75, 0.25, 0.25)
	e_base.position = Vector2(FIELD_RIGHT + 8.0, FIELD_TOP)
	e_base.size = Vector2(8.0, FIELD_BOTTOM - FIELD_TOP)
	add_child(e_base)
	for col in BattleSim.COL_COUNT:
		for row in BattleSim.ROW_COUNT:
			var tile := Button.new()
			tile.position = _tile_position(col, row)
			tile.size = Vector2(TILE_W, TILE_H)
			tile.text = "빈 칸"
			tile.disabled = true
			tile.focus_mode = Control.FOCUS_NONE
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile.add_theme_font_size_override("font_size", 15)
			add_child(tile)
			_tile_buttons[_tile_key(col, row)] = tile
	_units_layer = Control.new()
	_units_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_units_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_units_layer)
	# 결과 오버레이
	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.position = Vector2(FIELD_LEFT, 32.0)
	_result_label.size = Vector2(FIELD_RIGHT - FIELD_LEFT, 70.0)
	_result_label.add_theme_font_size_override("font_size", 56)
	_result_label.visible = false
	add_child(_result_label)

func _build_panel() -> void:
	var panel := VBoxContainer.new()
	panel.position = Vector2(28.0, 28.0)
	panel.custom_minimum_size = Vector2(440.0, 0.0)
	panel.add_theme_constant_override("separation", 10)
	add_child(panel)

	var title := Label.new()
	var lord_name := _lord.display_name if _lord != null else "?"
	title.text = "군주 — %s (촉)" % lord_name
	title.add_theme_font_size_override("font_size", 26)
	panel.add_child(title)

	if _lord != null and _lord.trait_name != "":
		var trait_label := Label.new()
		trait_label.text = "특성 — %s" % _lord.trait_name
		trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(trait_label)

	_wave_label = Label.new()
	_wave_label.add_theme_font_size_override("font_size", 22)
	_wave_label.visible = false
	panel.add_child(_wave_label)
	_update_wave_label()

	var guide := Label.new()
	guide.text = "보드 배치가 이번 전투 군세입니다."
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(guide)

	var board_head := Label.new()
	board_head.text = "보드 군세 — %d장" % _board_unit_count()
	board_head.add_theme_font_size_override("font_size", 20)
	panel.add_child(board_head)
	_add_board_summary(panel)

	_start_button = Button.new()
	_start_button.text = "전투 시작"
	_start_button.custom_minimum_size = Vector2(0.0, 44.0)
	_start_button.pressed.connect(_on_start_pressed)
	panel.add_child(_start_button)

	_hint_label = Label.new()
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.modulate = Color(1.0, 0.8, 0.4)
	panel.add_child(_hint_label)

func _add_board_summary(panel: VBoxContainer) -> void:
	var board := RunManager.get_board()
	var any := false
	for key in RunState.block_keys():
		if not board.has(key):
			continue
		any = true
		panel.add_child(_make_board_row(key, StringName(board[key])))
	if not any:
		var empty := Label.new()
		empty.text = "보드 군세 없음"
		panel.add_child(empty)

func _make_board_row(block_key: String, card_id: StringName) -> Control:
	var card := CardLibrary.get_card(card_id)
	var row := HBoxContainer.new()
	var slot_label := Label.new()
	slot_label.text = _block_label(block_key)
	slot_label.custom_minimum_size = Vector2(92.0, 0.0)
	row.add_child(slot_label)
	var name_label := Label.new()
	if card != null:
		name_label.text = "%s (%d)" % [card.display_name, card.cost]
	else:
		name_label.text = String(card_id)
	name_label.custom_minimum_size = Vector2(300.0, 0.0)
	row.add_child(name_label)
	return row

# ── 입력 ────────────────────────────────────────────────────
func _on_start_pressed() -> void:
	if _phase != Phase.DEPLOY:
		return
	_ensure_castle()
	if _board_unit_count() <= 0:
		_hint_label.text = "보드 군세가 비어 있습니다."
		return
	_sim.set_waves(WaveFactory.waves_for_node(RunManager.active_node_type()))
	_phase = Phase.BATTLE
	_clear_hero_command(false)
	_sync_visuals()
	_start_button.disabled = true
	_hint_label.text = "전투 중…"

# ── 시각화 ──────────────────────────────────────────────────
func _spawn_visual(u: BattleUnit) -> void:
	var root := Control.new()
	root.size = Vector2(UNIT_W, UNIT_H)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body := ColorRect.new()
	if u.is_castle:
		body.color = Color(0.62, 0.56, 0.40)
	else:
		body.color = Color(0.32, 0.52, 0.9) if u.team == BattleUnit.Team.PLAYER else Color(0.85, 0.32, 0.32)
	var command_marker := ColorRect.new()
	command_marker.color = Color(1.0, 0.85, 0.1, 0.55)
	command_marker.position = Vector2(-5.0, -5.0)
	command_marker.size = Vector2(UNIT_W + 10.0, UNIT_H + 10.0)
	command_marker.visible = false
	root.add_child(command_marker)
	body.size = Vector2(UNIT_W, UNIT_H)
	body.position = Vector2.ZERO
	root.add_child(body)
	var hp_bg := ColorRect.new()
	hp_bg.color = Color(0, 0, 0, 0.6)
	hp_bg.position = Vector2(3.0, 3.0)
	hp_bg.size = Vector2(UNIT_W - 6.0, 6.0)
	root.add_child(hp_bg)
	var hp := ColorRect.new()
	hp.color = Color(0.4, 0.9, 0.4) if u.team == BattleUnit.Team.PLAYER else Color(0.95, 0.6, 0.3)
	hp.position = Vector2(3.0, 3.0)
	hp.size = Vector2(UNIT_W - 6.0, 6.0)
	root.add_child(hp)
	var name_label := Label.new()
	name_label.text = u.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(0.0, 14.0)
	name_label.size = Vector2(UNIT_W, UNIT_H - 14.0)
	name_label.add_theme_font_size_override("font_size", 14)
	root.add_child(name_label)
	_units_layer.add_child(root)
	_vis[u] = { "root": root, "body": body, "base_color": body.color, "hp": hp, "command_marker": command_marker }
	_position_visual(u)

func _sync_visuals() -> void:
	var active_units := _sim_units()
	var active := {}
	for u in active_units:
		if u == null or not u.is_alive():
			continue
		active[u] = true
		if not _vis.has(u):
			_spawn_visual(u)
	for u in _vis.keys():
		if not active.has(u) or not u.is_alive():
			_vis[u]["root"].queue_free()
			_vis.erase(u)
	for u in active_units:
		if _vis.has(u):
			_position_visual(u)
			_vis[u]["hp"].size.x = (UNIT_W - 6.0) * u.hp_ratio()
			var marker: ColorRect = _vis[u].get("command_marker", null)
			if marker != null:
				marker.visible = u == _commanded_target
	_update_wave_label()

func _position_visual(u: BattleUnit) -> void:
	var offset := _unit_visual_offset(u)
	var sx := _map_px(u.px) - UNIT_W * 0.5 + offset.x
	var sy := _map_py(u.py) - UNIT_H * 0.5 + offset.y
	_vis[u]["root"].position = Vector2(sx, sy)

func _flash_skill_casts() -> void:
	for cast in _sim.last_skill_casts:
		var caster: BattleUnit = cast.get("caster", null)
		if caster == null or not _vis.has(caster):
			continue
		var body: ColorRect = _vis[caster].get("body", null)
		if body == null or not is_instance_valid(body):
			continue
		var base_color: Color = _vis[caster].get("base_color", body.color)
		body.color = Color(1.0, 1.0, 1.0)
		var tween := create_tween()
		tween.tween_property(body, "color", base_color, 0.15)

func _sim_units() -> Array[BattleUnit]:
	var units: Array[BattleUnit] = []
	units.append_array(_sim.player_units)
	units.append_array(_sim.enemy_units)
	return units

func _spawn_board_army() -> void:
	var board := RunManager.get_board()
	var army := CardLibrary.catalog.build_board_army(board, _lord)
	for unit in army:
		_sim.add_unit(unit)
		_spawn_visual(unit)
		_update_tile_label(unit.lane, unit.row, unit.display_name)

func _ensure_castle() -> void:
	var castle := _sim.add_castle()
	if not _vis.has(castle):
		_spawn_visual(castle)

func _apply_hero_command_at(screen_pos: Vector2) -> void:
	var target := _enemy_near_screen_pos(screen_pos)
	if target == null:
		_clear_hero_command(true)
		return
	var heroes := _controllable_heroes()
	if heroes.is_empty():
		_clear_hero_command(false)
		return
	for hero in heroes:
		hero.commanded_target = target
	_commanded_target = target
	_hint_label.text = "집중 표적 — %s" % target.display_name

func _clear_hero_command(update_hint: bool = true) -> void:
	for hero in _controllable_heroes():
		hero.commanded_target = null
	_commanded_target = null
	if update_hint and _phase == Phase.BATTLE:
		_hint_label.text = "자동 표적"

func _prune_command_target() -> void:
	if _commanded_target == null:
		return
	if _commanded_target.is_alive() and _sim.enemy_units.has(_commanded_target):
		return
	_clear_hero_command(false)

func _controllable_heroes() -> Array[BattleUnit]:
	var heroes: Array[BattleUnit] = []
	for u in _sim.player_units:
		if u != null and u.is_alive() and u.controllable:
			heroes.append(u)
	return heroes

func _enemy_near_screen_pos(screen_pos: Vector2) -> BattleUnit:
	if screen_pos.x < FIELD_LEFT or screen_pos.x > FIELD_RIGHT or screen_pos.y < FIELD_TOP or screen_pos.y > FIELD_BOTTOM:
		return null
	var field_pos := _screen_to_field(screen_pos)
	var best: BattleUnit = null
	var best_d := COMMAND_PICK_RADIUS
	for enemy in _sim.enemy_units:
		if enemy == null or not enemy.is_alive():
			continue
		var d := enemy.position().distance_to(field_pos)
		if d <= best_d:
			best_d = d
			best = enemy
	return best

func _screen_to_field(screen_pos: Vector2) -> Vector2:
	var tx := clampf((screen_pos.x - FIELD_LEFT) / (FIELD_RIGHT - FIELD_LEFT), 0.0, 1.0)
	var ty := clampf((screen_pos.y - FIELD_TOP) / (FIELD_BOTTOM - FIELD_TOP), 0.0, 1.0)
	return Vector2(tx * BattleSim.FIELD_W, ty * BattleSim.FIELD_H)

func _map_px(px: float) -> float:
	var t := clampf(px / BattleSim.FIELD_W, 0.0, 1.0)
	return FIELD_LEFT + t * (FIELD_RIGHT - FIELD_LEFT)

func _map_py(py: float) -> float:
	var t := clampf(py / BattleSim.FIELD_H, 0.0, 1.0)
	return FIELD_TOP + t * (FIELD_BOTTOM - FIELD_TOP)

func _tile_position(col: int, row: int) -> Vector2:
	var p := BattleSim.position_for_tile(col, row)
	return Vector2(_map_px(p.x) - TILE_W * 0.5, _map_py(p.y) - TILE_H * 0.5)

func _tile_key(col: int, row: int) -> String:
	return "%d:%d" % [col, row]

func _update_tile_label(col: int, row: int, text: String) -> void:
	var tile: Button = _tile_buttons.get(_tile_key(col, row), null)
	if tile != null:
		tile.text = text
		tile.disabled = true

func _unit_visual_offset(u: BattleUnit) -> Vector2:
	var index := 0
	for other in _sim_units():
		if other == u:
			break
		if other.team == u.team and other.position().distance_to(u.position()) < 4.0:
			index += 1
	return Vector2(float((index % 3) - 1) * 18.0, float(index / 3) * 14.0)

func _update_wave_label() -> void:
	if _wave_label == null:
		return
	if _sim.wave_total <= 0:
		_wave_label.text = "파도 - / -"
		_wave_label.visible = false
		return
	_wave_label.text = "파도 %d / %d" % [_sim.wave_index, _sim.wave_total]
	_wave_label.visible = _phase != Phase.DEPLOY

# ── 종료 · 전리(보상) ───────────────────────────────────────
func _end_battle() -> void:
	_phase = Phase.DONE
	_result_label.visible = true
	var win := _sim.result == BattleSim.Result.PLAYER_WIN
	if win:
		_result_label.text = "승리!"
		_result_label.modulate = Color(0.5, 1.0, 0.5)
		_hint_label.text = "전리품을 고르세요."
		EventBus.battle_won.emit()
	else:
		_result_label.text = "런 실패"
		_result_label.modulate = Color(1.0, 0.5, 0.5)
		_hint_label.text = "전투 종료."
		EventBus.battle_lost.emit()
	_build_outcome_ui(win)

func _build_outcome_ui(win: bool) -> void:
	var box := _new_overlay_box()
	if not win:
		var fail := Label.new()
		fail.text = "런 실패"
		fail.add_theme_font_size_override("font_size", 24)
		box.add_child(fail)
		box.add_child(_make_button("새 런", _restart_run))
		return
	var candidates := RunManager.reward_candidates(3)
	if candidates.is_empty():
		var none := Label.new()
		none.text = "획득 가능한 보상이 없습니다."
		box.add_child(none)
		_complete_node_once()
		_add_map_or_conquest_button(box)
		return
	var head := Label.new()
	head.text = "전리품 — 한 장을 골라 군세에 넣으세요"
	head.add_theme_font_size_override("font_size", 24)
	box.add_child(head)
	for id in candidates:
		var card := CardLibrary.get_card(id)
		box.add_child(_make_button("%s (%d) — %s" % [card.display_name, card.cost, _card_brief(card)], _pick_reward.bind(id)))

func _pick_reward(id: StringName) -> void:
	RunManager.add_card(id)
	var card := CardLibrary.get_card(id)
	var got_name := card.display_name if card != null else String(id)
	EventBus.card_rewarded.emit(id)
	_hint_label.text = "획득 — %s! 군세에 편입되었습니다." % got_name
	_complete_node_once()
	var box := _new_overlay_box()
	var got := Label.new()
	got.text = "획득 — %s" % got_name
	got.add_theme_font_size_override("font_size", 24)
	box.add_child(got)
	_add_map_or_conquest_button(box)

func _add_map_or_conquest_button(box: VBoxContainer) -> void:
	if RunManager.map_finished():
		_result_label.text = "구주 정복!"
		var done := Label.new()
		done.text = "구주 정복!"
		done.add_theme_font_size_override("font_size", 30)
		box.add_child(done)
		box.add_child(_make_button("새 런", _restart_run))
	else:
		box.add_child(_make_button("지도로 (보드 %d장)" % RunManager.get_deck().size(), _go_to_run_map))

func _complete_node_once() -> void:
	if _node_completed:
		return
	RunManager.complete_node()
	_node_completed = true

func _go_to_run_map() -> void:
	GameManager.change_scene("res://scenes/screens/run_map.tscn")

func _restart_run() -> void:
	RunManager.reset_run()
	GameManager.change_scene("res://scenes/screens/run_map.tscn")

# ── 헬퍼 ────────────────────────────────────────────────────
func _new_overlay_box() -> VBoxContainer:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	var box := VBoxContainer.new()
	box.position = Vector2(FIELD_LEFT, 150.0)
	box.custom_minimum_size = Vector2(FIELD_RIGHT - FIELD_LEFT, 0.0)
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_overlay = box
	return box

func _make_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0.0, 40.0)
	b.pressed.connect(cb)
	return b

func _card_brief(card: CardData) -> String:
	if card is UnitCardData:
		return "%s/%s" % [card.troop_type, card.attack_range]
	return card.card_type

func _board_unit_count() -> int:
	var count := 0
	for u in _sim.player_units:
		if u != null and not u.is_castle:
			count += 1
	return count

func _block_label(block_key: String) -> String:
	var parts := block_key.split(":")
	if parts.size() != 2:
		return block_key
	return "%d열 %d행" % [int(parts[0]) + 1, int(parts[1]) + 1]
