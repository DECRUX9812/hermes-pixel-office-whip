class_name TruthLayerReconstruction
extends Node3D
## Coordinates the 2.3 reconstruction centerpiece. The player collects the three
## substrate fragments in any order; each fragment is an interactable that fires
## a fragment beat when its dialogue finishes. When every fragment is collected
## this node raises truth_layer_reconstruction_completed and (if set) a story
## beat that opens the way on — so the scene can gate the descent behind the
## reveal without creating a dead end.

signal reconstruction_completed(reconstruction: TruthLayerReconstruction)

@export var fragment_ids: PackedStringArray = []
@export var complete_beat_id := ""

var collected: Array[String] = []
var _done := false

func _ready() -> void:
	EventBus.story_beat_triggered.connect(_on_story_beat)

func _exit_tree() -> void:
	EventBus.story_beat_triggered.disconnect(_on_story_beat)

func _on_story_beat(beat_id: String) -> void:
	if _done or not fragment_ids.has(beat_id) or collected.has(beat_id):
		return
	collected.append(beat_id)
	EventBus.truth_layer_fragment_collected.emit(beat_id, fragment_ids.size() - collected.size())
	if collected.size() < fragment_ids.size():
		return
	_done = true
	EventBus.truth_layer_reconstruction_completed.emit(self)
	reconstruction_completed.emit(self)
	if complete_beat_id != "":
		EventBus.story_beat_triggered.emit(complete_beat_id)

func is_complete() -> bool:
	return _done

func collected_count() -> int:
	return collected.size()
