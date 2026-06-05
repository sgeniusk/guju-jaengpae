# 군주별 전략 덱 풀. 전투 화면에는 여기서 매번 3장만 보인다.
class_name StrategyDeckCatalog
extends RefCounted

const TARGET_POOL_SIZE := 12

static func deck_for_lord(lord: LordData) -> Array[StringName]:
	if lord == null:
		return []
	match lord.id:
		&"lord_liubei":
			return [
				&"general_guanyu",
				&"troop_infantry",
				&"troop_archer",
				&"general_zhangfei",
				&"general_zhaoyun",
				&"general_huangzhong",
				&"troop_infantry",
				&"troop_archer",
				&"building_dunjeon",
				&"building_mangru",
				&"scheme_levy",
				&"scheme_fortify",
			]
		&"lord_caocao":
			return [
				&"general_caocao",
				&"troop_cavalry",
				&"troop_crossbow",
				&"general_xiahoudun",
				&"troop_cavalry",
				&"troop_crossbow",
				&"troop_infantry",
				&"troop_infantry",
				&"building_mangru",
				&"building_dunjeon",
				&"scheme_raid",
				&"scheme_fortify",
			]
		&"lord_sunquan":
			return [
				&"general_sunquan",
				&"troop_navy",
				&"troop_archer",
				&"general_zhouyu",
				&"troop_navy",
				&"troop_archer",
				&"troop_crossbow",
				&"troop_crossbow",
				&"building_dunjeon",
				&"building_mangru",
				&"scheme_fortify",
				&"scheme_levy",
			]
	var out: Array[StringName] = []
	for id in lord.starting_general_ids:
		out.append(StringName(id))
	for id in lord.starting_troop_ids:
		out.append(StringName(id))
	while out.size() > TARGET_POOL_SIZE:
		out.pop_back()
	return out

static func class_counts(deck: Array[StringName], catalog: CardCatalog) -> Dictionary:
	var counts := {
		"general": 0,
		"troop": 0,
		"building": 0,
		"scheme": 0,
		"treasure": 0,
		"unknown": 0,
	}
	for id in deck:
		var card := catalog.get_card(StringName(id)) if catalog != null else null
		var card_type := String(card.get("card_type")) if card != null else "unknown"
		if counts.has(card_type):
			counts[card_type] = int(counts[card_type]) + 1
		else:
			counts["unknown"] = int(counts["unknown"]) + 1
	return counts
