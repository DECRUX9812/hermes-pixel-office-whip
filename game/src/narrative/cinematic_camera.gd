class_name CinematicCamera
extends Camera3D
## Cinematic camera beat for the slice's authored moments.
##
## Slow, authored framing beats for 2.10 (Hermes's eleven seconds) and 2.11
## (the question): a gentle push-in and a small FOV pull that reads as
## attention, not as handheld noise. The DialogueRunner makes this camera
## current for the sequence; this script animates it while it is current and
## restores its authored transform afterwards (so skips and replays are clean).
##
## This is a PROTOTYPE camera layer: the motion here is the framing language a
## cinematic animator would replace with a tracked shot. It never rotates the
## camera beyond a few degrees and never moves it off its subject.

@export var push_in_distance := 0.7
@export var fov_start := 60.0
@export var fov_end := 55.0
@export var beat_seconds := 6.0
@export var sway_amplitude := 0.05

var _home: Transform3D
var _home_fov := 60.0
var _was_current := false
var _elapsed := 0.0

func _ready() -> void:
	_home = transform
	_home_fov = fov

func _process(delta: float) -> void:
	var current := is_current()
	if current and not _was_current:
		_elapsed = 0.0
		transform = _home
		fov = fov_start
	_was_current = current
	if not current:
		return
	_elapsed += delta
	var t := clampf(_elapsed / beat_seconds, 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)
	var sway := sin(_elapsed * 0.8) * sway_amplitude * (1.0 - t)
	transform = _home.translated_local(Vector3(0.0, sway, -push_in_distance * eased))
	fov = lerpf(fov_start, fov_end, eased)

func play_beat() -> void:
	make_current()
