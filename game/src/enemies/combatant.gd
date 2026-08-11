class_name Combatant
extends CharacterBody3D
## Shared enemy foundation (Custodian constructs, the Choir Warden).
##
## Owns what every hostile needs regardless of its AI:
##  - a HealthComponent ("Health" child),
##  - hit reactions (hurt pause, heavy stagger, knockback, hit flash),
##  - the reveal mark (Nous's Truth Breach -> incoming-damage multiplier),
##  - allegiance (Brooklyn's Heart-Bind flips a construct to friendly),
##  - defeat -> EventBus.combatant_defeated.
##
## Derived classes own their state machines; they call tick_timers() and
## move_and_slide() from their own _physics_process.

signal hurt(strength: String)
signal defeated(combatant: Combatant)

const DAMAGEABLE_LAYER := 16
const ENEMY_LAYER := 64
const WORLD_LAYER := 1
const PLAYER_LAYER := 2

@export var display_name := "Construct"
@export var hurt_duration := 0.26
@export var stagger_duration := 0.9
@export var flash_duration := 0.16
@export var knockback_strength := 3.0
@export var heavy_knockback_strength := 5.5

var hostile := true
var dead := false
var hurt_timer := 0.0
var stagger_timer := 0.0
var reveal_timer := 0.0
var reveal_multiplier := 1.0
var damage_taken_multiplier := 1.0
var _flash_timer := 0.0
var _knockback := Vector3.ZERO
var _dead_elapsed := 0.0
var _defeat_emitted := false

@onready var health: HealthComponent = $Health
@onready var flash_mesh: Node3D = $FlashMesh

func _ready() -> void:
	if hostile:
		add_to_group("hostile")
	health.depleted.connect(_on_health_depleted)
	EventBus.enemy_spawned.emit(self)

func is_hostile() -> bool:
	return hostile

func set_hostile(value: bool) -> void:
	if hostile == value:
		return
	hostile = value
	if hostile:
		add_to_group("hostile")
	else:
		remove_from_group("hostile")

func get_reveal_multiplier() -> float:
	return reveal_multiplier if reveal_timer > 0.0 else 1.0

func truth_reveal(duration: float) -> bool:
	reveal_timer = duration
	reveal_multiplier = 2.0
	EventBus.truth_revealed.emit(self, duration)
	EventBus.combat_event.emit("Truth Breach: %s revealed" % display_name)
	return true

func convert(duration: float) -> bool:
	## Allegiance flip. Custodian overrides; the Warden is sealed in its purpose.
	return false

func take_hit(amount: float, direction: Vector3, is_heavy: bool, attacker: Node = null) -> bool:
	if dead:
		return false
	var effective := amount * get_reveal_multiplier() * damage_taken_multiplier
	if not health.take_damage(effective, attacker):
		return false
	EventBus.damage_dealt.emit(attacker, self, effective, "heavy" if is_heavy else "light")
	if is_heavy:
		stagger_timer = stagger_duration
		hurt_timer = 0.0
		hurt.emit("stagger")
	else:
		hurt_timer = hurt_duration
		stagger_timer = 0.0
		hurt.emit("hurt")
	var flat := Vector3(direction.x, 0.0, direction.z).normalized()
	_knockback = flat * (heavy_knockback_strength if is_heavy else knockback_strength)
	_flash()
	interrupt()
	return true

func interrupt() -> void:
	## Derived state machines cancel telegraphed or channeled attacks here.
	pass

func tick_timers(delta: float) -> void:
	if hurt_timer > 0.0:
		hurt_timer = maxf(0.0, hurt_timer - delta)
	if stagger_timer > 0.0:
		stagger_timer = maxf(0.0, stagger_timer - delta)
	if reveal_timer > 0.0:
		reveal_timer = maxf(0.0, reveal_timer - delta)
		if reveal_timer <= 0.0:
			reveal_multiplier = 1.0
	if _flash_timer > 0.0:
		_flash_timer = maxf(0.0, _flash_timer - delta)
		if _flash_timer <= 0.0:
			_flash_off()
	if _knockback.length_squared() > 0.0001:
		velocity.x = _knockback.x
		velocity.z = _knockback.z
		_knockback = _knockback.move_toward(Vector3.ZERO, 16.0 * delta)
	if dead:
		_dead_elapsed += delta
		if _dead_elapsed >= 1.4 and not is_queued_for_deletion():
			queue_free()

func _flash() -> void:
	_flash_timer = flash_duration
	if flash_mesh:
		flash_mesh.visible = true

func _flash_off() -> void:
	if flash_mesh:
		flash_mesh.visible = false

func _on_health_depleted(_source: Node) -> void:
	dead = true
	hurt_timer = 0.0
	stagger_timer = 0.0
	set_hostile(false)
	if not _defeat_emitted:
		_defeat_emitted = true
		EventBus.combatant_defeated.emit(self)
		defeated.emit(self)
	_on_dead()

## Override for defeat visuals (sink, flame-out, etc).
func _on_dead() -> void:
	pass
