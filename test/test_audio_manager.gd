# 최소 BGM/SFX 레지스트리와 에셋 경로를 검증한다.
extends TestCase

const _AudioManager := preload("res://scripts/autoloads/audio_manager.gd")

func test_music_registry_has_default_battle_theme() -> void:
	eq(_AudioManager.music_ids(), [&"battle"], "기본 BGM id")
	truthy(_AudioManager.has_music(&"battle"), "battle BGM 존재")
	var path := _AudioManager.music_path(&"battle")
	truthy(path.ends_with("battle_theme.wav"), "battle BGM 파일명")
	not_null(load(path) as AudioStream, "battle BGM 로드")

func test_sfx_registry_has_minimum_cues() -> void:
	eq(_AudioManager.sfx_ids(), [&"defeat", &"gold", &"start", &"ui", &"victory"], "최소 SFX id")
	for id in _AudioManager.sfx_ids():
		truthy(_AudioManager.has_sfx(id), "%s SFX 존재" % id)
		not_null(load(_AudioManager.sfx_path(id)) as AudioStream, "%s SFX 로드" % id)
