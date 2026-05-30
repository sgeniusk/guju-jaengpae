# BattleUnit의 그리드 런타임 상태와 카드 변환을 검증한다.
extends TestCase

func test_from_card_rounds_hp_multiplier() -> void:
	var cat := CardCatalog.new()
	cat.load_all()
	var card := cat.get_card(&"troop_infantry")
	var unit := BattleUnit.from_card(card, BattleUnit.Team.PLAYER, 2, 120.0, 1.15, 2)
	eq(unit.max_hp, 161, "140 체력 병종에 15% 보정")
	eq(unit.hp, 161, "생성 시 현재 체력은 최대 체력")
	eq(unit.card_id, &"troop_infantry", "카드 id 보존")
	eq(unit.lane, 2, "컬럼 보존")
	eq(unit.row, 2, "행 보존")

func test_hp_ratio_reports_full_and_half() -> void:
	var unit := BattleUnit.make(BattleUnit.Team.PLAYER, 0, 0.0, "비율", 100, 1, 1.0, "melee", 0.0)
	almost(unit.hp_ratio(), 1.0, 0.001, "만피 비율")
	unit.take_damage(50)
	almost(unit.hp_ratio(), 0.5, 0.001, "반피 비율")

func test_make_maps_runtime_stats() -> void:
	var unit := BattleUnit.make(BattleUnit.Team.ENEMY, 1, 900.0, "사령병", 90, 14, 1.2, "melee", 34.0, &"enemy_dead", &"", "infantry", 0)
	eq(unit.team, BattleUnit.Team.ENEMY, "팀 매핑")
	eq(unit.lane, 1, "컬럼 매핑")
	eq(unit.row, 0, "행 매핑")
	almost(unit.x, 900.0, 0.001, "depth 매핑")
	eq(unit.display_name, "사령병", "표시명 매핑")
	eq(unit.max_hp, 90, "최대 체력 매핑")
	eq(unit.attack, 14, "공격력 매핑")
	almost(unit.attack_interval, 1.2, 0.001, "공격 간격 매핑")
	eq(unit.attack_range, "melee", "공격 사거리 타입 매핑")
	almost(unit.move_speed, 34.0, 0.001, "이동 속도 매핑")
	eq(unit.card_id, &"enemy_dead", "card_id 매핑")

func test_take_damage_clamps_and_alive_boundary() -> void:
	var unit := BattleUnit.make(BattleUnit.Team.PLAYER, 0, 0.0, "방패", 30, 1, 1.0, "melee", 0.0)
	truthy(unit.is_alive(), "생성 직후 생존")
	unit.take_damage(10)
	eq(unit.hp, 20, "피해 적용")
	unit.take_damage(99)
	eq(unit.hp, 0, "0 미만으로 내려가지 않음")
	falsy(unit.is_alive(), "hp 0은 사망")
