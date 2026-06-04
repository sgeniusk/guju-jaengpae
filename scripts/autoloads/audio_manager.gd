# Minimal audio facade for music and interface/gameplay cues.
extends Node

const DEFAULT_MUSIC_ID := &"battle"
const MUSIC_VOLUME_DB := -18.0
const SFX_VOLUME_DB := -8.0
const SFX_POOL_SIZE := 6

const MUSIC := {
	&"battle": "res://assets/audio/music/battle_theme.wav",
}

const SFX := {
	&"ui": "res://assets/audio/sfx/ui_click.wav",
	&"gold": "res://assets/audio/sfx/coin.wav",
	&"start": "res://assets/audio/sfx/battle_start.wav",
	&"victory": "res://assets/audio/sfx/victory.wav",
	&"defeat": "res://assets/audio/sfx/defeat.wav",
}

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _audio_enabled := true

func _ready() -> void:
	_audio_enabled = DisplayServer.get_name() != "headless"
	if _audio_enabled:
		_build_players()

func play_music(id: StringName = DEFAULT_MUSIC_ID) -> bool:
	if not _audio_enabled:
		return has_music(id)
	var path := music_path(id)
	if path == "":
		return false
	var stream := _load_audio_stream(path)
	if stream == null:
		return false
	if _music_player == null:
		_build_players()
	if _music_player.stream != null and _music_player.stream.resource_path == path and _music_player.playing:
		return true
	_music_player.stop()
	_music_player.stream = _loopable_stream(stream)
	_music_player.volume_db = MUSIC_VOLUME_DB
	_music_player.play()
	return true

func stop_music() -> void:
	if _music_player != null:
		_music_player.stop()

func play_sfx(id: StringName) -> bool:
	if not _audio_enabled:
		return has_sfx(id)
	var path := sfx_path(id)
	if path == "":
		return false
	var stream := _load_audio_stream(path)
	if stream == null:
		return false
	if _sfx_pool.is_empty():
		_build_players()
	var player := _sfx_pool[_sfx_index % _sfx_pool.size()]
	_sfx_index += 1
	player.stop()
	player.stream = stream
	player.volume_db = SFX_VOLUME_DB
	player.play()
	return true

static func music_ids() -> Array[StringName]:
	return _ids(MUSIC)

static func sfx_ids() -> Array[StringName]:
	return _ids(SFX)

static func music_path(id: StringName) -> String:
	return String(MUSIC.get(id, ""))

static func sfx_path(id: StringName) -> String:
	return String(SFX.get(id, ""))

static func has_music(id: StringName) -> bool:
	var path := music_path(id)
	return path != "" and ResourceLoader.exists(path)

static func has_sfx(id: StringName) -> bool:
	var path := sfx_path(id)
	return path != "" and ResourceLoader.exists(path)

func _build_players() -> void:
	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "Music"
		add_child(_music_player)
	while _sfx_pool.size() < SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "Sfx%d" % _sfx_pool.size()
		add_child(player)
		_sfx_pool.append(player)

static func _ids(source: Dictionary) -> Array[StringName]:
	var names: Array[String] = []
	for id in source.keys():
		names.append(String(id))
	names.sort()
	var ids: Array[StringName] = []
	for name in names:
		ids.append(StringName(name))
	return ids

func _load_audio_stream(path: String) -> AudioStream:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream

func _loopable_stream(stream: AudioStream) -> AudioStream:
	var copy := stream.duplicate()
	if copy is AudioStreamWAV:
		(copy as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	return copy
