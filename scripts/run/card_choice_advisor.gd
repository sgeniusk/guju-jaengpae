# 현재 보드/손패/골드 맥락에서 카드 선택 이유를 계산하는 순수 UI 헬퍼.
class_name CardChoiceAdvisor
extends RefCounted

const MODE_REWARD := "reward"
const MODE_SHOP := "shop"
const _SquadProfile := preload("res://scripts/battle/squad_profile.gd")

static func context(board: Dictionary, board_levels: Dictionary, hand: Array, gold: int, catalog: CardCatalog) -> Dictionary:
	var board_counts := {}
	var troop_types := {}
	var board_unit_count := 0
	var general_count := 0
	var troop_count := 0
	var building_count := 0
	var max_level_by_card := {}
	for key in board.keys():
		var card_id := StringName(board[key])
		board_counts[card_id] = int(board_counts.get(card_id, 0)) + 1
		var level := clampi(int(board_levels.get(String(key), board_levels.get(key, 1))), 1, RunState.CARD_LEVEL_MAX)
		max_level_by_card[card_id] = maxi(int(max_level_by_card.get(card_id, 0)), level)
		var card := catalog.get_card(card_id) if catalog != null else null
		if card == null:
			continue
		if card is UnitCardData:
			board_unit_count += 1
			if String(card.get("card_type")) == "general":
				general_count += 1
			else:
				troop_count += 1
			var troop_type := String(card.get("troop_type"))
			troop_types[troop_type] = int(troop_types.get(troop_type, 0)) + 1
		elif String(card.get("card_type")) == "building":
			building_count += 1
	var hand_counts := {}
	for id in hand:
		var hand_id := StringName(id)
		hand_counts[hand_id] = int(hand_counts.get(hand_id, 0)) + 1
	return {
		"board_counts": board_counts,
		"board_unit_count": board_unit_count,
		"general_count": general_count,
		"troop_count": troop_count,
		"building_count": building_count,
		"troop_types": troop_types,
		"max_level_by_card": max_level_by_card,
		"hand_counts": hand_counts,
		"hand_size": hand.size(),
		"gold": gold,
	}

static func advice_for_card(card: CardData, choice_context: Dictionary, mode: String = MODE_REWARD) -> Dictionary:
	if card == null:
		return _advice("판단 보류", "카드 정보를 불러오지 못했습니다.", 0)
	var can_afford := true
	if mode == MODE_SHOP:
		can_afford = int(choice_context.get("gold", 0)) >= int(card.cost)
	if not can_afford:
		var shortfall := maxi(0, int(card.cost) - int(choice_context.get("gold", 0)))
		return _advice("자금 부족", "%d금 더 필요" % shortfall, -20)
	if card is UnitCardData:
		return _unit_advice(card as UnitCardData, choice_context)
	match String(card.get("card_type")):
		"building":
			return _building_advice(card, choice_context)
		"scheme":
			return _scheme_advice(card as SchemeCardData)
		"treasure":
			return _treasure_advice(card as TreasureCardData)
		_:
			return _advice("전력 후보", "현재 덱에 새 선택지 추가", 1)

static func line_for_card(card: CardData, choice_context: Dictionary, mode: String = MODE_REWARD) -> String:
	var advice := advice_for_card(card, choice_context, mode)
	var detail := String(advice.get("detail", ""))
	if detail.is_empty():
		return "추천 — %s" % String(advice.get("label", "판단 보류"))
	return "추천 — %s · %s" % [String(advice.get("label", "판단 보류")), detail]

static func tooltip_for_card(card: CardData, choice_context: Dictionary, mode: String = MODE_REWARD) -> String:
	var advice := advice_for_card(card, choice_context, mode)
	return "추천 — %s\n%s" % [
		String(advice.get("label", "판단 보류")),
		String(advice.get("detail", "")),
	]

static func comparison_for_card(card: CardData, choice_context: Dictionary, mode: String = MODE_REWARD) -> Dictionary:
	if card == null:
		return _comparison("변화 없음", "카드 정보를 불러오지 못했습니다.", 0)
	if mode == MODE_SHOP and int(choice_context.get("gold", 0)) < int(card.cost):
		var shortfall := maxi(0, int(card.cost) - int(choice_context.get("gold", 0)))
		return _comparison("구매 보류", "%d금 더 모아야 이 선택을 적용할 수 있습니다." % shortfall, -20)
	if card is UnitCardData:
		return _unit_comparison(card as UnitCardData, choice_context)
	match String(card.get("card_type")):
		"building":
			return _building_comparison(card, choice_context)
		"scheme":
			return _scheme_comparison(card as SchemeCardData, choice_context)
		"treasure":
			return _treasure_comparison(card as TreasureCardData)
		_:
			return _comparison("선택지 추가", "현재 런에 새 카드 한 장을 더합니다.", 1)

