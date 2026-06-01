# 선형 스테이지 번호로 런 이벤트와 난이도 배율을 계산하는 순수 규칙.
class_name StageCadence
extends RefCounted

const SHOP_INTERVAL := 4
const BOSS_INTERVAL := 5
const EXPAND_INTERVAL := 5
const DIFFICULTY_STEP := 0.12

static func is_boss(stage: int) -> bool:
	return _is_interval(stage, BOSS_INTERVAL)

static func is_shop(stage: int) -> bool:
	return _is_interval(stage, SHOP_INTERVAL)

static func is_expand(stage: int) -> bool:
	return _is_interval(stage, EXPAND_INTERVAL)

static func difficulty_scale(stage: int) -> float:
	return 1.0 + DIFFICULTY_STEP * float(maxi(0, stage - 1))

static func stage_label(stage: int) -> String:
	if is_boss(stage):
		return "스테이지 %d — 보스" % stage
	return "스테이지 %d — 전투" % stage

static func _is_interval(stage: int, interval: int) -> bool:
	return stage > 0 and interval > 0 and stage % interval == 0
