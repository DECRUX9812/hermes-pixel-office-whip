class_name ChoirWarden
extends Combatant
## Choir Warden — Conductor-class construct, the Chapter 2 arena antagonist.
##
## Encounter foundation, not a full boss design. It conducts rather than brawls:
##   - Phase 1 (above 50%): telegraphed sonic sweeps.
##   - Phase 2 (below 50%): requiem channel — a long, vulnerable channel the
##     player must strike to interrupt, exactly as the slice script demands
##     ("strike the Warden's resonator during the requiem"), plus summoning
##     custodians to protect the channel.
##
## Combat readability rules:
##   - Every damaging act has a visible windup (pulsing core light).
##   - The requiem is the ONLY damage window the Warden grants itself.
##   - Heavy / repeated hits stagger it; any hit interrupts a channel.

enum State { SLEEP, ENGAGE, WINDUP_SWEEP, SWEEP, REQUIEM_CHANNEL, SUMMON, RECOVER, HURT, STAGGER, DEFEAT }

const GRAVITY := 18.0

@export var active := false
@export var display_health_name := "CHOIR WARDEN"

@export_group("Sense")
@export var engage_range := 3.0
@export var decide_interval := 0.6

@export_group("Movement")
@export var warden_speed := 2.2

@export_group("Sweep")
@export var sweep_windup := 1.0
@export var sweep_active := 0.35
@export var sweep_damage := 20.0

@export_group("Requiem")
@export var requiem_time := 2.0
@export var requiem_damage := 26.0
@export var requiem_radius := 5.0
@export var requiem_interval := 8.0
@export var vulnerable_multiplier := 2.0

@export_group("Summon")
@export var summon_time := 0.7
@export var summon_interval := 10.0
@export var summon_count := 2
@export var summon_offset := 2.2

@export_group("Recover")
@export var recover_time := 0.85

var state := State.SLEEP
var state_time := 0.0
var attack_cooldown := 0.0
var requiem_cooldown := 0.0
var summon_cooldown := 0.0

const CUSTODIAN_SCENE := preload("res://scenes/world/entities/custodian.tscn")

@onready var visual_root: Node3D = $VisualRoot
@onready var core_light: OmniLight3D = $VisualRoot/CoreLight
@onready var core_glow: MeshInstance3D = $VisualRoot/CoreGlow
@onready var sweep_area: Area3D = $VisualRoot/SweepArea

func _ready() -> void:
	super()
	sweep_area.collision_layer = 0
	sweep_area.collision_mask = PLAYER_LAYER
	_emit_state()

func begin_encounter() -> void:
	if active or dead:
		return
	active = true
	_set_state(State.ENGAGE)

func _physics_process(delta: float) -> void:
	tick_timers(delta)
	if dead:
		move_and_slide()
		return
	if not active:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		move_and_slide()
		return
	state_time += delta
	if attack_cooldown > 0.0:
		attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if requiem_cooldown > 0.0:
		requiem_cooldown = maxf(0.0, requiem_cooldown - delta)
	if summon_cooldown > 0.0:
		summon_cooldown = maxf(0.0, summon_cooldown - delta)
	var target := _find_player()
	match state:
		State.HURT, State.STAGGER:
			if hurt_timer <= 0.0 and stagger_timer <= 0.0:
				_set_state(State.RECOVER)
		State.ENGAGE:
			if target:
				_face_target(target)
				if target.global_position.distance_to(global_position) > engage_range:
					_advance_to(target, delta)
			if state_time >= decide_interval:
				_decide_next()
		State.WINDUP_SWEEP:
			_face_target(target)
			_pulse_core(delta)
			if state_time >= sweep_windup:
				_set_state(State.SWEEP)
		State.SWEEP:
			_face_target(target)
			_sweep_overlap()
			if state_time >= sweep_active:
				_set_state(State.RECOVER)
		State.REQUIEM_CHANNEL:
			_pulse_core(delta)
			if state_time >= requiem_time:
				_finish_requiem()
				set_vulnerable(false)
				_set_state(State.RECOVER)
		State.SUMMON:
			if state_time >= summon_time:
				_spawn_minions()
				_set_state(State.RECOVER)
		State.RECOVER:
			if state_time >= recover_time:
				_set_state(State.ENGAGE)
	move_and_slide()

