# 전투 스크린샷 하네스가 실제 교전 phase로 진입 가능한 런 상태를 만드는지 검증한다.
extends TestCase

const _ShootBattle := preload("res://tools/shoot_battle.gd")

func before_each() -> void:
	CardLibrary.catalog.load_all()
	RunManager.reset_run()

func test_demo_board_marks_one_card_played_for_fight_capture() -> void:
	var harness := _ShootBattle.new()

	harness._prepare_target_stage(&"lord_liubei", 5)
	harness._prepare_demo_board(5)

	truthy(RunManager.has_castle(), "전투 촬영 하네스는 성 위치를 준비")
	falsy(RunManager.can_place_deploy_card(), "전투 촬영 하네스는 교전 시작 조건에 맞게 한 수 사용 처리")
	eq(RunManager.state.deploy_cards_played, 1, "직접 배치 후 deploy_cards_played 갱신")
	eq(RunManager.state.deploy_stage_index, 5, "직접 배치 stage index 갱신")
	truthy(_board_unit_count() > 0, "교전 캡처용 보드는 전투할 유닛을 포함")

	harness.free()

func _board_unit_count() -> int:
	var count := 0
	for card_id in RunManager.get_board().values():
		var card := CardLibrary.get_card(StringName(card_id))
		if card is UnitCardData:
			count += 1
	return count
