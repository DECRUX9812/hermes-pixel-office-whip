class_name Custodian
extends Combatant
## Custodian construct — the Reliquary's repurposed household guardians.
##
## Readable telegraph-driven state machine:
##   IDLE -> CHASE -> WINDUP (lamp blinks) -> ATTACK (lunge) -> RECOVER -> CHASE
##   any non-attack state reacts to hits: HURT (light) / STAGGER (heavy).
##   Brooklyn's Heart-Bind flips allegiance; a converted Custodian hunts its
##   former kin instead of the squad.
##
## States are simple on purpose: the challenge comes from reading the telegraph,
## not from hidden enemy logic.

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVER, HURT, STAGGER, DEFEAT }

const GRAVITY := 18.0

@export_group("Sense")
@export var aggro_range := 9.0
@export var lose_range := 14.0
@export var attack_range := 1.9

@export_group("Movement")
@export var walk_speed := 3.2
@export var lunge_speed := 7.5

@export_group("Combat")
@export var windup_time := 0.7
@export var attack_active_time := 0.32
@export var recover_time := 0.55
@export var attack_cooldown_time := 1.1
@export var attack_damage := 12.0
@export var telegraph_blink_rate := 12.0

var state := State.IDLE
var state_time := 0.0
var attack_cooldown := 0.0

@onready var visual_root: Node3D = $VisualRoot
@onready var eye_light: OmniLight3D = $VisualRoot/EyeLight
@onready var eye_glow: MeshInstance3D = $VisualRoot/EyeGlow
@onready var attack_area: Area3D = $VisualRoot/AttackArea

func _ready() -> void:
	super()
	attack_area.collision_layer = 0
	attack_area.collision_mask = PLAYER_LAYER
	_emit_state()

func _physics_process(delta: float) -> void:
	tick_timers(delta)
	if dead:
		move_and_slide()
		return
	state_time += delta
	if attack_cooldown > 0.0:
		attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var target := _resolve_target()
	match state:
		State.HURT, State.STAGGER:
			# Held by the reaction timers in tick_timers(); recover when free.
			if hurt_timer <= 0.0 and stagger_timer <= 0.0:
				_set_state(State.CHASE if target != null else State.IDLE)
		State.WINDUP:
			_blink_telegraph(delta)
			_face_target(target)
			if state_time >= windup_time:
				_set_state(State.ATTACK)
		State.ATTACK:
			if target != null:
				_face_target(target)
				_lunge(delta)
			_attack_overlap()
			if state_time >= attack_active_time:
				attack_cooldown = attack_cooldown_time
				_set_state(State.RECOVER)
		State.RECOVER:
			if state_time >= recover_time:
				_set_state(State.CHASE if target != null else State.IDLE)
		State.IDLE:
			if target != null and target.global_position.distance_to(global_position) <= aggro_range:
				_set_state(State.CHASE)
		State.CHASE:
			if target == null:
				_set_state(State.IDLE)
			elif target.global_position.distance_to(global_position) > lose_range and hostile:
				_set_state(State.IDLE)
			else:
				_face_target(target)
				if target.global_position.distance_to(global_position) <= attack_range and attack_cooldown <= 0.0:
					_set_state(State.WINDUP)
				else:
					_chase_move(delta)
	move_and_slide()

func _resolve_target() -> Node3D:
	if hostile:
		var player := _find_player()
		if player:
			return player as Node3D
		return null
	# Converted: hunt the nearest hostile construct.
	var best: Node3D = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("hostile"):
		if node == self:
			continue
		var candidate := node as Node3D
		if candidate == null:
			continue
		if candidate.has_method("is_hostile") and not candidate.is_hostile():
			continue
		var d := candidate.global_position.distance_to(global_position)
		if d < best_distance:
			best_distance = d
			best = candidate
	return best

func _find_player() -> Node:
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

func _chase_move(delta: float) -> void:
	var target := _resolve_target()
	if target == null:
		return
	var dir := Vector3(target.global_position.x, global_position.y, target.global_position.z) - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return
	var desired := dir.normalized() * walk_speed
	velocity.x = lerpf(velocity.x, desired.x, 6.0 * delta)
	velocity.z = lerpf(velocity.z, desired.z, 6.0 * delta)

func _lunge(delta: float) -> void:
	var target := _resolve_target()
	var dir := Vector3.FORWARD
	if target != null:
		var flat := Vector3(target.global_position.x, global_position.y, target.global_position.z) - global_position
		flat.y = 0.0
		if flat.length_squared() > 0.0001:
			dir = flat.normalized()
	velocity.x = dir.x * lunge_speed
	velocity.z = dir.z * lunge_speed
	velocity.y = move_toward(velocity.y, -GRAVITY * 0.1, GRAVITY * delta)

func _attack_overlap() -> void:
	for body in attack_area.get_overlapping_bodies():
		if not _is_valid_target(body):
			continue
		var health := _resolve_target_health(body)
		if health == null or health.is_dead():
			continue
		if health.take_damage(attack_damage, self):
			EventBus.player_hit_received.emit(body, attack_damage, self)
			EventBus.combat_event.emit("%s struck %s (%d)" % [display_name, body.name, attack_damage])

func _is_valid_target(body: Node) -> bool:
	if body.has_method("is_hostile"):
		return body.is_hostile()
	return body is Player

func _resolve_target_health(body: Node) -> HealthComponent:
	if body is HealthComponent:
		return body as HealthComponent
	var direct := body.get_node_or_null("Health") as HealthComponent
	if direct:
		return direct
	var parent := body.get_parent()
	if parent is Node:
		return parent.get_node_or_null("Health") as HealthComponent
	return null

func _face_target(target: Node3D) -> void:
	if target == null:
		return
	var to := Vector3(target.global_position.x, global_position.y, target.global_position.z) - global_position
	to.y = 0.0
	if to.length_squared() < 0.0001:
		return
	visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(-to.x, -to.z), 10.0 * get_physics_process_delta_time())

func _blink_telegraph(delta: float) -> void:
	var phase := fmod(state_time * telegraph_blink_rate, 1.0)
	eye_glow.visible = phase < 0.6
	eye_light.visible = phase < 0.6

func convert(duration: float) -> bool:
	if dead:
		return false
	set_hostile(false)
	attack_cooldown = 0.0
	_set_state(State.IDLE)
	EventBus.custodian_converted.emit(self, duration)
	EventBus.combat_event.emit("Heart-Bind: %s converted (%ds)" % [display_name, duration])
	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(_on_conversion_expire)
	return true

func _on_conversion_expire() -> void:
	if dead or is_queued_for_deletion():
		return
	set_hostile(true)
	_set_state(State.IDLE)
	EventBus.combat_event.emit("%s's conversion faded" % display_name)

func interrupt() -> void:
	if state == State.WINDUP or state == State.ATTACK:
		_set_state(State.RECOVER)
		attack_cooldown = maxf(attack_cooldown, 0.4)

func _set_state(next: State) -> void:
	if state == next:
		return
	state = next
	state_time = 0.0
	if next != State.WINDUP and next != State.ATTACK:
		eye_light.visible = false
		eye_glow.visible = true
	_emit_state()

func _emit_state() -> void:
	EventBus.enemy_state_changed.emit(self, State.keys()[state])

func _on_dead() -> void:
	_set_state(State.DEFEAT)
	eye_light.visible = false
	eye_glow.visible = false
	EventBus.combat_event.emit("%s disabled" % display_name)
	if visual_root:
		var tween := create_tween()
		tween.tween_property(visual_root, "position:y", -1.4, 0.9)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
