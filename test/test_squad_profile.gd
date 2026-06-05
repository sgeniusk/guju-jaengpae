extends TestCase

const SquadProfile := preload("res://scripts/battle/squad_profile.gd")

var cat: CardCatalog

func before_each() -> void:
	cat = CardCatalog.new()
	cat.load_all()

func test_troop_profile_starts_as_visible_squad_and_grows() -> void:
	var card := cat.get_card(&"troop_archer") as UnitCardData
	var lv1 := SquadProfile.for_card(card, 1)
	var lv3 := SquadProfile.for_card(card, 3)
	eq(lv1.get("squad_count", 0), 10, "궁병 Lv.1은 10명 분대")
	eq(lv1.get("retinue_count", -1), 0, "병종은 호위병 없음")
	eq(lv3.get("squad_count", 0), 18, "중복 카드 증원은 보이는 병력 증가")
	truthy(float(lv3.get("hp_mult", 1.0)) > float(lv1.get("hp_mult", 1.0)), "레벨업은 체력 배수 증가")
	truthy(String(lv3.get("label", "")).contains("분대"), "라벨은 분대 단위 표시")

func test_general_profile_is_small_leader_with_retinue() -> void:
	var card := cat.get_card(&"general_guanyu") as UnitCardData
	var lv1 := SquadProfile.for_card(card, 1)
	var lv2 := SquadProfile.for_card(card, 2)
	eq(lv1.get("squad_count", 0), 1, "장수 본체는 1명")
	eq(lv1.get("retinue_count", 0), 5, "장수 Lv.1은 호위병 5명")
	eq(lv2.get("retinue_count", 0), 7, "장수 증원은 호위병 증가")
	truthy(float(lv1.get("body_scale", 1.0)) < 1.0, "장수 본체는 기존 대형 스프라이트보다 작게 렌더 의도")

func test_apply_to_unit_updates_aggregate_stats_only() -> void:
	var card := cat.get_card(&"troop_cavalry") as UnitCardData
	var unit := BattleUnit.from_card(card, BattleUnit.Team.PLAYER, 0, 0.0, 1.0)
	SquadProfile.apply_to_unit(unit, card, 2)
	eq(unit.squad_level, 2, "unit 레벨 저장")
	eq(unit.squad_count, 12, "기병 8명 + 증원 4명")
	eq(unit.retinue_count, 0, "병종 retinue 없음")
	truthy(unit.max_hp > card.max_hp, "집계 HP 증가")
	truthy(unit.attack > card.attack, "공격 증가")
