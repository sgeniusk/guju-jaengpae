# v0.1 전투 화면 — 군주의 시작 덱을 레인에 배치하고(배치 단계) "전투 시작"을 누르면 오토배틀이 진행된다.
# 순수 전투 로직은 BattleSim에 있다. 이 스크립트는 입력·배치 UI·유닛 시각화만 담당한다.
extends Control

enum Phase { DEPLOY, BATTLE, DONE }

const LORD_ID := &"lord_liubei"
const START_POINTS := 12

const FIELD_LEFT := 520.0
const FIELD_RIGHT := 1840.0
const LANE_Y := [260.0, 520.0, 780.0]
const UNIT_W := 70.0
const UNIT_H := 52.0

var _phase: int = Phase.DEPLOY
var _sim := BattleSim.new()
var _lord: LordData
var _points: int = START_POINTS
var _vis: Dictionary = {}            # BattleUnit -> { root: Control, hp: ColorRect }
var _lane_count := [0, 0, 0]         # 레인별 아군 배치 수(겹침 방지 오프셋)

var _units_layer: Control
var _points_label: Label
var _hint_label: Label
var _start_button: Button
var _result_label: Label
var _overlay: Control            # 승리 보상 / 패배 재시도 패널

func _ready() -> void:
	_lord = CardLibrary.get_lord(LORD_ID)
	RunManager.ensure_started(LORD_ID)
	_build_field()
	_build_panel()
	if _lord == null:
		_hint_label.text = "오류 — 군주(%s)를 불러오지 못했습니다." % LORD_ID

func _process(delta: float) -> void:
	if _phase != Phase.BATTLE:
		return
	_sim.step(delta)
	_sync_visuals()
	if _sim.is_over():
		_end_battle()

# ── 화면 구성 ───────────────────────────────────────────────
func _build_field() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.08, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# 레인 띠 + 기지 표시
	for lane in BattleSim.LANE_COUNT:
		var band := ColorRect.new()
		band.color = Color(0.16, 0.15, 0.19) if lane % 2 == 0 else Color(0.13, 0.12, 0.16)
		band.position = Vector2(FIELD_LEFT - 30.0, LANE_Y[lane] - 95.0)
		band.size = Vector2(FIELD_RIGHT - FIELD_LEFT + 60.0, 190.0)
		add_child(band)
	var p_base := ColorRect.new()
	p_base.color = Color(0.25, 0.4, 0.75)
	p_base.position = Vector2(FIELD_LEFT - 40.0, LANE_Y[0] - 95.0)
	p_base.size = Vector2(8.0, LANE_Y[2] - LANE_Y[0] + 190.0)
	add_child(p_base)
	var e_base := ColorRect.new()
	e_base.color = Color(0.75, 0.25, 0.25)
	e_base.position = Vector2(FIELD_RIGHT + 32.0, LANE_Y[0] - 95.0)
	e_base.size = Vector2(8.0, LANE_Y[2] - LANE_Y[0] + 190.0)
	add_child(e_base)
	_units_layer = Control.new()
	_units_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_units_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_units_layer)
	# 결과 오버레이
	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.position = Vector2(FIELD_LEFT, 60.0)
	_result_label.size = Vector2(FIELD_RIGHT - FIELD_LEFT, 80.0)
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

	_points_label = Label.new()
	_points_label.add_theme_font_size_override("font_size", 22)
	panel.add_child(_points_label)
	_update_points()

	var guide := Label.new()
	guide.text = "카드 오른쪽 1·2·3 버튼으로 레인에 배치하세요."
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(guide)

	# 덱 카드 행 (런 상태의 현재 덱 — 시작 덱 + 전리 보상)
	for card_id in RunManager.get_deck():
		panel.add_child(_make_card_row(card_id))

	_start_button = Button.new()
	_start_button.text = "전투 시작"
	_start_button.custom_minimum_size = Vector2(0.0, 44.0)
	_start_button.pressed.connect(_on_start_pressed)
	panel.add_child(_start_button)

	_hint_label = Label.new()
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.modulate = Color(1.0, 0.8, 0.4)
	panel.add_child(_hint_label)

