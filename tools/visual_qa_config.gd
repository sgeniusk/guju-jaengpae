# 시각 QA 촬영 하네스가 공유하는 군주·스테이지·출력 경로 규칙.
extends RefCounted

const DEFAULT_LORDS: Array[StringName] = [&"lord_liubei", &"lord_caocao", &"lord_sunquan"]
const DEFAULT_FLOW_STAGES: Array[int] = [1, 3, 4, 5]
const DEFAULT_BATTLE_STAGE := 5
const DEFAULT_SHOP_STAGE := 4
const DEFAULT_OUTPUT_DIR := "/tmp/guju-visual-qa"

static func env_lord(default_lord: StringName = &"lord_liubei") -> StringName:
	if not OS.has_environment("LORD"):
		return default_lord
	var value := OS.get_environment("LORD").strip_edges()
	if value.is_empty():
		return default_lord
	return StringName(value)

static func env_int(name: String, fallback: int) -> int:
	if not OS.has_environment(name):
		return fallback
	var value := OS.get_environment(name).strip_edges()
	if value.is_empty():
		return fallback
	return maxi(1, int(value))

static func env_stage_list(name: String, fallback: Array[int]) -> Array[int]:
	if not OS.has_environment(name):
		return fallback.duplicate()
	var value := OS.get_environment(name).strip_edges()
	if value.is_empty():
		return fallback.duplicate()
	var stages: Array[int] = []
	for part in value.split(" ", false):
		var n := int(part.strip_edges())
		if n > 0:
			stages.append(n)
	return stages if not stages.is_empty() else fallback.duplicate()

static func env_output_dir() -> String:
	if not OS.has_environment("SHOT_DIR"):
		return DEFAULT_OUTPUT_DIR
	return normalize_output_dir(OS.get_environment("SHOT_DIR"))

static func normalize_output_dir(path: String) -> String:
	var clean := path.strip_edges()
	if clean.is_empty():
		clean = DEFAULT_OUTPUT_DIR
	while clean.length() > 1 and clean.ends_with("/"):
		clean = clean.substr(0, clean.length() - 1)
	return clean

static func shot_path(kind: String, lord: StringName, stage: int = 0, output_dir: String = DEFAULT_OUTPUT_DIR) -> String:
	var suffix := ""
	if stage > 0:
		suffix = "_stage_%d" % stage
	return "%s/%s_%s%s.png" % [
		normalize_output_dir(output_dir),
		_safe_token(kind),
		_safe_token(String(lord)),
		suffix,
	]

static func _safe_token(value: String) -> String:
	var safe := value.strip_edges().to_lower()
	for ch in ["/", "\\", " ", ":", ";"]:
		safe = safe.replace(ch, "_")
	return safe
