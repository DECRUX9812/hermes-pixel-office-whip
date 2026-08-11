class_name Player
extends CharacterBody3D
## Teknium, the player lead. Third-person CharacterBody3D with camera-relative
## movement, jump, sprint, a bounded-invulnerability dodge, and minimal melee.
## The physics body never rotates — the visual root faces the move direction so
## the spring-arm camera stays independent of body rotation.

signal movement_state_changed(state: String)

enum MoveState { GROUND, AIR, DODGE }

const WORLD_LAYER := 1

@export_group("Movement")
@export var walk_speed := 4.5
@export var sprint_speed := 7.5
@export var acceleration := 12.0
@export var air_acceleration := 5.0
@export var ground_friction := 10.0
@export var gravity := 18.0
@export var jump_velocity := 6.5
@export var max_fall_speed := 28.0
@export var rotation_speed := 12.0

@export_group("Dodge")
@export var dodge_speed := 11.0
@export var dodge_duration := 0.28
@export var dodge_invulnerability := 0.35
@export var dodge_cooldown := 0.9

var alive := true
var move_state := MoveState.GROUND
var _state_timer := 0.0
var _dodge_vector := Vector3.ZERO
var _dodge_cooldown := 0.0

@onready var camera_rig: CameraRig = $CameraRig
@onready var visual_root: Node3D = $VisualRoot
@onready var health: HealthComponent = $Health
@onready var resolve: ResolveComponent = $Resolve
@onready var interaction: InteractionController = $Interaction
@onready var melee: MeleeController = $Melee
@onready var targeting: TargetingController = $Targeting
@onready var companions: CompanionController = $Companions

func _ready() -> void:
	add_to_group("player")
	health.depleted.connect(_on_health_depleted)
	EventBus.player_spawned.emit(self)
	_apply_checkpoint_spawn()

func _physics_process(delta: float) -> void:
	if _dodge_cooldown > 0.0:
		_dodge_cooldown = maxf(0.0, _dodge_cooldown - delta)
	if not alive:
		velocity.x = lerpf(velocity.x, 0.0, delta * 4.0)
		velocity.z = lerpf(velocity.z, 0.0, delta * 4.0)
		move_and_slide()
		return
	match move_state:
		MoveState.DODGE:
			_physics_dodge(delta)
		_:
			_physics_ground_air(delta)
	targeting.update(self, delta)
	_poll_actions()

func _physics_ground_air(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish_dir := _wish_direction(input_dir)
	var moving := input_dir.length() > 0.1

	if move_state == MoveState.GROUND:
		var sprinting := Input.is_action_pressed("sprint") and moving
		var target_speed := sprint_speed if sprinting else walk_speed
		var accel := acceleration if moving else ground_friction
		_apply_horizontal_velocity(wish_dir, target_speed, accel, delta)
		_face_direction(wish_dir, moving, delta)
	else:
		_apply_horizontal_velocity(wish_dir, walk_speed, air_acceleration, delta)

	if is_on_floor():
		if move_state == MoveState.AIR:
			move_state = MoveState.GROUND
			_emit_state()
	else:
		velocity.y -= gravity * delta
		velocity.y = maxf(velocity.y, -max_fall_speed)

	move_and_slide()

func _physics_dodge(delta: float) -> void:
	_state_timer -= delta
	velocity.x = _dodge_vector.x * dodge_speed
	velocity.z = _dodge_vector.z * dodge_speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	if _state_timer <= 0.0:
		move_state = MoveState.AIR if not is_on_floor() else MoveState.GROUND
		velocity.x = 0.0
		velocity.z = 0.0
		_emit_state()

func _poll_actions() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor() and move_state != MoveState.DODGE:
		velocity.y = jump_velocity
		move_state = MoveState.AIR
		_emit_state()
		return
	if Input.is_action_just_pressed("dodge") and _dodge_cooldown <= 0.0 and move_state != MoveState.DODGE:
		melee.cancel_to_dodge()
		_start_dodge()
		return
	if Input.is_action_just_pressed("interact"):
		interaction.perform_interaction()
	if Input.is_action_just_pressed("attack_light"):
		melee.try_light_attack()
	if Input.is_action_just_pressed("attack_heavy"):
		melee.try_heavy_attack()
	if Input.is_action_just_pressed("lock_on"):
		targeting.toggle_lock(self)
	if Input.is_action_just_pressed("companion_command"):
		companions.try_command(self)
	if Input.is_action_just_pressed("switch_companion"):
		companions.switch_active()

func get_combat_target() -> Node3D:
	return targeting.get_target(self)

func set_visual_facing(direction: Vector3) -> void:
	if direction.length_squared() < 0.0001:
		return
	visual_root.rotation.y = atan2(-direction.x, -direction.z)

func is_locked_on() -> bool:
	return targeting.is_locked()

func locked_target() -> Node3D:
	return targeting.locked_target

func get_dodge_cooldown() -> float:
	return _dodge_cooldown

func _wish_direction(input_dir: Vector2) -> Vector3:
	# Input.get_vector maps move_forward to the negative Y axis (y = -1 when
	# walking forward), so negate before composing with camera-forward.
	var forward := camera_rig.get_flat_forward()
	var right := camera_rig.get_flat_right()
	return (forward * -input_dir.y + right * input_dir.x).normalized()

func _apply_horizontal_velocity(dir: Vector3, target_speed: float, accel: float, delta: float) -> void:
	var current_h := Vector2(velocity.x, velocity.z)
	var target_h := Vector2(dir.x, dir.z) * target_speed
	var new_h := current_h.move_toward(target_h, accel * delta)
	velocity.x = new_h.x
	velocity.z = new_h.y

func _face_direction(dir: Vector3, moving: bool, delta: float) -> void:
	if not moving or melee.is_attacking():
		return
	var target_yaw := atan2(-dir.x, -dir.z)
	visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_yaw, rotation_speed * delta)

func _start_dodge() -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := _wish_direction(input_dir)
	if dir.length_squared() < 0.01:
		dir = camera_rig.get_flat_forward() * -1.0
	_dodge_vector = dir.normalized()
	move_state = MoveState.DODGE
	_state_timer = dodge_duration
	health.grant_invulnerability_window(dodge_invulnerability)
	_dodge_cooldown = dodge_cooldown
	EventBus.player_dodged.emit()
	_emit_state()

func _on_health_depleted(_source: Node) -> void:
	alive = false
	move_state = MoveState.GROUND
	EventBus.player_died.emit()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _apply_checkpoint_spawn() -> void:
	if not GameState.has_checkpoint():
		return
	var scene := get_tree().current_scene
	if scene and scene.scene_file_path == GameState.last_checkpoint.get("scene_path", ""):
		var spawn := CheckpointManager.get_spawn_transform()
		global_position = spawn.origin
		camera_rig.set_yaw(spawn.basis.get_euler().y)
		visual_root.rotation.y = 0.0

func _emit_state() -> void:
	var label: String = MoveState.keys()[move_state]
	movement_state_changed.emit(label)
	EventBus.player_movement_state_changed.emit(label)
