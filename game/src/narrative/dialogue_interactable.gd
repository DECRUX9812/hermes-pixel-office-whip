class_name DialogueInteractable
extends Interactable
## Interactable that plays a DialogueRunner sequence on interaction. The runner
## owns the dialogue and its finish beat; this node only decides when it plays
## (and, with one_shot, when it is consumed). Used for the truth-layer fragments
## in the Weep's upper gallery.

@export var runner_path: NodePath = ^""

var _runner: DialogueRunner = null

func _ready() -> void:
	super()
	_runner = get_node_or_null(runner_path) as DialogueRunner

func _on_interact(_interactor: Node3D) -> void:
	if _runner:
		_runner.play()
