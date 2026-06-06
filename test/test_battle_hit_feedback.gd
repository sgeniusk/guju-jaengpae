extends TestCase

const BattleHitFeedback := preload("res://scripts/battle/battle_hit_feedback.gd")

func test_attack_event_gets_one_spark_profile() -> void:
	var profiles := BattleHitFeedback.profiles_for_event({"amount": 12, "kind": "attack"})
	eq(profiles.size(), 1, "일반 공격은 spark 1개")
	eq(profiles[0].get("kind", ""), BattleHitFeedback.KIND_SPARK, "spark kind")
	truthy(float(profiles[0].get("duration", 0.0)) > 0.0, "spark 지속 시간")

func test_crit_event_adds_ring_profile() -> void:
	var profiles := BattleHitFeedback.profiles_for_event({"amount": 15, "kind": "attack", "is_crit": true})
	eq(profiles.size(), 2, "치명타는 spark+crit ring")
	eq(profiles[1].get("kind", ""), BattleHitFeedback.KIND_CRIT, "crit ring kind")
	truthy(float(profiles[1].get("scale", 0.0)) > float(profiles[0].get("scale", 0.0)), "crit ring은 더 크게 확산")

func test_skill_and_scheme_events_add_burst_profile() -> void:
	var skill_profiles := BattleHitFeedback.profiles_for_event({"amount": 80, "kind": "skill"})
	var scheme_profiles := BattleHitFeedback.profiles_for_event({"amount": 40, "kind": "scheme"})
	eq(skill_profiles.size(), 2, "스킬은 spark+burst")
	eq(scheme_profiles.size(), 2, "계략은 spark+burst")
	eq(skill_profiles[1].get("kind", ""), BattleHitFeedback.KIND_BURST, "스킬 burst")
	eq(scheme_profiles[1].get("kind", ""), BattleHitFeedback.KIND_BURST, "계략 burst")

func test_zero_damage_event_has_no_profile() -> void:
	eq(BattleHitFeedback.profiles_for_event({"amount": 0}).size(), 0, "피해 0은 VFX 없음")
