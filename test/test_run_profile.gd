# RunManager는 전투 결과를 ProfileState에 기록하고 다음 런 해금을 이어준다.
extends TestCase

const TEST_PROFILE_PATH := "user://guju_test_profile.cfg"
const TEST_PROFILE_FILE := "guju_test_profile.cfg"
const _PersistenceStore := preload("res://scripts/run/persistence_store.gd")

func before_each() -> void:
	_remove_test_profile_file()
	RunManager.reset_run()
	RunManager.reset_profile()
	RunManager.ensure_started(&"lord_liubei")

func test_loss_records_stage_and_score_without_unlocks() -> void:
	RunManager.state.stage_index = 3
	RunManager.state.gold = 20
	RunManager.state.hand = [&"troop_infantry"]

	var outcome := RunManager.record_battle_outcome(false)
	falsy(outcome.get("win", true), "패배 결과")
	eq(outcome.get("stage"), 3, "결과 stage")
	eq(outcome.get("run_result"), "defeat", "패배는 run_result defeat")
	truthy(outcome.get("run_complete"), "패배는 런 종료")
	falsy(outcome.get("run_victory"), "패배는 런 승리 아님")
	eq(outcome.get("score"), 323, "패배 점수는 stage/gold/hand 기반")
	eq((outcome.get("unlocked_lords") as Array).size(), 0, "패배는 군주 해금 없음")
	eq(RunManager.get_profile().best_stage, 3, "profile best_stage 기록")
	eq(RunManager.get_profile().best_score, 323, "profile best_score 기록")

func test_boss_win_unlocks_next_lord_once_and_persists_across_new_run() -> void:
	RunManager.state.stage_index = 5
	RunManager.state.gold = 10
	RunManager.state.board = {"0:0": &"general_zhaoyun", "1:0": &"troop_infantry"}
	RunManager.state.hand = []

	var outcome := RunManager.record_battle_outcome(true)
	truthy(outcome.get("win", false), "승리 결과")
	eq(outcome.get("run_result"), "ongoing", "첫 보스 승리는 런 진행 중")
	falsy(outcome.get("run_complete"), "첫 보스 승리는 런 종료 아님")
	falsy(outcome.get("run_victory"), "첫 보스 승리는 최종 승리 아님")
	eq(outcome.get("score"), 1030, "승리 점수는 win bonus 포함")
	eq(outcome.get("unlocked_lords"), [&"lord_caocao"], "stage 5 승리로 조조 해금")
	truthy(RunManager.get_profile().is_lord_unlocked(&"lord_caocao"), "profile 조조 해금")

	var repeat := RunManager.record_battle_outcome(true)
	eq(repeat.get("unlocked_lords"), [], "이미 해금된 군주는 반복 표시 없음")

	RunManager.reset_run()
	truthy(RunManager.get_profile().is_lord_unlocked(&"lord_caocao"), "새 런을 시작해도 프로필 해금 유지")
	falsy(RunManager.state.started, "런 상태만 초기화")

func test_later_boss_win_unlocks_remaining_current_lords() -> void:
	RunManager.state.stage_index = 10

	var outcome := RunManager.record_battle_outcome(true)
	eq(outcome.get("unlocked_lords"), [&"lord_caocao", &"lord_sunquan"], "stage 10 승리로 현세 3국 해금")
	eq(outcome.get("run_result"), "ongoing", "stage 10 보스 승리도 런 진행 중")
	falsy(outcome.get("is_final_boss"), "stage 10은 최종 보스 아님")
	truthy(RunManager.get_profile().is_lord_unlocked(&"lord_caocao"), "조조 해금")
	truthy(RunManager.get_profile().is_lord_unlocked(&"lord_sunquan"), "손권 해금")

func test_final_boss_win_marks_run_victory() -> void:
	RunManager.state.stage_index = 15
	truthy(RunManager.is_final_boss_stage(), "RunManager 최종 보스 예측자")

	var outcome := RunManager.record_battle_outcome(true)
	eq(outcome.get("stage"), 15, "최종 보스 stage 기록")
	eq(outcome.get("node_kind"), "boss", "최종 보스 node_kind")
	truthy(outcome.get("is_final_boss"), "stage 15는 최종 보스")
	eq(outcome.get("run_result"), "victory", "최종 보스 승리는 run_result victory")
	truthy(outcome.get("run_victory"), "최종 보스 승리는 런 승리")
	truthy(outcome.get("run_complete"), "런 승리는 종료 상태")
	eq(outcome.get("unlocked_lords"), [&"lord_caocao", &"lord_sunquan"], "최종 보스 승리 시 현세 해금도 유지")

