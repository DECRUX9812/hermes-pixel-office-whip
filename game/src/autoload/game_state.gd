extends Node
## Persistent runtime state: flags, checkpoint record, death count, save/load.
## Survives scene changes via the autoload singleton; keeps the vertical slice's
## persistent threads (Nous trust, street allegiance, record integrity) as flags.

signal save_loaded
signal new_game_started

const SAVE_PATH := "user://last_open_door_save.cfg"

var last_checkpoint: Dictionary = {}
var flags: Dictionary = {}
var death_count := 0
var started := false

func start_new_game() -> void:
	last_checkpoint = {}
	flags = {}
	death_count = 0
	started = true
	new_game_started.emit()

func set_flag(id: String, value: Variant = true) -> void:
	flags[id] = value

func get_flag(id: String, default: Variant = null) -> Variant:
	return flags.get(id, default)

func has_checkpoint() -> bool:
	return last_checkpoint.has("scene_path")

func record_checkpoint(scene_path: String, position: Vector3, rotation_y: float) -> void:
	last_checkpoint = {
		"scene_path": scene_path,
		"position": position,
		"rotation_y": rotation_y,
	}

func get_checkpoint_position() -> Vector3:
	return last_checkpoint.get("position", Vector3.ZERO)

func get_checkpoint_rotation() -> float:
	return float(last_checkpoint.get("rotation_y", 0.0))

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("checkpoint", "data", last_checkpoint)
	cfg.set_value("flags", "data", flags)
	cfg.set_value("meta", "death_count", death_count)
	cfg.set_value("meta", "started", started)
	cfg.save(SAVE_PATH)

func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	last_checkpoint = cfg.get_value("checkpoint", "data", {})
	flags = cfg.get_value("flags", "data", {})
	death_count = cfg.get_value("meta", "death_count", 0)
	started = cfg.get_value("meta", "started", false)
	save_loaded.emit()
	return true

func delete_save() -> void:
	last_checkpoint = {}
	flags = {}
	death_count = 0
	started = false
	var path := ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
