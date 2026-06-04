# 선형 스테이지 번호로 런 이벤트와 난이도 배율을 계산하는 순수 규칙.
class_name StageCadence
extends RefCounted

const SHOP_INTERVAL := 4
const BOSS_INTERVAL := 5
const EXPAND_INTERVAL := 5
const EDICT_INTERVAL := 3
const ELITE_INTERVAL := 7
const EVENT_INTERVAL := 11
const FINAL_BOSS_STAGE := 15
const DIFFICULTY_STEP := 0.10

static func is_boss(stage: int) -> bool:
	return _is_interval(stage, BOSS_INTERVAL)

static func is_shop(stage: int) -> bool:
	return _is_interval(stage, SHOP_INTERVAL)

static func is_expand(stage: int) -> bool:
	return _is_interval(stage, EXPAND_INTERVAL)

static func is_edict(stage: int) -> bool:
	return _is_interval(stage, EDICT_INTERVAL)

static func is_elite(stage: int) -> bool:
	return _is_interval(stage, ELITE_INTERVAL)

static func is_event(stage: int) -> bool:
	return _is_interval(stage, EVENT_INTERVAL)

static func is_final_boss(stage: int) -> bool:
	return stage == FINAL_BOSS_STAGE

static func node_kind(stage: int) -> String:
	if is_boss(stage):
		return "boss"
	if is_edict(stage):
		return "edict"
	if is_shop(stage):
		return "shop"
	if is_elite(stage):
		return "elite"
	if is_event(stage):
		return "event"
	if is_expand(stage):
		return "expand"
	return "combat"

static func difficulty_scale(stage: int) -> float:
	return 1.0 + DIFFICULTY_STEP * float(maxi(0, stage - 1))

static func stage_label(stage: int) -> String:
	match node_kind(stage):
		"boss":
			return "스테이지 %d — 보스" % stage
		"edict":
			return "스테이지 %d — 왕의 칙령" % stage
		"shop":
			return "스테이지 %d — 상점" % stage
		"elite":
			return "스테이지 %d — 정예" % stage
		"event":
			return "스테이지 %d — 사건" % stage
		_:
			return "스테이지 %d — 전투" % stage

static func _is_interval(stage: int, interval: int) -> bool:
	return stage > 0 and interval > 0 and stage % interval == 0
