class_name TrainingDummy
extends StaticBody3D
## A damageable practice target standing in for the first Custodian construct in
## the Choir threshold. On defeat it raises EventBus.combatant_defeated, which the
## chapter director turns into objective completion.

const DAMAGEABLE_LAYER := 16

@export var display_name := "Training Dummy"

@onready var health: HealthComponent = $Health

func _ready() -> void:
	collision_layer = DAMAGEABLE_LAYER
	collision_mask = 0
	health.depleted.connect(_on_depleted)

func _on_depleted(_source: Node) -> void:
	EventBus.combatant_defeated.emit(self)
