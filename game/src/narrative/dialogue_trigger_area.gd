class_name DialogueTriggerArea
extends Area3D
## Auto-trigger a DialogueRunner when the player overlaps the volume. Polled (like
## CheckpointArea) so it fires reliably in headless runs where enter/exit signals
## are not flushed. Used for ambient beats the player walks through (descent
## exchange, the announcement, the payoff echo, the Teknium/Nous conversation).

const PLAYER_LAYER := 2

@export var runner_path: NodePath = ^""
@export var once := true

var _triggered := false
var _runner: DialogueRunner = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = PLAYER_LAYER
	monitoring = true
	_runner = get_node_or_null(runner_path) as DialogueRunner

func _physics_process(_delta: float) -> void:
	if _triggered:
		return
	for body in get_overlapping_bodies():
		if body is Player:
			if _runner:
				_runner.play()
			if once:
				_triggered = true
			return

func has_triggered() -> bool:
	return _triggered
