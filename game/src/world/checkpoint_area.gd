class_name CheckpointArea
extends Area3D
## Checkpoint boundary: an Area3D that activates when the player overlaps it,
## registering a spawn transform with CheckpointManager / GameState.
## Activation is polled (plus the body_entered fast path) so it works reliably
## in headless runs where physics enter/exit signals are not flushed.

signal activated(checkpoint: CheckpointArea)

const CHECKPOINT_LAYER := 8
const PLAYER_LAYER := 2

@export var checkpoint_id := ""
@export var display_name := "Checkpoint"

var _activated := false

@onready var spawn_point: Marker3D = $SpawnPoint

func _ready() -> void:
	collision_layer = CHECKPOINT_LAYER
	collision_mask = PLAYER_LAYER
	monitoring = true
	body_entered.connect(_on_body_entered)
	if spawn_point == null:
		spawn_point = Marker3D.new()
		spawn_point.name = "SpawnPoint"
		add_child(spawn_point)

func _physics_process(_delta: float) -> void:
	if _activated:
		return
	for body in get_overlapping_bodies():
		if body is Player:
			activate(body as Player)
			return

func _on_body_entered(body: Node3D) -> void:
	if body is Player and not _activated:
		activate(body as Player)

func activate(player: Player) -> void:
	if _activated:
		return
	_activated = true
	CheckpointManager.set_active(self)
	activated.emit(self)
	EventBus.checkpoint_reached.emit(self)

func get_spawn_position() -> Vector3:
	return spawn_point.global_position

func get_spawn_rotation_y() -> float:
	return spawn_point.global_rotation.y
