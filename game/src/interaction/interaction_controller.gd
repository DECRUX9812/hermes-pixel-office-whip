class_name InteractionController
extends Node3D
## Detects the nearest valid Interactable inside the detection area, drives the
## HUD focus prompt, and performs the interaction on the player's command.

signal focused_changed(interactable: Interactable)

const INTERACTABLE_LAYER := 4

@export var detection_radius := 2.6

var focused: Interactable = null

@onready var detector: Area3D = $DetectionArea

func _ready() -> void:
	detector.collision_layer = 0
	detector.collision_mask = INTERACTABLE_LAYER
	detector.monitoring = true
	var shape_node := detector.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node:
		var sphere := SphereShape3D.new()
		sphere.radius = detection_radius
		shape_node.shape = sphere

func _physics_process(_delta: float) -> void:
	_refresh_focus()

func _refresh_focus() -> void:
	var best: Interactable = null
	var best_distance_sq := INF
	var origin := global_position
	for area in detector.get_overlapping_areas():
		var candidate := area as Interactable
		if candidate == null or not candidate.can_interact(self):
			continue
		var distance_sq := candidate.global_position.distance_squared_to(origin)
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best = candidate
	if best != focused:
		focused = best
		focused_changed.emit(focused)
		if focused:
			EventBus.interactable_focused.emit(focused)
		else:
			EventBus.interactable_unfocused.emit()

func perform_interaction() -> void:
	if focused and focused.can_interact(self):
		focused.interact(get_parent() as Node3D)