static func comparison_line_for_card(card: CardData, choice_context: Dictionary, mode: String = MODE_REWARD) -> String:
	var comparison := comparison_for_card(card, choice_context, mode)
	return "비교 — %s" % String(comparison.get("change", "변화 없음"))

static func comparison_tooltip_for_card(card: CardData, choice_context: Dictionary, mode: String = MODE_REWARD) -> String:
	var comparison := comparison_for_card(card, choice_context, mode)
	return "비교 — %s\n%s" % [
		String(comparison.get("change", "변화 없음")),
		String(comparison.get("detail", "")),
	]

static func ranked_ids(ids: Array, choice_context: Dictionary, catalog: CardCatalog, mode: String = MODE_REWARD) -> Array[StringName]:
	var ranked: Array[Dictionary] = []
	for index in ids.size():
		var id := StringName(ids[index])
		var card := catalog.get_card(id) if catalog != null else null
		var advice := advice_for_card(card, choice_context, mode)
		ranked.append({
			"id": id,
			"score": int(advice.get("score", 0)),
			"index": index,
		})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_score := int(a.get("score", 0))
		var b_score := int(b.get("score", 0))
		if a_score == b_score:
			return int(a.get("index", 0)) < int(b.get("index", 0))
		return a_score > b_score
	)
	var out: Array[StringName] = []
	for entry in ranked:
		out.append(StringName(entry.get("id", &"")))
	return out

static func _unit_advice(card: UnitCardData, choice_context: Dictionary) -> Dictionary:
	var max_level_by_card: Dictionary = choice_context.get("max_level_by_card", {})
	var current_level := int(max_level_by_card.get(card.id, 0))
	if current_level > 0 and current_level < RunState.CARD_LEVEL_MAX:
		return _advice("증원 후보", "기존 부대 Lv.%d -> Lv.%d" % [current_level, current_level + 1], 30)
	var card_type := String(card.get("card_type"))
	if card_type == "general":
		if int(choice_context.get("general_count", 0)) <= 0:
			return _advice("지휘 핵심", "장수와 호위병으로 전열 형성", 24)
		if int(choice_context.get("troop_count", 0)) >= 2:
			return _advice("지휘 보강", "병종 군세 위에 장수 화력 추가", 18)
		return _advice("장수 전력", "정예 전투 카드 추가", 14)
	var squad_count := _SquadProfile.base_squad_count(card.troop_type)
	var troop_types: Dictionary = choice_context.get("troop_types", {})
	if int(choice_context.get("board_unit_count", 0)) <= 1:
		return _advice("전열 보강", "%d명 분대 추가" % squad_count, 22)
	if card.troop_type == "archer" and int(troop_types.get("infantry", 0)) > 0:
		return _advice("후열 보강", "보병 뒤에서 원거리 화력", 18)
	if card.troop_type == "cavalry" and int(choice_context.get("troop_count", 0)) >= 2:
		return _advice("측면 돌파", "기동 병종으로 적 후열 압박", 18)
	return _advice("군세 보강", "%d명 분대 추가" % squad_count, 12)

static func _building_advice(card: CardData, choice_context: Dictionary) -> Dictionary:
	if int(card.get("gold_per_sec")) > 0:
		return _advice("경제 확장", "전투 중 초당 %d금 생산" % int(card.get("gold_per_sec")), 20)
	if float(card.get("aura_attack_pct")) > 0.0:
		return _advice("화력 거점", "공격 오라로 배치값 상승", 18)
	if int(choice_context.get("building_count", 0)) <= 0:
		return _advice("거점 구축", "빈칸을 지속 효과 칸으로 전환", 12)
	return _advice("지형 시너지", "보드 효과를 한 칸 더 추가", 10)

static func _scheme_advice(card: SchemeCardData) -> Dictionary:
	match String(card.effect_id):
		"scheme_damage_enemy":
			return _advice("즉시 한 수", "전투 중 적에게 직접 피해", 16)
		"scheme_gain_gold":
			return _advice("군자금 확보", "다음 선택을 위한 골드 확보", 15)
		"scheme_fortify_castle":
			return _advice("성 방어", "위기 때 성 체력 보강", 14)
		_:
			return _advice("전술 카드", "배치 대신 즉시 효과 선택", 10)

