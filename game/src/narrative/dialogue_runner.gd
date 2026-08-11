class_name DialogueRunner
extends Node3D
## Skip-safe cinematic / dialogue runner.
##
## Plays a ScriptDialogue sequence as timed subtitles, with skip handling:
##   - press skip_action (default "interact") once  -> advance one line
##   - hold skip_action for hold_skip_seconds       -> skip the whole sequence
##   - press skip_all_action (default "skip_cutscene") -> skip the whole sequence
##
## Skip-safety guarantee: `beat_id` fires on EVERY finish, skipped or not, so a
## scene director can advance objectives no matter how fast the player skips. The
## player is never softlocked by a cutscene the player refuses to watch.
##
## Optional:
##   - lock_player: disables Teknium's input while playing (cinematic beats).
##   - camera_path: a Camera3D made current for the sequence, restored on finish.

signal sequence_started(sequence_id: String)
signal sequence_finished(sequence_id: String)

const DEFAULT_SKIP_ACTION := "interact"
const DEFAULT_SKIP_ALL_ACTION := "skip_cutscene"

@export var sequence_id := ""
@export var beat_id := ""
@export var play_on_ready := false
@export var lock_player := false
@export var camera_path: NodePath = ^""
@export var skip_action := DEFAULT_SKIP_ACTION
@export var skip_all_action := DEFAULT_SKIP_ALL_ACTION
@export var hold_skip_seconds := 0.5
@export var allow_replay := false

var _lines: Array[DialogueLine] = []
var _playing := false
var _played_once := false
var _line_index := -1
var _line_timer := 0.0
var _hold_timer := 0.0
var _locked_player: Player = null
var _cin_camera: Camera3D = null
var _player_camera: Camera3D = null
var _camera_was_current := false

func _ready() -> void:
	_reload_lines()
	if play_on_ready:
		call_deferred("play")

func _reload_lines() -> void:
	if sequence_id != "":
		_lines = ScriptDialogue.sequence(sequence_id)

func is_playing() -> bool:
	return _playing

func has_played() -> bool:
	return _played_once

func current_line_index() -> int:
	return _line_index

func play() -> void:
	if _played_once and not allow_replay:
		return
	_played_once = true
	_playing = true
	_line_index = -1
	_hold_timer = 0.0
	EventBus.subtitle_clear.emit()
	EventBus.dialogue_sequence_started.emit(sequence_id)
	sequence_started.emit(sequence_id)
	_apply_lock()
	_apply_camera()
	_advance_line()

func advance_line() -> void:
	if _playing:
		_advance_line()

func skip_all() -> void:
	if _playing:
		_finish()

func _process(delta: float) -> void:
	if not _playing:
		return
	if Input.is_action_just_pressed(skip_all_action):
		_finish()
		return
	if Input.is_action_just_pressed(skip_action):
		_advance_line()
		return
	if Input.is_action_pressed(skip_action):
		_hold_timer += delta
		if _hold_timer >= hold_skip_seconds:
			_finish()
			return
	else:
		_hold_timer = 0.0
	_line_timer -= delta
	if _line_timer <= 0.0:
		_advance_line()

func _advance_line() -> void:
	_line_index += 1
	if _line_index >= _lines.size():
		_finish()
		return
	_play_current()

func _play_current() -> void:
	var line := _lines[_line_index]
	if line.is_silence():
		EventBus.subtitle_clear.emit()
		_line_timer = maxf(0.5, line.seconds)
		return
	_line_timer = maxf(0.5, _duration_for(line))
	EventBus.subtitle_requested_timed.emit(line.speaker, line.text, _line_timer)

func _duration_for(line: DialogueLine) -> float:
	if line.seconds > 0.0:
		return line.seconds
	return clampf(line.text.length() * 0.06, 2.0, 6.5)

func _finish() -> void:
	if not _playing:
		return
	_playing = false
	_hold_timer = 0.0
	_release_lock()
	_restore_camera()
	EventBus.subtitle_clear.emit()
	if beat_id != "":
		EventBus.story_beat_triggered.emit(beat_id)
	EventBus.dialogue_sequence_finished.emit(sequence_id)
	sequence_finished.emit(sequence_id)

func _apply_lock() -> void:
	if not lock_player:
		return
	for node in get_tree().get_nodes_in_group("player"):
		if node is Player:
			_locked_player = node as Player
			_locked_player.control_locked = true
			return

func _release_lock() -> void:
	if _locked_player and is_instance_valid(_locked_player):
		_locked_player.control_locked = false
	_locked_player = null

func _apply_camera() -> void:
	if camera_path.is_empty():
		return
	var cam := get_node_or_null(camera_path) as Camera3D
	if cam == null:
		return
	_player_camera = _find_player_camera()
	_camera_was_current = _player_camera != null and _player_camera.is_current()
	_cin_camera = cam
	_cin_camera.current = true

func _restore_camera() -> void:
	if _cin_camera == null:
		return
	if _camera_was_current and is_instance_valid(_player_camera):
		_player_camera.current = true
	_cin_camera = null
	_player_camera = null

func _find_player_camera() -> Camera3D:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	var player := players[0] as Player
	var cam := player.get_node_or_null("CameraRig/SpringArm/Camera3D") as Camera3D
	return cam
