# lord_select는 ProfileState 해금 상태에 따라 군주 버튼을 잠그거나 연다.
extends TestCase

const _LordSelectScreen := preload("res://scripts/screens/lord_select.gd")

func before_each() -> void:
	CardLibrary.catalog.load_all()
	RunManager.reset_run()
	RunManager.reset_profile()

func test_lord_buttons_follow_profile_unlocks() -> void:
	var screen := _LordSelectScreen.new()
	var liubei_button := screen._build_lord_button(CardLibrary.get_lord(&"lord_liubei"))
	falsy(liubei_button.disabled, "기본 군주는 선택 가능")
	truthy(_has_label(liubei_button, "해금됨"), "기본 군주 상태 표시")
	truthy(liubei_button.tooltip_text.find("선택하면 새 런") >= 0, "해금 군주 tooltip은 새 런 시작 안내")
	liubei_button.free()

	var caocao_button := screen._build_lord_button(CardLibrary.get_lord(&"lord_caocao"))
	truthy(caocao_button.disabled, "잠긴 군주는 선택 불가")
	truthy(_has_label(caocao_button, "잠김"), "잠김 상태 표시")
	truthy(caocao_button.tooltip_text.find("보스 승리") >= 0, "잠긴 군주 tooltip은 해금 조건 안내")
	caocao_button.free()

	RunManager.get_profile().unlock_lord(&"lord_caocao")
	var unlocked_button := screen._build_lord_button(CardLibrary.get_lord(&"lord_caocao"))
	falsy(unlocked_button.disabled, "해금 후 선택 가능")
	truthy(_has_label(unlocked_button, "해금됨"), "해금 상태 표시")
	truthy(unlocked_button.tooltip_text.find("선택하면 새 런") >= 0, "해금된 추가 군주 tooltip 갱신")
	unlocked_button.free()
	screen.free()

func test_lord_panels_are_catalog_driven() -> void:
	var probe := LordData.new()
	probe.id = &"lord_catalog_probe"
	probe.display_name = "카탈로그 군주"
	probe.realm = "mortal"
	probe.nation = &"shu"
	probe.trait_name = "목록 검증"
	CardLibrary.catalog.lords[probe.id] = probe
	RunManager.get_profile().unlock_lord(probe.id)

	var screen := _LordSelectScreen.new()
	screen._build_root()
	screen._build_lord_panels()
	truthy(_has_label(screen, "카탈로그 군주"), "lord_select는 카탈로그에 추가된 군주도 렌더")
	screen.free()

func _has_label(node: Node, text: String) -> bool:
	if node is Label and (node as Label).text == text:
		return true
	for child in node.get_children():
		if _has_label(child, text):
			return true
	return false
