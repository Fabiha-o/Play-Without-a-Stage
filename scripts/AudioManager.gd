extends Node

const MUSIC_PATH := "res://assets/02 - Trey Travis - It Waits Between Thoughts.wav"
const FOOTSTEP_PATH := "res://assets/foley_footstep_carpet_1.wav"
const PAPER_PATH := "res://assets/paper_scrunch.wav"
const DOOR_PATH := "res://assets/creaky_door_short.wav"

const MUSIC_VOLUME_DB := -6.0
const FOOTSTEP_VOLUME_DB := -14.0
const SFX_VOLUME_DB := -10.0

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index := 0

var _footstep_stream: AudioStream
var _paper_stream: AudioStream
var _door_stream: AudioStream


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Master"
	_music_player.volume_db = MUSIC_VOLUME_DB
	add_child(_music_player)

	for i in 3:
		var sfx := AudioStreamPlayer.new()
		sfx.name = "SfxPlayer%d" % i
		sfx.bus = "Master"
		add_child(sfx)
		_sfx_players.append(sfx)

	_preload_streams()


func _preload_streams() -> void:
	_footstep_stream = _load_stream(FOOTSTEP_PATH)
	_paper_stream = _load_stream(PAPER_PATH)
	_door_stream = _load_stream(DOOR_PATH)


func _load_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: Missing audio at %s" % path)
		return null
	return load(path) as AudioStream


func play_music_loop() -> void:
	if _music_player == null:
		return
	if not ResourceLoader.exists(MUSIC_PATH):
		push_warning("AudioManager: No music at %s" % MUSIC_PATH)
		return
	var stream := load(MUSIC_PATH) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LoopMode.LOOP_FORWARD
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_music_player.stream = stream
	_music_player.volume_db = MUSIC_VOLUME_DB
	if not _music_player.playing:
		_music_player.play()


func stop_music() -> void:
	if _music_player:
		_music_player.stop()


func play_footstep() -> void:
	_play_sfx(_footstep_stream, FOOTSTEP_VOLUME_DB, randf_range(0.92, 1.08))


func play_paper_scrunch() -> void:
	_play_sfx(_paper_stream, SFX_VOLUME_DB)


func play_door_creak() -> void:
	_play_sfx(_door_stream, SFX_VOLUME_DB)


func play_interact() -> void:
	play_paper_scrunch()


func play_takeover_sting() -> void:
	pass


func play_trap() -> void:
	pass


func play_comedy() -> void:
	pass


func play_damage() -> void:
	pass


func _play_sfx(stream: AudioStream, volume_db: float, pitch: float = 1.0) -> void:
	if stream == null or _sfx_players.is_empty():
		return
	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()
