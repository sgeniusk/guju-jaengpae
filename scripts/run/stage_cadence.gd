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

static func stage_prep_label(stage: int) -> String:
	match node_kind(stage):
		"boss":
			return "보스전입니다. 보드와 손패를 정비하세요."
		"edict":
			return "왕의 칙령을 골라 런 전체 보정을 더합니다."
		"shop":
			return "군자금으로 카드를 구매하고 손패를 정리합니다."
		"elite":
			return "정예 전투입니다. 증원 우선순위를 확인하세요."
		"event":
			return "길목 사건으로 군자금을 보급합니다."
		"expand":
			return "보드 확장 길목입니다. 새 칸 활용을 준비하세요."
		_:
			return "전투 화면에서 손패 3장 중 1장을 배치합니다."

static func stage_prep_tooltip(stage: int) -> String:
	match node_kind(stage):
		"boss":
			return "런맵에서 보스 전투로 진입합니다. 전투 화면에서 배치 한 수를 고른 뒤 교전합니다."
		"edict":
			return "런맵에서 칙령 선택지가 열립니다. 하나를 고르면 즉시 다음 스테이지로 진행합니다."
		"shop":
			return "런맵에서 상점이 열립니다. 구매를 마친 뒤 상점 떠나기로 진행합니다."
		"elite":
			return "런맵에서 정예 전투로 진입합니다. 보드 성장과 증원 후보를 먼저 확인하세요."
		"event":
			return "런맵에서 사건 보상을 받고 다음 스테이지로 이동합니다."
		"expand":
			return "보드 확장 보상을 처리한 뒤 다음 전투 준비를 이어갑니다."
		_:
			return "런맵에서 전투 시작 버튼을 누르면 배치 단계로 들어갑니다."

static func _is_interval(stage: int, interval: int) -> bool:
	return stage > 0 and interval > 0 and stage % interval == 0
