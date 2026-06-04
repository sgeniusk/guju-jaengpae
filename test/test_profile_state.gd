# ProfileState는 영구 해금, 최고 기록, 설정의 의미 owner다.
extends TestCase

func test_default_profile_unlocks_starting_lord() -> void:
	var profile := ProfileState.new_default()
	eq(profile.unlocked_lord_ids, [&"lord_liubei"], "기본 프로필은 유비를 해금")
	eq(profile.unlocked_card_ids, [], "기본 카드 해금은 비어 있음")
	truthy(profile.is_lord_unlocked(&"lord_liubei"), "유비 해금 조회")
	falsy(profile.is_lord_unlocked(&"lord_caocao"), "조조는 아직 잠김")
	eq(profile.best_stage, 0, "기본 최고 스테이지")
	eq(profile.best_score, 0, "기본 최고 점수")
	eq(profile.settings, {}, "기본 설정")

func test_new_default_profile_roundtrips_as_new_profile_payload() -> void:
	var payload := ProfileState.new_default().to_dict()
	var restored := ProfileState.new()
	truthy(restored.from_dict(payload), "신규 프로필 payload 로드")
	eq(restored.unlocked_lord_ids, [&"lord_liubei"], "신규 프로필 시작 군주 보존")
	eq(restored.unlocked_card_ids, [], "신규 프로필 카드 해금 기본값")
	eq(restored.best_stage, 0, "신규 프로필 stage 기본값")
	eq(restored.best_score, 0, "신규 프로필 score 기본값")

func test_unlock_lord_and_card_are_unique() -> void:
	var profile := ProfileState.new()
	truthy(profile.unlock_lord(&"lord_caocao"), "새 군주 해금")
	falsy(profile.unlock_lord(&"lord_caocao"), "중복 군주 해금은 변화 없음")
	falsy(profile.unlock_lord(&""), "빈 군주 id는 무시")
	truthy(profile.unlock_card(&"scheme_raid"), "새 카드 해금")
	falsy(profile.unlock_card(&"scheme_raid"), "중복 카드 해금은 변화 없음")
	falsy(profile.unlock_card(&""), "빈 카드 id는 무시")
	eq(profile.unlocked_lord_ids, [&"lord_caocao"], "군주 해금 목록 dedupe")
	eq(profile.unlocked_card_ids, [&"scheme_raid"], "카드 해금 목록 dedupe")
	truthy(profile.is_card_unlocked(&"scheme_raid"), "카드 해금 조회")

func test_record_result_keeps_best_stage_and_score() -> void:
	var profile := ProfileState.new()
	truthy(profile.record_result(3, 100), "첫 기록 저장")
	eq(profile.best_stage, 3, "best_stage 저장")
	eq(profile.best_score, 100, "best_score 저장")
	truthy(profile.record_result(2, 120), "점수만 갱신")
	eq(profile.best_stage, 3, "낮은 stage는 무시")
	eq(profile.best_score, 120, "높은 score는 갱신")
	truthy(profile.record_result(4, 90), "stage만 갱신")
	eq(profile.best_stage, 4, "높은 stage 갱신")
	eq(profile.best_score, 120, "낮은 score는 무시")
	falsy(profile.record_result(-1, -1), "낮은 기록은 변화 없음")

func test_settings_accept_only_primitive_values() -> void:
	var profile := ProfileState.new()
	truthy(profile.set_setting("music", true), "bool 설정 저장")
	truthy(profile.set_setting("volume", 0.75), "float 설정 저장")
	truthy(profile.set_setting("labels", [&"fast", "readable"]), "Array 설정 저장")
	falsy(profile.set_setting("", true), "빈 key는 무시")
	falsy(profile.set_setting("resource", RunState.new()), "Resource 설정은 거부")
	eq(profile.setting("music"), true, "설정 조회")
	almost(float(profile.setting("volume", 0.0)), 0.75, 0.0001, "float 설정 조회")
	eq((profile.setting("labels") as Array)[0], "fast", "StringName 설정은 String으로 저장")
	eq(profile.setting("missing", "fallback"), "fallback", "기본값 조회")
	falsy(profile.settings.has("resource"), "거부된 설정은 저장되지 않음")
	truthy(profile.erase_setting("music"), "설정 삭제")
	falsy(profile.erase_setting("music"), "이미 삭제된 설정")

func test_from_dict_deduplicates_unlocks_and_sanitizes_settings() -> void:
	var profile := ProfileState.new()
	truthy(profile.from_dict({
		"save_version": ProfileState.SAVE_VERSION,
		"unlocked_lord_ids": ["lord_liubei", "lord_liubei", "", "lord_caocao"],
		"unlocked_card_ids": ["scheme_raid", "scheme_raid", "treasure_jinyin"],
		"best_stage": 5,
		"best_score": 80,
		"settings": {
			"music": true,
			"bad": RunState.new(),
			"nested": {"label": &"compact"},
		},
	}), "profile payload 로드")
	eq(profile.unlocked_lord_ids, [&"lord_liubei", &"lord_caocao"], "군주 해금 dedupe")
	eq(profile.unlocked_card_ids, [&"scheme_raid", &"treasure_jinyin"], "카드 해금 dedupe")
	eq(profile.best_stage, 5, "stage 로드")
	eq(profile.best_score, 80, "score 로드")
	truthy(profile.settings.get("music"), "primitive 설정 유지")
	falsy(profile.settings.has("bad"), "비저장 설정 제거")
	eq((profile.settings.get("nested") as Dictionary).get("label"), "compact", "중첩 StringName은 String으로 저장")

func test_missing_unknown_profile_payload_uses_safe_defaults() -> void:
	var profile := ProfileState.new()
	truthy(profile.from_dict({
		"unknown_future_field": "ignored",
		"best_stage": -3,
		"best_score": -9,
	}), "missing/unknown profile payload 로드")
	eq(profile.unlocked_lord_ids, [], "missing lord unlock 기본값")
	eq(profile.unlocked_card_ids, [], "missing card unlock 기본값")
	eq(profile.best_stage, 0, "best_stage 보정")
	eq(profile.best_score, 0, "best_score 보정")
	eq(profile.settings, {}, "missing settings 기본값")

func test_newer_profile_payload_fails_without_mutation() -> void:
	var profile := ProfileState.new_default()
	profile.best_stage = 4
	profile.best_score = 120
	falsy(profile.from_dict({
		"save_version": "2.0.0",
		"unlocked_lord_ids": ["lord_caocao"],
		"best_stage": 99,
		"best_score": 999,
	}), "newer major profile payload 거부")
	eq(profile.unlocked_lord_ids, [&"lord_liubei"], "거부 후 군주 해금 유지")
	eq(profile.best_stage, 4, "거부 후 stage 유지")
	eq(profile.best_score, 120, "거부 후 score 유지")
