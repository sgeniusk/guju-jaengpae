# 장기런 전투 시간 예산 helper를 검증한다.
extends TestCase

const _LongRunTempoContract := preload("res://scripts/run/long_run_tempo_contract.gd")
const _StageCadence := preload("res://scripts/run/stage_cadence.gd")

func test_final_boss_gets_separate_but_bounded_time_limit() -> void:
	eq(_LongRunTempoContract.limit_for_stage(1), 24.0, "일반 전투는 24초 예산")
	eq(_LongRunTempoContract.limit_for_stage(10), 24.0, "중간 보스도 24초 예산")
	eq(_LongRunTempoContract.limit_for_stage(_StageCadence.FINAL_BOSS_STAGE), 28.0, "최종 보스만 28초 예산")

func test_combat_time_ok_uses_stage_limit() -> void:
	truthy(_LongRunTempoContract.combat_time_ok(5, 24.0), "일반 보스 24초는 통과")
	falsy(_LongRunTempoContract.combat_time_ok(5, 24.1), "일반 보스 24초 초과는 실패")
	truthy(_LongRunTempoContract.combat_time_ok(_StageCadence.FINAL_BOSS_STAGE, 28.0), "최종 보스 28초는 통과")
	falsy(_LongRunTempoContract.combat_time_ok(_StageCadence.FINAL_BOSS_STAGE, 28.1), "최종 보스 28초 초과는 실패")

func test_average_time_budget_catches_dragging_runs() -> void:
	eq(_LongRunTempoContract.average_time([]), 0.0, "빈 장기런 평균은 0")
	truthy(_LongRunTempoContract.average_time_ok([12.0, 18.0, 24.0]), "평균 18초는 통과")
	falsy(_LongRunTempoContract.average_time_ok([18.0, 19.0]), "평균 18초 초과는 실패")
