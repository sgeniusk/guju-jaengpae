# 영구 프로필 payload 컨테이너. 해금 규칙과 저장 연결은 후속 G048 이후에서 확장한다.
class_name ProfileState
extends RefCounted

const SAVE_VERSION := "1.0.0"
const SAVE_MAJOR_VERSION := 1
const STARTING_LORD_ID := &"lord_liubei"

var unlocked_lord_ids: Array[StringName] = []
var unlocked_card_ids: Array[StringName] = []
var best_stage: int = 0
var best_score: int = 0
var settings: Dictionary = {}

static func new_default() -> ProfileState:
	var profile := ProfileState.new()
	profile.unlocked_lord_ids = default_unlocked_lord_ids()
	profile.unlocked_card_ids = default_unlocked_card_ids()
	return profile

static func default_unlocked_lord_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.append(STARTING_LORD_ID)
	return ids

static func default_unlocked_card_ids() -> Array[StringName]:
	return []

func is_lord_unlocked(id: StringName) -> bool:
	return unlocked_lord_ids.has(id)

func is_card_unlocked(id: StringName) -> bool:
	return unlocked_card_ids.has(id)

func unlock_lord(id: StringName) -> bool:
	return _append_unique_id(unlocked_lord_ids, id)

func unlock_card(id: StringName) -> bool:
	return _append_unique_id(unlocked_card_ids, id)

func record_result(stage: int, score: int) -> bool:
	var changed := false
	var normalized_stage := maxi(0, stage)
	var normalized_score := maxi(0, score)
	if normalized_stage > best_stage:
		best_stage = normalized_stage
		changed = true
	if normalized_score > best_score:
		best_score = normalized_score
		changed = true
	return changed

func set_setting(key: String, value) -> bool:
	var normalized_key := String(key)
	if normalized_key == "":
		return false
	var copied = _primitive_copy(value)
	if copied == null:
		return false
	settings[normalized_key] = copied
	return true

func setting(key: String, default_value = null):
	return settings.get(String(key), default_value)

func erase_setting(key: String) -> bool:
	return settings.erase(String(key))

func to_dict() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"unlocked_lord_ids": _string_array(unlocked_lord_ids),
		"unlocked_card_ids": _string_array(unlocked_card_ids),
		"best_stage": best_stage,
		"best_score": best_score,
		"settings": _primitive_copy(settings),
	}

func from_dict(data: Dictionary) -> bool:
	if _payload_major_version(data) > SAVE_MAJOR_VERSION:
		return false
	unlocked_lord_ids = _string_name_array(data.get("unlocked_lord_ids", []))
	unlocked_card_ids = _string_name_array(data.get("unlocked_card_ids", []))
	best_stage = maxi(0, int(data.get("best_stage", 0)))
	best_score = maxi(0, int(data.get("best_score", 0)))
	settings = _primitive_dictionary(data.get("settings", {}))
	return true

static func _string_array(values: Array) -> Array:
	var out: Array = []
	var seen := {}
	for value in values:
		var text := String(value)
		if text != "" and not seen.has(text):
			out.append(text)
			seen[text] = true
	return out

static func _string_name_array(value) -> Array[StringName]:
	var out: Array[StringName] = []
	if not (value is Array):
		return out
	var seen := {}
	for item in value:
		var text := String(item)
		if text != "" and not seen.has(text):
			out.append(StringName(text))
			seen[text] = true
	return out

static func _append_unique_id(ids: Array[StringName], id: StringName) -> bool:
	if id == &"" or ids.has(id):
		return false
	ids.append(id)
	return true

static func _primitive_copy(value):
	match typeof(value):
		TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
		TYPE_STRING_NAME:
			return String(value)
		TYPE_ARRAY:
			var array_out: Array = []
			for item in value:
				var copied = _primitive_copy(item)
				if copied != null:
					array_out.append(copied)
			return array_out
		TYPE_DICTIONARY:
			return _primitive_dictionary(value)
		_:
			return null

static func _primitive_dictionary(value) -> Dictionary:
	var out := {}
	if not (value is Dictionary):
		return out
	for key in (value as Dictionary).keys():
		var copied = _primitive_copy((value as Dictionary)[key])
		if copied != null:
			out[String(key)] = copied
	return out

static func _payload_major_version(data: Dictionary) -> int:
	var raw_version = data.get("save_version", SAVE_VERSION)
	if raw_version is int or raw_version is float:
		return maxi(0, int(raw_version))
	var text := String(raw_version)
	if text == "":
		return SAVE_MAJOR_VERSION
	return maxi(0, int(text.split(".", false, 1)[0]))
