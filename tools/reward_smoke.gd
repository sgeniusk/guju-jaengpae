# 전리(보상)·덱 영속 헤드리스 스모크 — RunState/RewardPool 로직을 검증한다.
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
	if run.deck.size() != 6:
		e += _fail("시작 덱이 6장이 아님: %d" % run.deck.size())
	var elig := RewardPool.eligible(cat, run.deck)
	print("  시작 덱 %d장, 보상 후보 %d장" % [run.deck.size(), elig.size()])
	if elig.is_empty():
		return e + _fail("보상 후보가 없음 (보상 카드를 추가했는지 확인)")
	for id in elig:
		if run.deck.has(id):
			e += _fail("후보 %s 가 이미 덱에 있음" % id)
	# 한 장 획득 → 덱 +1, 후보에서 제거
	var picked: StringName = elig[0]
	var before := run.deck.size()
	run.add_card(picked)
	if run.deck.size() != before + 1:
		e += _fail("획득 후 덱 크기가 +1이 아님")
	if not run.has_card(picked):
		e += _fail("획득 카드가 덱에 없음")
	var elig2 := RewardPool.eligible(cat, run.deck)
	if elig2.has(picked):
		e += _fail("획득한 카드가 후보에 여전히 남음")
	if elig2.size() != elig.size() - 1:
		e += _fail("획득 후 후보 수가 1 줄지 않음")
	if e == 0:
		print("  획득 %s → 덱 %d장, 남은 후보 %d장 OK" % [picked, run.deck.size(), elig2.size()])
	return e
