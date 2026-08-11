extends Node
## Central signal bus. Keeps cross-system communication decoupled so gameplay
## modules can be replaced (blockout -> authored art, prototype -> production)
## without rewiring unrelated systems.

signal player_spawned(player: Node3D)
signal player_movement_state_changed(state: String)
signal player_dodged
signal player_died
signal player_respawned

signal health_changed(node: Node, current: float, maximum: float, delta: float)
signal resolve_changed(node: Node, current: float, maximum: float, delta: float)

signal interactable_focused(interactable: Interactable)
signal interactable_unfocused
signal interaction_performed(interactable: Interactable)
signal story_beat_triggered(beat_id: String)

signal objective_updated(objective: Objective)
signal objective_completed(objective_id: String)

signal checkpoint_reached(checkpoint: CheckpointArea)

signal game_paused
signal game_unpaused

signal subtitle_requested(speaker: String, text: String)

signal combatant_defeated(combatant: Node)
signal truth_layer_toggled(active: bool)

signal scene_loading(scene_path: String)
signal scene_loaded(scene_path: String)