static func _treasure_advice(card: TreasureCardData) -> Dictionary:
	match String(card.effect_id):
		"treasure_attack_pct":
			return _advice("지속 화력", "모든 전투의 공격 기대값 상승", 22)
		"treasure_gold_pct":
			return _advice("지속 성장", "런 전체 골드 획득 증가", 21)
		"treasure_reward_bonus":
			return _advice("보상 확장", "전리품 선택지를 넓힘", 23)
		_:
			return _advice("지속 성장", "획득 즉시 런 보정", 16)

static func _unit_comparison(card: UnitCardData, choice_context: Dictionary) -> Dictionary:
	var max_level_by_card: Dictionary = choice_context.get("max_level_by_card", {})
	var current_level := int(max_level_by_card.get(card.id, 0))
	if current_level > 0 and current_level < RunState.CARD_LEVEL_MAX:
		return _unit_upgrade_comparison(card, current_level)
	if current_level >= RunState.CARD_LEVEL_MAX:
		return _comparison("기존 부대 최고 Lv.%d" % current_level, "이미 최고 레벨이라 새 전력 효율이 낮습니다.", 0)
	if String(card.get("card_type")) == "general":
		var before_generals := int(choice_context.get("general_count", 0))
		var profile := _SquadProfile.for_card(card, 1)
		return _comparison(
			"장수 %d -> %d" % [before_generals, before_generals + 1],
			"장수 본체와 호위 %d명이 새 지휘 축을 만듭니다." % int(profile.get("retinue_count", 0)),
			24
		)
	var before_units := int(choice_context.get("board_unit_count", 0))
	var troop_profile := _SquadProfile.for_card(card, 1)
	return _comparison(
		"전투 유닛 %d -> %d" % [before_units, before_units + 1],
		"%d명 분대가 새 보드 칸을 차지하고 진형 보너스 후보가 됩니다." % int(troop_profile.get("squad_count", 1)),
		12
	)

static func _unit_upgrade_comparison(card: UnitCardData, current_level: int) -> Dictionary:
	var next_level := current_level + 1
	var current_profile := _SquadProfile.for_card(card, current_level)
	var next_profile := _SquadProfile.for_card(card, next_level)
	var detail := ""
	if String(card.get("card_type")) == "general":
		detail = "새 칸을 쓰지 않고 호위 %d명 -> %d명과 장수 피해 성장치를 올립니다." % [
			int(current_profile.get("retinue_count", 0)),
			int(next_profile.get("retinue_count", 0)),
		]
	else:
		detail = "새 칸을 쓰지 않고 병력 %d명 -> %d명과 피해 성장치를 올립니다." % [
			int(current_profile.get("squad_count", 1)),
			int(next_profile.get("squad_count", 1)),
		]
	return _comparison("기존 부대 Lv.%d -> Lv.%d" % [current_level, next_level], detail, 30)

static func _building_comparison(card: CardData, choice_context: Dictionary) -> Dictionary:
	var before := int(choice_context.get("building_count", 0))
	var detail := "보드 한 칸을 지속 효과 칸으로 바꿉니다."
	if int(card.get("gold_per_sec")) > 0:
		detail = "전투 중 경제 생산 칸을 하나 늘립니다."
	elif float(card.get("aura_attack_pct")) > 0.0:
		detail = "인접 배치가 공격 오라를 받을 수 있는 거점을 추가합니다."
	return _comparison("건물 %d -> %d" % [before, before + 1], detail, 12)

static func _scheme_comparison(_card: SchemeCardData, choice_context: Dictionary) -> Dictionary:
	var before := int(choice_context.get("hand_size", 0))
	return _comparison(
		"손패 %d -> %d" % [before, before + 1],
		"다음 배치에서 타일을 쓰지 않는 즉시 한 수로 소비할 수 있습니다.",
		10
	)

static func _treasure_comparison(_card: TreasureCardData) -> Dictionary:
	return _comparison("보패 즉시 장착", "보드 칸과 손패 슬롯을 쓰지 않고 런 전체 지속 효과를 더합니다.", 16)

static func _advice(label: String, detail: String, score: int) -> Dictionary:
	return {
		"label": label,
		"detail": detail,
		"score": score,
	}

static func _comparison(change: String, detail: String, score: int) -> Dictionary:
	return {
		"change": change,
		"detail": detail,
		"score": score,
	}