func _decide_next() -> void:
	var phase2 := health.current_health / health.max_health < 0.5
	if phase2 and summon_cooldown <= 0.0:
		summon_cooldown = summon_interval
		_set_state(State.SUMMON)
		return
	if phase2 and requiem_cooldown <= 0.0:
		requiem_cooldown = requiem_interval
		set_vulnerable(true)
		_set_state(State.REQUIEM_CHANNEL)
		EventBus.combat_event.emit("CHOIR WARDEN begins the requiem — strike it down")
		return
	_set_state(State.WINDUP_SWEEP)

func _sweep_overlap() -> void:
	for body in sweep_area.get_overlapping_bodies():
		if not (body is Player):
			continue
		var target_health := (body as Player).health
		if target_health and target_health.take_damage(sweep_damage, self):
			EventBus.player_hit_received.emit(body, sweep_damage, self)
			EventBus.combat_event.emit("CHOIR WARDEN sweep struck %s (%d)" % [body.name, sweep_damage])

func _finish_requiem() -> void:
	var player := _find_player()
	if player == null:
		return
	var distance := player.global_position.distance_to(global_position)
	if distance > requiem_radius:
		return
	var target_health := (player as Player).health
	if target_health and target_health.take_damage(requiem_damage, self):
		EventBus.player_hit_received.emit(player, requiem_damage, self)
		EventBus.combat_event.emit("Requiem channel completed — %d damage" % requiem_damage)

func _spawn_minions() -> void:
	for i in summon_count:
		var side := 1.0 if i % 2 == 0 else -1.0
		var custodian: Custodian = CUSTODIAN_SCENE.instantiate()
		custodian.position = global_position + Vector3(side * summon_offset, 0.0, 1.0)
		get_parent().add_child(custodian)
		EventBus.combat_event.emit("CHOIR WARDEN summons a Custodian")

func _find_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	var best: Node3D = null
	var best_distance := INF
	for node in players:
		var candidate := node as Node3D
		if candidate == null:
			continue
		var d := candidate.global_position.distance_to(global_position)
		if d < best_distance:
			best_distance = d
			best = candidate
	return best

func _advance_to(target: Node3D, delta: float) -> void:
	var flat := Vector3(target.global_position.x, global_position.y, target.global_position.z) - global_position
	flat.y = 0.0
	if flat.length_squared() < 0.0001:
		return
	var desired := flat.normalized() * warden_speed
	velocity.x = lerpf(velocity.x, desired.x, 4.0 * delta)
	velocity.z = lerpf(velocity.z, desired.z, 4.0 * delta)

func _face_target(target: Node3D) -> void:
	if target == null:
		return
	var to := Vector3(target.global_position.x, global_position.y, target.global_position.z) - global_position
	to.y = 0.0
	if to.length_squared() < 0.0001:
		return
	visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(-to.x, -to.z), 8.0 * get_physics_process_delta_time())

func _pulse_core(delta: float) -> void:
	var phase := fmod(state_time * 10.0, 1.0)
	core_light.visible = phase < 0.7
	core_glow.visible = phase < 0.7

func set_vulnerable(value: bool, multiplier: float = 2.0) -> void:
	damage_taken_multiplier = multiplier if value else 1.0

func interrupt() -> void:
	if state == State.REQUIEM_CHANNEL:
		set_vulnerable(false)
		EventBus.combat_event.emit("CHOIR WARDEN's requiem interrupted")
		_set_state(State.RECOVER)
	elif state == State.WINDUP_SWEEP:
		_set_state(State.RECOVER)

func _set_state(next: State) -> void:
	if state == next:
		return
	state = next
	state_time = 0.0
	if next != State.WINDUP_SWEEP and next != State.REQUIEM_CHANNEL:
		core_light.visible = false
		core_glow.visible = true
	_emit_state()

func _emit_state() -> void:
	EventBus.enemy_state_changed.emit(self, State.keys()[state])

func _on_dead() -> void:
	_set_state(State.DEFEAT)
	set_vulnerable(false)
	core_light.visible = false
	core_glow.visible = false
	EventBus.combat_event.emit("CHOIR WARDEN falls — the Choir goes silent")
	if visual_root:
		var tween := create_tween()
		tween.tween_property(visual_root, "position:y", -1.8, 1.1)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
