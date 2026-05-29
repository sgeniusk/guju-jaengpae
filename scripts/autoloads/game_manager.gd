# 게임 전역 상태와 씬 전환을 관리하는 싱글톤
extends Node

signal scene_changed(scene_path: String)

## 현재 선택된 군주 id (런 동안 유지)
var current_lord_id: StringName = &""

func change_scene(path: String) -> void:
	scene_changed.emit(path)
	get_tree().change_scene_to_file(path)
