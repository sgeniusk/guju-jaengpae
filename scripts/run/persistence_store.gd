# 저장 포맷과 기본 위치를 고정하는 얇은 경계. payload 변환은 RunState/ProfileState가 소유한다.
class_name PersistenceStore
extends RefCounted

const FORMAT_NAME := "ConfigFile"
const RUN_SAVE_PATH := "user://guju_run.cfg"
const PROFILE_SAVE_PATH := "user://guju_profile.cfg"

const SECTION_META := "meta"
const SECTION_RUN := "run"
const SECTION_PROFILE := "profile"
const KEY_FORMAT := "format"

static func new_config() -> ConfigFile:
	var config := ConfigFile.new()
	stamp_format(config)
	return config

static func stamp_format(config: ConfigFile) -> void:
	config.set_value(SECTION_META, KEY_FORMAT, FORMAT_NAME)

static func is_configfile_format(config: ConfigFile) -> bool:
	if config == null:
		return false
	return String(config.get_value(SECTION_META, KEY_FORMAT, "")) == FORMAT_NAME

static func default_run_path() -> String:
	return RUN_SAVE_PATH

static func default_profile_path() -> String:
	return PROFILE_SAVE_PATH

static func default_paths() -> Dictionary:
	return {
		"run": RUN_SAVE_PATH,
		"profile": PROFILE_SAVE_PATH,
	}

static func save_run_state(run_state: RunState, path: String = RUN_SAVE_PATH) -> int:
	if run_state == null:
		return ERR_INVALID_PARAMETER
	return save_run_payload(run_state.to_dict(), path)

static func save_run_payload(payload: Dictionary, path: String = RUN_SAVE_PATH) -> int:
	var config := new_config()
	_write_section(config, SECTION_RUN, payload)
	return config.save(path)

static func load_run_payload(path: String = RUN_SAVE_PATH) -> Dictionary:
	var config := ConfigFile.new()
	var err := config.load(path)
	if err != OK:
		return _load_result(false, err, {})
	if not is_configfile_format(config) or not config.has_section(SECTION_RUN):
		return _load_result(false, ERR_INVALID_DATA, {})
	return _load_result(true, OK, _read_section(config, SECTION_RUN))

static func run_save_exists(path: String = RUN_SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)

static func delete_run_save(path: String = RUN_SAVE_PATH) -> int:
	if not run_save_exists(path):
		return OK
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

static func save_profile_state(profile_state: ProfileState, path: String = PROFILE_SAVE_PATH) -> int:
	if profile_state == null:
		return ERR_INVALID_PARAMETER
	return save_profile_payload(profile_state.to_dict(), path)

static func save_profile_payload(payload: Dictionary, path: String = PROFILE_SAVE_PATH) -> int:
	var config := new_config()
	_write_section(config, SECTION_PROFILE, payload)
	return config.save(path)

static func load_profile_payload(path: String = PROFILE_SAVE_PATH) -> Dictionary:
	var config := ConfigFile.new()
	var err := config.load(path)
	if err != OK:
		return _load_result(false, err, {})
	if not is_configfile_format(config) or not config.has_section(SECTION_PROFILE):
		return _load_result(false, ERR_INVALID_DATA, {})
	return _load_result(true, OK, _read_section(config, SECTION_PROFILE))

static func profile_save_exists(path: String = PROFILE_SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)

static func delete_profile_save(path: String = PROFILE_SAVE_PATH) -> int:
	if not profile_save_exists(path):
		return OK
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

static func _write_section(config: ConfigFile, section: String, payload: Dictionary) -> void:
	for key in payload.keys():
		config.set_value(section, String(key), payload[key])

static func _read_section(config: ConfigFile, section: String) -> Dictionary:
	var out := {}
	for key in config.get_section_keys(section):
		out[String(key)] = config.get_value(section, key)
	return out

static func _load_result(ok: bool, error: int, payload: Dictionary) -> Dictionary:
	return {
		"ok": ok,
		"error": error,
		"payload": payload,
	}
