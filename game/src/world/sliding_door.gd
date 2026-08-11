class_name SlidingDoor
extends Node3D
## Scripted set-piece: a door that slides up when its story beat fires (played by
## an Interactable or an event). Demonstrates environment reacting to story.

@export var open_offset := Vector3(0.0, 3.4, 0.0)
@export var move_time := 1.2
@export var beat_to_open := ""

var _is_open := false

func _ready() -> void:
	EventBus.story_beat_triggered.connect(_on_story_beat)

func _on_story_beat(beat_id: String) -> void:
	if beat_to_open != "" and beat_id == beat_to_open and not _is_open:
		_open()

func _open() -> void:
	_is_open = true
	var tween := create_tween()
	tween.tween_property(self, "position", position + open_offset, move_time)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func is_open() -> bool:
	return _is_open
