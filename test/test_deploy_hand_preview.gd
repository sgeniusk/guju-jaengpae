# 다음 전투 배치 손패 preview가 실제 prepare와 같은 순서로 계산되는지 검증한다.
extends TestCase

func test_deploy_hand_preview_matches_prepare_without_mutating_state() -> void:
	var run := RunState.new()
	run.start_run(CardLibrary.get_lord(&"lord_liubei"), CardLibrary.catalog)
	var starting_hand := run.hand.duplicate()
	eq(run.deploy_hand_preview(), starting_hand, "이미 준비된 stage는 현재 손패 preview")
	run.advance_stage()
	var hand_before := run.hand.duplicate()
	var draw_before := run.draw_pile.duplicate()
	var preview := run.deploy_hand_preview()
	eq(preview.size(), RunState.HAND_DRAW_COUNT, "다음 stage preview 3장")
	eq(run.hand, hand_before, "preview는 손패 불변")
	eq(run.draw_pile, draw_before, "preview는 draw pile 불변")
	truthy(run.prepare_deploy_hand(), "실제 prepare 실행")
	eq(run.hand, preview, "실제 prepare 결과와 preview 일치")
