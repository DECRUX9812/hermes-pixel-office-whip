class_name BoundsGuard
extends Node3D
## Safety net for traversal: if Teknium falls out of the world (a broken bridge
## section, a missed jump over the conduit gap) the scene restores from the last
## checkpoint instead of softlocking in the void. This is what makes the
## traversal gaps "no progression dead ends".

@export var fall_limit_y := -20.0

func _physics_process(_delta: float) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if node is Player and node.alive and node.global_position.y < fall_limit_y:
			EventBus.combat_event.emit("Fell out of bounds — restoring from checkpoint")
			CheckpointManager.respawn_from_checkpoint()
			return