func _make_card_row(card_id: StringName) -> Control:
	var card := CardLibrary.get_card(card_id)
	var row := HBoxContainer.new()
	var name_label := Label.new()
	if card != null:
		name_label.text = "%s (%d)" % [card.display_name, card.cost]
	else:
		name_label.text = String(card_id)
	name_label.custom_minimum_size = Vector2(220.0, 0.0)
	row.add_child(name_label)
	for lane in BattleSim.LANE_COUNT:
		var b := Button.new()
		b.text = str(lane + 1)
		b.custom_minimum_size = Vector2(56.0, 0.0)
		b.pressed.connect(_on_deploy_pressed.bind(card_id, lane))
		row.add_child(b)
	return row

# ── 입력 ────────────────────────────────────────────────────
func _on_deploy_pressed(card_id: StringName, lane: int) -> void:
	if _phase != Phase.DEPLOY or _lord == null:
		return
	var card := CardLibrary.get_card(card_id)
	if card == null:
		return
	if _points < card.cost:
		_hint_label.text = "지휘력이 부족합니다 (필요 %d)." % card.cost
		return
	var x := 30.0 + float(_lane_count[lane]) * 26.0
	var u := CardLibrary.build_player_unit(card_id, lane, x, _lord)
	if u == null:
		return
	_sim.add_unit(u)
	_spawn_visual(u)
	_lane_count[lane] += 1
	_points -= card.cost
	_update_points()
	_hint_label.text = "%s → %d레인 배치" % [card.display_name, lane + 1]

func _on_start_pressed() -> void:
	if _phase != Phase.DEPLOY:
		return
	if _sim.player_units.is_empty():
		_hint_label.text = "최소 한 유닛을 배치해야 합니다."
		return
	for e in WaveFactory.wave_one():
		_sim.add_unit(e)
		_spawn_visual(e)
	_phase = Phase.BATTLE
	_start_button.disabled = true
	_hint_label.text = "전투 중…"

# ── 시각화 ──────────────────────────────────────────────────
func _spawn_visual(u: BattleUnit) -> void:
	var root := Control.new()
	root.size = Vector2(UNIT_W, UNIT_H)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body := ColorRect.new()
	body.color = Color(0.32, 0.52, 0.9) if u.team == BattleUnit.Team.PLAYER else Color(0.85, 0.32, 0.32)
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
	_vis[u] = { "root": root, "hp": hp }
	_position_visual(u)

func _sync_visuals() -> void:
	for u in _vis.keys():
		if not u.is_alive():
			_vis[u]["root"].queue_free()
			_vis.erase(u)
		else:
			_position_visual(u)
			_vis[u]["hp"].size.x = (UNIT_W - 6.0) * u.hp_ratio()

func _position_visual(u: BattleUnit) -> void:
	var sx := _map_x(u.x) - UNIT_W * 0.5
	var sy := float(LANE_Y[u.lane]) - UNIT_H * 0.5
	_vis[u]["root"].position = Vector2(sx, sy)

func _map_x(sim_x: float) -> float:
	return FIELD_LEFT + (sim_x / BattleSim.LANE_LENGTH) * (FIELD_RIGHT - FIELD_LEFT)

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
		_result_label.text = "패배…"
		_result_label.modulate = Color(1.0, 0.5, 0.5)
		_hint_label.text = "전투 종료."
		EventBus.battle_lost.emit()
	_build_outcome_ui(win)

func _build_outcome_ui(win: bool) -> void:
	var box := _new_overlay_box()
	if not win:
		box.add_child(_make_button("다시 시도", _restart_run))
		return
	var candidates := RunManager.reward_candidates(3)
	if candidates.is_empty():
		var none := Label.new()
		none.text = "획득 가능한 보상이 없습니다."
		box.add_child(none)
		box.add_child(_make_button("다음 전투", _next_battle))
		return
	var head := Label.new()
	head.text = "전리품 — 한 장을 골라 덱에 넣으세요"
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
	_hint_label.text = "획득 — %s! 덱에 편입되었습니다." % got_name
	var box := _new_overlay_box()
	var got := Label.new()
	got.text = "획득 — %s" % got_name
	got.add_theme_font_size_override("font_size", 24)
	box.add_child(got)
	box.add_child(_make_button("다음 전투 (덱 %d장)" % RunManager.get_deck().size(), _next_battle))

func _next_battle() -> void:
	get_tree().reload_current_scene()   # RunManager(오토로드)가 덱을 유지 → 보상이 반영됨

func _restart_run() -> void:
	RunManager.reset()
	get_tree().reload_current_scene()

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

func _update_points() -> void:
	_points_label.text = "지휘력 — %d / %d" % [_points, START_POINTS]
