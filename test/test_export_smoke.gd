# export smoke helper keeps the release app verifiable without changing normal play.
extends TestCase

const _ExportSmoke := preload("res://scripts/run/export_smoke.gd")

func before_each() -> void:
	CardLibrary.catalog.load_all()
	RunManager.reset_run()
	RunManager.reset_profile()

func test_first_battle_board_smoke_places_a_unit_from_the_starting_hand() -> void:
	RunManager.ensure_started(&"lord_liubei")
	var hand_before := RunManager.get_hand().size()

	var result := _ExportSmoke.ensure_first_battle_board()

	truthy(result.get("ok", false), "smoke placement succeeds")
	eq(result.get("source", ""), "hand", "first placement comes from hand")
	truthy(RunManager.get_board().has(String(result.get("block_key", ""))), "placed unit occupies reported block")
	eq(RunManager.get_hand().size(), hand_before - 1, "one hand card moved to board")
	truthy(_board_has_unit(), "board contains a battle unit")

func test_first_battle_board_smoke_reuses_existing_unit() -> void:
	RunManager.ensure_started(&"lord_liubei")
	var first := _ExportSmoke.ensure_first_battle_board()
	truthy(first.get("ok", false), "initial placement succeeds")

	var second := _ExportSmoke.ensure_first_battle_board()

	truthy(second.get("ok", false), "existing placement succeeds")
	eq(second.get("source", ""), "existing", "existing unit is reused")
	eq(RunManager.get_board().size(), 1, "helper does not place duplicate units")

func _board_has_unit() -> bool:
	for card_id in RunManager.get_board().values():
		if CardLibrary.get_card(StringName(card_id)) is UnitCardData:
			return true
	return false
