# Phase 4 9세력 확장은 정본 승인 뒤에만 CardVocab과 Resource로 내려간다.
extends TestCase

const WORLDVIEW_PATH := "res://docs/worldview.md"
const SPEC_PATH := "res://docs/specs/feat-034.md"
const APPROVED_NATIONS := ["wei", "shu", "wu"]
const PROPOSED_NATIONS := ["kunlun", "penglai", "ziwei", "huangtian", "luoyang", "wanyao"]

func test_card_vocab_contains_only_current_approved_nations() -> void:
	eq(CardVocab.NATIONS, APPROVED_NATIONS, "현재 승인 nation은 현세 3국")
	for nation in PROPOSED_NATIONS:
		falsy(CardVocab.NATIONS.has(nation), "%s는 승인 전 CardVocab에 없음" % nation)

func test_worldview_marks_heaven_and_demon_names_as_pending_approval() -> void:
	var text := _read_text(WORLDVIEW_PATH)
	truthy(text.contains("천계·마계 제안 — 사용자 승인 대기"), "세계관 정본은 승인 대기 상태를 표시")
	truthy(text.contains("사용자 승인 후 Phase 4"), "nation id 확장은 승인 후 Phase 4로 명시")
	for nation in PROPOSED_NATIONS:
		truthy(text.contains("`%s`" % nation), "%s 제안 id는 worldview에만 기록" % nation)

func test_phase4_spec_preserves_expansion_order() -> void:
	var text := _read_text(SPEC_PATH)
	var last_index := -1
	for step in ["명칭 승인", "docs/worldview.md", "CardVocab.NATIONS", "validator", "Resource", "lord_select"]:
		var index := text.find(step)
		truthy(index > last_index, "%s 순서 유지" % step)
		last_index = index

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text
