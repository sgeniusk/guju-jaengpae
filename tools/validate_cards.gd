# 카드·군주 Resource를 헤드리스로 로드해 스키마 일관성을 검증하는 도구.
# 실행 — godot --headless --path . --script res://tools/validate_cards.gd
extends SceneTree

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
		if String(res.get("id")) == "":
			errors += _err(path, "id 비어 있음")
		if String(res.get("display_name")) == "":
			errors += _err(path, "display_name 비어 있음")
		if not CardVocab.is_in(String(res.get("realm")), CardVocab.REALMS):
			errors += _err(path, "realm 값 오류: %s" % res.get("realm"))
		if not CardVocab.is_in(String(res.get("nation")), CardVocab.NATIONS):
			errors += _err(path, "nation 값 오류: %s" % res.get("nation"))
		if not CardVocab.is_in(String(res.get("card_type")), CardVocab.CARD_TYPES):
			errors += _err(path, "card_type 값 오류: %s" % res.get("card_type"))
		if not CardVocab.is_in(String(res.get("fantasy_tier")), CardVocab.FANTASY_TIERS):
			errors += _err(path, "fantasy_tier 값 오류: %s" % res.get("fantasy_tier"))
		# 유닛 카드(장수·병종) 전투 스탯 검증
		if String(res.get("card_type")) in ["general", "troop"]:
			if not CardVocab.is_in(String(res.get("troop_type")), CardVocab.TROOP_TYPES):
				errors += _err(path, "troop_type 값 오류: %s" % res.get("troop_type"))
			if not CardVocab.is_in(String(res.get("attack_range")), CardVocab.ATTACK_RANGES):
				errors += _err(path, "attack_range 값 오류: %s" % res.get("attack_range"))
			if not CardVocab.is_in(String(res.get("target_rule")), CardVocab.TARGET_RULES):
				errors += _err(path, "target_rule 값 오류: %s" % res.get("target_rule"))
			if int(res.get("max_hp")) <= 0:
				errors += _err(path, "max_hp는 0보다 커야 함")
			if int(res.get("attack")) < 0:
				errors += _err(path, "attack은 음수일 수 없음")
	if errors == 0:
		print("  cards: %d개 OK" % files.size())
	return errors

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
		# 군주 시작 덱 최소 — 장수 2종 이상·병종 3종 이상 (위·오 군주는 장수 2종으로 시작)
		if gens.size() < 2:
			errors += _err(path, "starting_general_ids < 2 (군주는 장수 2종 이상 필요)")
		if troops.size() < 3:
			errors += _err(path, "starting_troop_ids < 3 (군주는 병종 3종 이상 필요)")
	if errors == 0:
		print("  lords: %d개 OK" % files.size())
	return errors
