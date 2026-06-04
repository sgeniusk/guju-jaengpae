# 저장 I/O 경계는 RunManager와 PersistenceStore 밖으로 새지 않는다.
extends TestCase

const SCRIPTS_DIR := "res://scripts"
const RUN_MANAGER_PATH := "res://scripts/autoloads/run_manager.gd"
const PERSISTENCE_STORE_PATH := "res://scripts/run/persistence_store.gd"
const BATTLE_SIM_PATH := "res://scripts/battle/battle_sim.gd"

const STORE_API_TOKENS := [
	"_PersistenceStore.",
	"PersistenceStore.",
	"save_run_state(",
	"save_run_payload(",
	"load_run_payload(",
	"run_save_exists(",
	"delete_run_save(",
	"save_profile_state(",
	"save_profile_payload(",
	"load_profile_payload(",
	"profile_save_exists(",
	"delete_profile_save(",
]

const BATTLE_SIM_FORBIDDEN_TOKENS := [
	"PersistenceStore",
	"ConfigFile",
	"FileAccess",
	"DirAccess",
	"ResourceLoader",
	"user://",
	"save_run",
	"load_run",
	"save_profile",
	"load_profile",
]

func test_persistence_store_api_is_only_called_by_run_manager() -> void:
	var checked := 0
	for path in _gd_files(SCRIPTS_DIR):
		if path == RUN_MANAGER_PATH or path == PERSISTENCE_STORE_PATH:
			continue
		var text := _read_text(path)
		for token in STORE_API_TOKENS:
			falsy(text.contains(token), "%s는 %s 직접 호출 없음" % [path, token])
		checked += 1
	truthy(checked > 0, "production script 경계 검사 실행")

func test_battle_sim_has_no_save_io_or_resource_loader_boundary() -> void:
	var text := _read_text(BATTLE_SIM_PATH)
	truthy(text.length() > 0, "BattleSim 소스 로드")
	for token in BATTLE_SIM_FORBIDDEN_TOKENS:
		falsy(text.contains(token), "BattleSim에는 %s 없음" % token)

func _gd_files(root: String) -> Array[String]:
	var out: Array[String] = []
	_collect_gd_files(root, out)
	out.sort()
	return out

func _collect_gd_files(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var path := "%s/%s" % [dir_path, file_name]
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_collect_gd_files(path, out)
		elif file_name.ends_with(".gd"):
			out.append(path)
		file_name = dir.get_next()
	dir.list_dir_end()

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text
