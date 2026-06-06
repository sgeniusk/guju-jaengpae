# 런맵 현재 위치와 앞으로 이어질 스테이지 리듬을 player-facing 문구로 요약한다.
class_name RunFlowSummary
extends RefCounted

const DEFAULT_LOOKAHEAD := 3

static func for_stage(stage: int, lookahead: int = DEFAULT_LOOKAHEAD) -> Dictionary:
	var current_stage := maxi(1, stage)
	var count := maxi(0, lookahead)
	var title := "진행 리듬 — 현재 %s" % _short_label(current_stage)
	var current := "현재 행동: %s" % StageCadence.stage_prep_label(current_stage)
	var upcoming := _upcoming_line(current_stage, count)
	var tooltip := "%s\n%s\n%s" % [
		StageCadence.stage_label(current_stage),
		StageCadence.stage_prep_tooltip(current_stage),
		upcoming,
	]
	return {
		"title": title,
		"current": current,
		"upcoming": upcoming,
		"tooltip": tooltip,
		"stage": current_stage,
		"lookahead": count,
		"kind": StageCadence.node_kind(current_stage),
	}

static func _upcoming_line(stage: int, lookahead: int) -> String:
	if lookahead <= 0:
		return "다음 흐름: 표시할 다음 스테이지가 없습니다."
	var parts: Array[String] = []
	for offset in range(1, lookahead + 1):
		parts.append(_short_label(stage + offset))
	return "다음 흐름: %s" % " -> ".join(parts)

static func _short_label(stage: int) -> String:
	var name := _kind_label(StageCadence.node_kind(stage))
	if StageCadence.is_final_boss(stage):
		name = "최종 보스"
	return "%d %s" % [stage, name]

static func _kind_label(kind: String) -> String:
	match kind:
		"boss":
			return "보스"
		"edict":
			return "칙령"
		"shop":
			return "상점"
		"elite":
			return "정예"
		"event":
			return "사건"
		"expand":
			return "확장"
		_:
			return "전투"
