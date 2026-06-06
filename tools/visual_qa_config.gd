# 시각 QA 촬영 하네스가 공유하는 군주·스테이지·출력 경로 규칙.
extends RefCounted

const DEFAULT_LORDS: Array[StringName] = [&"lord_liubei", &"lord_caocao", &"lord_sunquan"]
const DEFAULT_FLOW_STAGES: Array[int] = [1, 3, 4, 5]
const DEFAULT_BATTLE_STAGE := 5
const DEFAULT_SHOP_STAGE := 4
const DEFAULT_OUTPUT_DIR := "/tmp/guju-visual-qa"
const HEADLESS_CAPTURE_SETTLE_FRAMES := 2

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

static func display_driver_name() -> String:
	return DisplayServer.get_name().strip_edges().to_lower()

static func should_wait_for_frame_post_draw(display_driver: String = "") -> bool:
	if _truthy_env("SHOT_SKIP_POST_DRAW"):
		return false
	var driver := display_driver.strip_edges().to_lower()
	if driver.is_empty():
		driver = display_driver_name()
	return driver != "headless"

static func capture_viewport_png(viewport: Viewport, tree: SceneTree, path: String) -> bool:
	if viewport == null or tree == null:
		print("SHOT FAIL ", path, " no_viewport")
		return false
	var display_driver := display_driver_name()
	if should_wait_for_frame_post_draw():
		await RenderingServer.frame_post_draw
	else:
		await wait_process_frames(tree, HEADLESS_CAPTURE_SETTLE_FRAMES)
		if display_driver == "headless":
			print("SHOT FAIL ", path, " headless_display")
			return false
	var texture := viewport.get_texture()
	if texture == null:
		print("SHOT FAIL ", path, " no_texture")
		return false
	var img := texture.get_image()
	if img == null or img.get_width() <= 0 or img.get_height() <= 0:
		print("SHOT FAIL ", path, " no_image")
		return false
	var err := img.save_png(path)
	if err != OK:
		print("SHOT FAIL ", path, " save_error=", err)
		return false
	print("SHOT ", path, " ", img.get_size())
	return true

static func wait_process_frames(tree: SceneTree, frames: int) -> void:
	var count := maxi(1, frames)
	for _i in count:
		await tree.process_frame

static func _safe_token(value: String) -> String:
	var safe := value.strip_edges().to_lower()
	for ch in ["/", "\\", " ", ":", ";"]:
		safe = safe.replace(ch, "_")
	return safe

static func _truthy_env(name: String) -> bool:
	if not OS.has_environment(name):
		return false
	var value := OS.get_environment(name).strip_edges().to_lower()
	return value in ["1", "true", "yes", "y", "on"]
