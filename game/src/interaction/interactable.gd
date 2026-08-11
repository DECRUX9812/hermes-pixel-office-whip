class_name Interactable
extends Area3D
## Interaction interface. Any node the player can interact with extends this.
## The concrete scene supplies a CollisionShape3D; the controller detects the
## area and the HUD shows the prompt. Replace StoryInteractable with richer
## scripted set-pieces without touching the player's interaction system.

signal interaction_performed(interactable: Interactable)

const INTERACTABLE_LAYER := 4

@export var id := ""
@export var prompt_text := "Interact"
@export var one_shot := false

var interactive := true

func _ready() -> void:
	collision_layer = INTERACTABLE_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true

func can_interact(_interactor: Node3D) -> bool:
	return interactive

func interact(interactor: Node3D) -> void:
	if not can_interact(interactor):
		return
	interaction_performed.emit(self)
	EventBus.interaction_performed.emit(self)
	_on_interact(interactor)
	if one_shot:
		interactive = false
		EventBus.interactable_unfocused.emit()

## Override to define the actual behaviour.
func _on_interact(_interactor: Node3D) -> void:
	pass
