# 카드 타입별 UI 문구를 한곳에서 만든다. 내부 effect_id 대신 플레이어 행동 경로를 노출한다.
class_name CardUiText
extends RefCounted

const _SchemeCatalog := preload("res://scripts/run/scheme_catalog.gd")
const _TreasureCatalog := preload("res://scripts/run/treasure_catalog.gd")

static func type_label(card: CardData) -> String:
	if card == null:
		return "?"
	match String(card.get("card_type")):
		"general":
			return "장수"
		"troop":
			return "병종"
		"building":
			return "건물"
		"scheme":
			return "계략"
		"treasure":
			return "보패"
		_:
			return card.card_type

static func battle_brief(card: CardData) -> String:
	if card == null:
		return "알 수 없음"
	var card_type := String(card.get("card_type"))
	if card is UnitCardData:
		var unit := card as UnitCardData
		var unit_label := "장수" if card_type == "general" else "병종"
		return "보드 배치/%s 공격 %d" % [unit_label, unit.attack]
	match card_type:
		"building":
			return "건물 배치/%s" % _building_effect_brief(card)
		"scheme":
			return "계략 발동/%s" % _scheme_effect_brief(card as SchemeCardData)
		"treasure":
			return "보패 장착/%s" % _treasure_effect_brief(card as TreasureCardData)
		_:
			return card.card_type

static func shop_route_label(card: CardData) -> String:
	if card == null:
		return "구매 경로 없음"
	match String(card.get("card_type")):
		"general", "troop":
			return "손패 구매 · 보드 배치"
		"building":
			return "손패 구매 · 건물 배치"
		"scheme":
			return "손패 구매 · 계략 발동"
		"treasure":
			return "즉시 장착 · 지속 보패"
		_:
			return "손패 구매"

static func acquisition_hint(card: CardData, display_name: String) -> String:
	if card == null:
		return "획득 — %s" % display_name
	match String(card.get("card_type")):
		"treasure":
			return "획득 — %s. 보패로 즉시 장착했습니다." % display_name
		"scheme":
			return "획득 — %s. 손패에 들어왔고 전투에서 계략 발동합니다." % display_name
		"building":
			return "획득 — %s. 손패에 들어왔고 전투에서 건물 배치합니다." % display_name
		_:
			return "획득 — %s. 손패에 들어왔고 전투에서 보드 배치합니다." % display_name

static func tooltip(card: CardData) -> String:
	if card == null:
		return "카드 정보를 불러오지 못했습니다."
	var parts: Array[String] = [
		"%s — %s" % [type_label(card), shop_route_label(card)],
		battle_brief(card),
	]
	if card.description != "":
		parts.append(card.description)
	return "\n".join(parts)

static func _scheme_effect_brief(card: SchemeCardData) -> String:
	var result := _SchemeCatalog.resolve(card)
	if not bool(result.get("ok", false)):
		return "효과 미등록"
	var run: Dictionary = result.get("run", {})
	if run.has("gold_delta"):
		return "+%d골드" % int(run.get("gold_delta", 0))
	var battle: Dictionary = result.get("battle", {})
	if battle.has("damage_enemy"):
		var damage: Dictionary = battle.get("damage_enemy", {})
		return "적 피해 %d" % int(damage.get("amount", 0))
	if battle.has("castle_hp_delta"):
		return "성 +%d" % int(battle.get("castle_hp_delta", 0))
	return "효과 없음"

static func _treasure_effect_brief(card: TreasureCardData) -> String:
	var result := _TreasureCatalog.resolve(card)
	if not bool(result.get("ok", false)):
		return "효과 미등록"
	var battle: Dictionary = result.get("battle", {})
	if battle.has("attack_pct"):
		return "공격 +%d%%" % int(round(float(battle.get("attack_pct", 0.0)) * 100.0))
	var economy: Dictionary = result.get("economy", {})
	if economy.has("gold_pct"):
		return "골드 +%d%%" % int(round(float(economy.get("gold_pct", 0.0)) * 100.0))
	var reward: Dictionary = result.get("reward", {})
	if reward.has("bonus_choices"):
		return "보상 +%d" % int(reward.get("bonus_choices", 0))
	return "효과 없음"

static func _building_effect_brief(card: CardData) -> String:
	if int(card.get("gold_per_sec")) > 0:
		return "초당 %d골드" % int(card.get("gold_per_sec"))
	if float(card.get("aura_attack_pct")) > 0.0:
		return "공격 +%d%%" % int(round(float(card.get("aura_attack_pct")) * 100.0))
	return "보드 지속"
