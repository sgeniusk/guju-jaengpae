# 장기런 스모크가 느린 전투를 놓치지 않도록 공유하는 시간 예산.
class_name LongRunTempoContract
extends RefCounted

const _StageCadence := preload("res://scripts/run/stage_cadence.gd")

const MAX_COMBAT_SECONDS := 24.0
const FINAL_BOSS_MAX_SECONDS := 28.0
const MAX_AVERAGE_COMBAT_SECONDS := 18.0

static func limit_for_stage(stage: int) -> float:
	return FINAL_BOSS_MAX_SECONDS if _StageCadence.is_final_boss(stage) else MAX_COMBAT_SECONDS

static func combat_time_ok(stage: int, elapsed_seconds: float) -> bool:
	return elapsed_seconds <= limit_for_stage(stage)

static func average_time_ok(times: Array) -> bool:
	return average_time(times) <= MAX_AVERAGE_COMBAT_SECONDS

static func average_time(times: Array) -> float:
	if times.is_empty():
		return 0.0
	var total := 0.0
	for value in times:
		total += float(value)
	return total / float(times.size())
