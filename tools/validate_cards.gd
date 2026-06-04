# 카드·군주 Resource를 헤드리스로 로드해 스키마 일관성을 검증하는 도구.
# 실행 — godot --headless --path . --script res://tools/validate_cards.gd
extends SceneTree

const _SchemeCatalog := preload("res://scripts/run/scheme_catalog.gd")
const _TreasureCatalog := preload("res://scripts/run/treasure_catalog.gd")

func _initialize() -> void:
	var errors := 0
	errors += _validate_cards("res://resources/cards")
	errors += _validate_lords("res://resources/lords")
	if errors == 0:
		print("✅ 카드/군주 검증 통과")
		quit(0)
	else:
		printerr("❌ 카드/군주 검증 실패: %d건" % errors)
		quit(1)

func _list_tres(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		printerr("디렉토리 열기 실패: ", dir_path)
		return out
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.ends_with(".tres"):
			out.append(dir_path + "/" + f)
		f = dir.get_next()
	dir.list_dir_end()
	return out

func _err(path: String, msg: String) -> int:
	printerr("  [%s] %s" % [path.get_file(), msg])
	return 1

func _validate_cards(dir_path: String) -> int:
	var errors := 0
	var files := _list_tres(dir_path)
	if files.is_empty():
		return _err(dir_path, "카드 .tres가 없음")
	for path in files:
		var res = ResourceLoader.load(path)
		if res == null:
			errors += _err(path, "로드 실패")
			continue
		for msg in card_errors(res):
			errors += _err(path, msg)
	if errors == 0:
		print("  cards: %d개 OK" % files.size())
	return errors

static func card_errors(res: Resource) -> PackedStringArray:
	var errors := PackedStringArray()
	if res == null:
		errors.append("로드 실패")
		return errors
	var card_type := String(res.get("card_type"))
	if String(res.get("id")) == "":
		errors.append("id 비어 있음")
	if String(res.get("display_name")) == "":
		errors.append("display_name 비어 있음")
	if _int_property(res, "cost", 0) < 0:
		errors.append("cost는 음수일 수 없음")
	if not CardVocab.is_in(String(res.get("realm")), CardVocab.REALMS):
		errors.append("realm 값 오류: %s" % res.get("realm"))
	if not CardVocab.is_in(String(res.get("nation")), CardVocab.NATIONS):
		errors.append("nation 값 오류: %s" % res.get("nation"))
	if not CardVocab.is_in(card_type, CardVocab.CARD_TYPES):
		errors.append("card_type 값 오류: %s" % res.get("card_type"))
	if not CardVocab.is_in(String(res.get("fantasy_tier")), CardVocab.FANTASY_TIERS):
		errors.append("fantasy_tier 값 오류: %s" % res.get("fantasy_tier"))
	if card_type in ["general", "troop"]:
		_append_unit_errors(errors, res)
	elif card_type == "scheme":
		_append_scheme_errors(errors, res)
	elif card_type == "treasure":
		_append_treasure_errors(errors, res)
	return errors

static func _append_unit_errors(errors: PackedStringArray, res: Resource) -> void:
	if not CardVocab.is_in(String(res.get("troop_type")), CardVocab.TROOP_TYPES):
		errors.append("troop_type 값 오류: %s" % res.get("troop_type"))
	if not CardVocab.is_in(String(res.get("attack_range")), CardVocab.ATTACK_RANGES):
		errors.append("attack_range 값 오류: %s" % res.get("attack_range"))
	if not CardVocab.is_in(String(res.get("target_rule")), CardVocab.TARGET_RULES):
		errors.append("target_rule 값 오류: %s" % res.get("target_rule"))
	if _int_property(res, "max_hp", 0) <= 0:
		errors.append("max_hp는 0보다 커야 함")
	if _int_property(res, "attack", 0) < 0:
		errors.append("attack은 음수일 수 없음")

static func _append_scheme_errors(errors: PackedStringArray, res: Resource) -> void:
	if not (res is SchemeCardData):
		errors.append("scheme 카드는 SchemeCardData여야 함")
	var effect_id := _string_name_property(res, "effect_id")
	if effect_id == &"":
		errors.append("scheme effect_id 비어 있음")
	elif not _SchemeCatalog.has_effect(effect_id):
		errors.append("scheme effect_id registry 미등록: %s" % effect_id)

static func _append_treasure_errors(errors: PackedStringArray, res: Resource) -> void:
	if not (res is TreasureCardData):
		errors.append("treasure 카드는 TreasureCardData여야 함")
	var effect_id := _string_name_property(res, "effect_id")
	if effect_id == &"":
		errors.append("treasure effect_id 비어 있음")
	elif not _TreasureCatalog.has_effect(effect_id):
		errors.append("treasure effect_id registry 미등록: %s" % effect_id)
	if _int_property(res, "stack_limit", 0) < 1:
		errors.append("treasure stack_limit은 1 이상이어야 함")

static func _string_name_property(res: Resource, property_name: String) -> StringName:
	var value = res.get(property_name)
	if value == null:
		return &""
	return StringName(value)

static func _int_property(res: Resource, property_name: String, default_value: int) -> int:
	var value = res.get(property_name)
	if value == null:
		return default_value
	return int(value)

func _validate_lords(dir_path: String) -> int:
	var errors := 0
	var files := _list_tres(dir_path)
	if files.is_empty():
		return _err(dir_path, "군주 .tres가 없음")
	for path in files:
		var res = ResourceLoader.load(path)
		if res == null:
			errors += _err(path, "로드 실패")
			continue
		if String(res.get("id")) == "":
			errors += _err(path, "id 비어 있음")
		var gens: PackedStringArray = res.get("starting_general_ids")
		var troops: PackedStringArray = res.get("starting_troop_ids")
		# 군주 시작 덱 최소 — 장수 2종 이상·병종 3종 이상·총 6장 이상.
		if gens.size() < 2:
			errors += _err(path, "starting_general_ids < 2 (군주는 장수 2종 이상 필요)")
		if troops.size() < 3:
			errors += _err(path, "starting_troop_ids < 3 (군주는 병종 3종 이상 필요)")
		if gens.size() + troops.size() < 6:
			errors += _err(path, "starting deck < 6 (첫 전투 기준 최소 6장 필요)")
	if errors == 0:
		print("  lords: %d개 OK" % files.size())
	return errors
