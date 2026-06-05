# 전리(보상)·손패/owned 영속 헤드리스 스모크 — RunState/RewardPool 로직을 검증한다.
# 실행 — godot --headless --path . --script res://tools/reward_smoke.gd
extends SceneTree

func _initialize() -> void:
	var errors := 0
	var cat := CardCatalog.new()
	cat.load_all()
	var lord := cat.get_lord(&"lord_liubei")
	if lord == null:
		errors += _fail("유비 군주 로드 실패")
	else:
		errors += _run_checks(cat, lord)
	if errors == 0:
		print("✅ 전리 보상 검증 통과")
		quit(0)
	else:
		printerr("❌ 전리 보상 검증 실패: %d건" % errors)
		quit(1)

func _fail(msg: String) -> int:
	printerr("  ", msg)
	return 1

func _run_checks(cat: CardCatalog, lord: LordData) -> int:
	var e := 0
	var run := RunState.new()
	run.start_run(lord, cat)
	if run.board_card_ids().size() != 0:
		e += _fail("시작 보드가 비어 있지 않음: %d" % run.board_card_ids().size())
	if run.hand.size() != RunState.HAND_DRAW_COUNT:
		e += _fail("시작 손패가 3장이 아님: %d" % run.hand.size())
	var expected_draw := cat.get_lord_strategy_deck(lord).size() - RunState.HAND_DRAW_COUNT
	if run.draw_pile.size() != expected_draw:
		e += _fail("전술 드로우 더미가 %d장이 아님: %d" % [expected_draw, run.draw_pile.size()])
	var elig := RewardPool.eligible(cat, run.owned_card_ids())
	print("  시작 손패 %d장, 드로우 %d장, 보상 후보 %d장" % [run.hand.size(), run.draw_pile.size(), elig.size()])
	if elig.is_empty():
		return e + _fail("보상 후보가 없음 (보상 카드를 추가했는지 확인)")
	for id in elig:
		if run.owned_card_ids().has(id):
			var card := cat.get_card(id)
			if not (card is UnitCardData or card is TreasureCardData):
				e += _fail("성장/stack 불가 후보 %s 가 이미 owned에 있음" % id)
	# 한 장 획득 → owned +1, 비유닛이면 후보에서 제거
	var picked: StringName = &"scheme_raid"
	if not elig.has(picked):
		return e + _fail("테스트용 계략 후보가 없음: %s" % picked)
	var before := run.owned_card_ids().size()
	run.add_card(picked)
	if not run.hand.has(picked):
		e += _fail("획득 카드가 손패에 없음")
	if run.owned_card_ids().size() != before + 1:
		e += _fail("획득 후 owned 크기가 +1이 아님")
	if not run.has_card(picked):
		e += _fail("획득 카드가 owned에 없음")
	var elig2 := RewardPool.eligible(cat, run.owned_card_ids())
	if elig2.has(picked):
		e += _fail("획득한 카드가 후보에 여전히 남음")
	if elig2.size() != elig.size() - 1:
		e += _fail("획득 후 후보 수가 1 줄지 않음")
	if e == 0:
		print("  획득 %s → owned %d장, 남은 후보 %d장 OK" % [picked, run.owned_card_ids().size(), elig2.size()])
	return e
