extends Node
## Respawn authority. CheckpointArea nodes register spawn data here; on player
## death (or a manual restart) the current scene is reloaded and the player
## re-spawns at the most recent checkpoint transform held by GameState.

var active_checkpoint: CheckpointArea = null

func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)

func set_active(checkpoint: CheckpointArea) -> void:
	active_checkpoint = checkpoint
	var tree := checkpoint.get_tree()
	var scene := tree.current_scene if tree else null
	var scene_path := scene.scene_file_path if scene else "res://scenes/world/chapter2_choir_below.tscn"
	GameState.record_checkpoint(
		scene_path,
		checkpoint.get_spawn_position(),
		checkpoint.get_spawn_rotation_y()
	)

func get_spawn_transform() -> Transform3D:
	var result := Transform3D.IDENTITY
	if GameState.has_checkpoint():
		result = result.rotated(Vector3.UP, GameState.get_checkpoint_rotation())
		result.origin = GameState.get_checkpoint_position()
	return result

func respawn_from_checkpoint() -> void:
	_respawn()

func _on_player_died() -> void:
	await get_tree().create_timer(1.2).timeout
	_respawn()

func _respawn() -> void:
	GameState.death_count += 1
	EventBus.player_respawned.emit()
	var tree := get_tree()
	if tree and tree.current_scene:
		tree.reload_current_scene()
