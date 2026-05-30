# 전투 시뮬레이션 헤드리스 스모크 테스트 — 결정적 결과를 검증한다.
# 실행 — godot --headless --path . --script res://tools/sim_smoke.gd
extends SceneTree

func _initialize() -> void:
	var errors := 0
	var cat := CardCatalog.new()
	cat.load_all()
	var lord := cat.get_lord(&"lord_liubei")
	if lord == null:
		errors += _fail("유비 군주 로드 실패")
	else:
		errors += _case_player_wins(cat, lord)
		errors += _case_player_loses(cat, lord)
	if errors == 0:
		print("✅ 전투 시뮬레이션 검증 통과")
		quit(0)
	else:
		printerr("❌ 전투 시뮬레이션 검증 실패: %d건" % errors)
		quit(1)

func _fail(msg: String) -> int:
	printerr("  ", msg)
	return 1

# 시작 덱 전체(장수3·병종3)를 3×3 시작 진형에 배치하면 기본 파도를 막아낸다(승리).
func _case_player_wins(cat: CardCatalog, lord: LordData) -> int:
	var sim := BattleSim.new()
	var castle := sim.add_castle()
	var deck := cat.get_lord_deck(lord)
	var tile := 0
	for card_id in deck:
		var col := tile % BattleSim.LANE_COUNT
		var row := int(tile / BattleSim.LANE_COUNT)
		var start := BattleSim.position_for_tile(col, row)
		var unit := cat.build_player_unit(card_id, col, start.x, lord)
		unit.row = row
		unit.set_position(start.x, start.y)
		sim.add_unit(unit)
		tile += 1
	sim.set_waves(WaveFactory.default_waves())
	var res := sim.run_to_completion(0.1, 120.0)
	if res != BattleSim.Result.PLAYER_WIN:
		return _fail("승리 시나리오인데 결과=%d (%.1fs, 적잔존=%d, 성HP=%d)" % [res, sim.elapsed, sim.enemy_units.size(), castle.hp])
	if not castle.is_alive():
		return _fail("승리 시나리오에서 성이 파괴됨")
	print("  승리 시나리오 OK (%.1fs, 성HP %d, 아군잔존 %d)" % [sim.elapsed, castle.hp, sim.player_units.size()])
	return 0

# 아무도 배치하지 않으면 성이 노출되어 파괴되고 패배한다.
func _case_player_loses(_cat: CardCatalog, _lord: LordData) -> int:
	var sim := BattleSim.new()
	var castle := sim.add_castle(300)
	sim.set_waves([WaveFactory.wave_one()])
	var res := sim.run_to_completion(0.1, 120.0)
	if res != BattleSim.Result.PLAYER_LOSE:
		return _fail("패배 시나리오인데 결과=%d (성HP=%d)" % [res, castle.hp])
	if castle.is_alive():
		return _fail("패배 시나리오에서 성이 살아있음 (성HP=%d)" % castle.hp)
	print("  패배 시나리오 OK (%.1fs, 성 파괴)" % sim.elapsed)
	return 0