func test_last_battle_outcome_is_a_copy() -> void:
	RunManager.state.stage_index = 5
	var outcome := RunManager.record_battle_outcome(true)
	var copy := RunManager.get_last_battle_outcome()
	(copy.get("unlocked_lords") as Array).append(&"lord_fake")
	eq(outcome.get("unlocked_lords"), [&"lord_caocao"], "원본 outcome은 호출 시점 사본")
	eq(RunManager.get_last_battle_outcome().get("unlocked_lords"), [&"lord_caocao"], "저장된 outcome도 외부 변경 방지")

func test_reward_candidates_follow_profile_unlocks() -> void:
	var before := RunManager.reward_candidates(99)
	falsy(before.has(&"general_caocao"), "조조 해금 전 보상 후보 제외")
	falsy(before.has(&"general_sunquan"), "손권 해금 전 보상 후보 제외")

	RunManager.get_profile().unlock_lord(&"lord_caocao")
	var after_lord := RunManager.reward_candidates(99)
	truthy(after_lord.has(&"general_caocao"), "조조 해금 후 위 장수 후보 포함")
	falsy(after_lord.has(&"general_sunquan"), "오 군주 해금 전 오 장수 제외")

	RunManager.get_profile().unlock_card(&"general_sunquan")
	var after_card := RunManager.reward_candidates(99)
	truthy(after_card.has(&"general_sunquan"), "개별 카드 해금 후 후보 포함")

func test_profile_save_load_preserves_unlocks_records_and_settings() -> void:
	RunManager.state.stage_index = 5
	RunManager.state.gold = 10
	RunManager.state.hand = []
	RunManager.record_battle_outcome(true)
	truthy(RunManager.get_profile().set_setting("music", true), "설정 저장")
	truthy(RunManager.get_profile().unlock_card(&"scheme_raid"), "개별 카드 해금")
	truthy(RunManager.save_profile(TEST_PROFILE_PATH), "명시 프로필 저장")

	RunManager.reset_profile()
	falsy(RunManager.get_profile().is_lord_unlocked(&"lord_caocao"), "로드 전 조조 잠김")
	truthy(RunManager.load_profile(TEST_PROFILE_PATH), "명시 프로필 로드")
	truthy(RunManager.get_profile().is_lord_unlocked(&"lord_caocao"), "조조 해금 복구")
	truthy(RunManager.get_profile().is_card_unlocked(&"scheme_raid"), "카드 해금 복구")
	eq(RunManager.get_profile().best_stage, 5, "best stage 복구")
	eq(RunManager.get_profile().best_score, 1010, "best score 복구")
	eq(RunManager.get_profile().setting("music"), true, "설정 복구")
	truthy(RunManager.clear_profile_save(TEST_PROFILE_PATH), "프로필 저장 삭제")
	falsy(RunManager.has_profile_save(TEST_PROFILE_PATH), "삭제 후 저장 없음")

func test_profile_load_rejects_newer_major_without_mutating_current_profile() -> void:
	truthy(RunManager.get_profile().unlock_lord(&"lord_caocao"), "기존 조조 해금")
	RunManager.get_profile().best_stage = 4
	var payload := {
		"save_version": "2.0.0",
		"unlocked_lord_ids": ["lord_sunquan"],
		"best_stage": 99,
	}
	eq(_save_profile_payload(payload), OK, "newer profile payload 저장")

	falsy(RunManager.load_profile(TEST_PROFILE_PATH), "newer major 프로필 로드 거부")
	truthy(RunManager.get_profile().is_lord_unlocked(&"lord_caocao"), "기존 조조 해금 유지")
	falsy(RunManager.get_profile().is_lord_unlocked(&"lord_sunquan"), "거부된 손권 해금 미반영")
	eq(RunManager.get_profile().best_stage, 4, "거부 후 best stage 유지")

func _save_profile_payload(payload: Dictionary) -> int:
	return _PersistenceStore.save_profile_payload(payload, TEST_PROFILE_PATH)

func _remove_test_profile_file() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists(TEST_PROFILE_FILE):
		dir.remove(TEST_PROFILE_FILE)
