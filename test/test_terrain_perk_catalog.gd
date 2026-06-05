extends TestCase

const TerrainPerkCatalog := preload("res://scripts/run/terrain_perk_catalog.gd")

func test_lord_maps_to_faction_terrain_perk() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	eq(TerrainPerkCatalog.id_for_lord(cat.get_lord(&"lord_liubei")), TerrainPerkCatalog.TERRAIN_SHU, "유비는 촉 향리")
	eq(TerrainPerkCatalog.id_for_lord(cat.get_lord(&"lord_caocao")), TerrainPerkCatalog.TERRAIN_WEI, "조조는 위 군령")
	eq(TerrainPerkCatalog.id_for_lord(cat.get_lord(&"lord_sunquan")), TerrainPerkCatalog.TERRAIN_WU, "손권은 오 수로")

func test_shu_perk_buffs_castle_adjacent_hp() -> void:
	var unit := BattleUnit.make(BattleUnit.Team.PLAYER, 0, 0.0, "보병", 100, 10, 1.0, "melee", 0.0)
	TerrainPerkCatalog.apply_to_unit(unit, TerrainPerkCatalog.TERRAIN_SHU, 1, 0, "1:1")
	eq(unit.max_hp, 120, "성 인접 칸 체력 +20%")
	eq(unit.hp, 120, "현재 체력도 보정")

func test_wei_and_wu_perks_buff_attack_by_position() -> void:
	var wei := BattleUnit.make(BattleUnit.Team.PLAYER, 0, 0.0, "기병", 100, 20, 1.0, "melee", 0.0)
	TerrainPerkCatalog.apply_to_unit(wei, TerrainPerkCatalog.TERRAIN_WEI, 0, 2, "1:2")
	eq(wei.attack, 23, "성 같은 행 공격 +15%")

	var wu := BattleUnit.make(BattleUnit.Team.PLAYER, 0, 0.0, "수군", 100, 20, 1.0, "melee", 0.0)
	TerrainPerkCatalog.apply_to_unit(wu, TerrainPerkCatalog.TERRAIN_WU, 2, 1, "1:1")
	eq(wu.attack, 23, "가장자리 공격 +15%")

func test_non_matching_tiles_do_not_change_stats() -> void:
	var unit := BattleUnit.make(BattleUnit.Team.PLAYER, 0, 0.0, "보병", 100, 20, 1.0, "melee", 0.0)
	TerrainPerkCatalog.apply_to_unit(unit, TerrainPerkCatalog.TERRAIN_WEI, 0, 0, "1:2")
	eq(unit.max_hp, 100, "비대상 칸 체력 불변")
	eq(unit.attack, 20, "비대상 칸 공격 불변")
