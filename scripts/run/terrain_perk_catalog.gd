# 군주별 지형 특전과 타일 보너스를 모으는 순수 helper.
class_name TerrainPerkCatalog
extends RefCounted

const TERRAIN_SHU := &"terrain_shu_hometown"
const TERRAIN_WEI := &"terrain_wei_commandery"
const TERRAIN_WU := &"terrain_wu_waterway"

static func id_for_lord(lord: LordData) -> StringName:
	if lord == null:
		return TERRAIN_SHU
	match lord.nation:
		&"wei":
			return TERRAIN_WEI
		&"wu":
			return TERRAIN_WU
		_:
			return TERRAIN_SHU

static func info(id: StringName) -> Dictionary:
	match id:
		TERRAIN_WEI:
			return {
				"id": TERRAIN_WEI,
				"name": "군령 평원",
				"text": "성 같은 행에 배치한 아군은 공격력 +15%",
			}
		TERRAIN_WU:
			return {
				"id": TERRAIN_WU,
				"name": "강동 수로",
				"text": "좌우 가장자리 칸의 아군은 공격력 +15%",
			}
		_:
			return {
				"id": TERRAIN_SHU,
				"name": "인덕 향리",
				"text": "성에 인접한 아군은 체력 +20%",
			}

static func bonus_for_tile(id: StringName, col: int, row: int, castle_key: String) -> Dictionary:
	match id:
		TERRAIN_WEI:
			return {"attack_mult": 1.15} if row == row_from_key(castle_key) else {}
		TERRAIN_WU:
			return {"attack_mult": 1.15} if col == 0 or col == BattleSim.COL_COUNT - 1 else {}
		TERRAIN_SHU:
			return {"hp_mult": 1.20} if is_adjacent_to_castle(col, row, castle_key) else {}
	return {}

static func apply_to_unit(unit: BattleUnit, id: StringName, col: int, row: int, castle_key: String) -> void:
	if unit == null or unit.is_castle or id == &"":
		return
	var bonus := bonus_for_tile(id, col, row, castle_key)
	if bonus.has("hp_mult"):
		var new_hp := maxi(1, int(round(float(unit.max_hp) * float(bonus.get("hp_mult", 1.0)))))
		unit.max_hp = new_hp
		unit.hp = new_hp
	if bonus.has("attack_mult"):
		unit.attack = maxi(0, int(round(float(unit.attack) * float(bonus.get("attack_mult", 1.0)))))

static func is_adjacent_to_castle(col: int, row: int, castle_key: String) -> bool:
	var castle_col := col_from_key(castle_key)
	var castle_row := row_from_key(castle_key)
	if castle_col < 0 or castle_row < 0:
		return false
	return absi(col - castle_col) + absi(row - castle_row) == 1

static func col_from_key(key: String) -> int:
	var parts := key.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int():
		return -1
	return int(parts[0])

static func row_from_key(key: String) -> int:
	var parts := key.split(":")
	if parts.size() != 2 or not parts[1].is_valid_int():
		return -1
	return int(parts[1])
