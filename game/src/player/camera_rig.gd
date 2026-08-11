class_name CameraRig
extends Node3D
## Third-person spring-arm camera. The rig holds yaw; the child SpringArm holds
## pitch and camera distance, so the player body never rotates with the camera.
## Mouse look only applies while the pointer is captured (i.e. not in menus).

const WORLD_LAYER := 1

@export var mouse_sensitivity := 0.0022
@export var gamepad_sensitivity := 3.0
@export var pitch_min_deg := -80.0
@export var pitch_max_deg := 60.0
@export var camera_distance := 4.2

var yaw := 0.0
var pitch := 0.0

@onready var spring: SpringArm3D = $SpringArm
@onready var camera: Camera3D = $SpringArm/Camera3D

func _ready() -> void:
	spring.spring_length = camera_distance
	spring.collision_mask = WORLD_LAYER
	var player := get_parent()
	if player is CollisionObject3D:
		spring.add_excluded_object((player as CollisionObject3D).get_rid())
	_apply()

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		var multiplier := mouse_sensitivity * Settings.camera_sensitivity
		yaw += -motion.relative.x * multiplier
		var p_delta := motion.relative.y * multiplier
		if Settings.invert_y:
			p_delta = -p_delta
		pitch = clampf(pitch + p_delta, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
		_apply()
	elif event is InputEventJoypadMotion:
		var joy := event as InputEventJoypadMotion
		var delta := get_process_delta_time()
		if joy.axis == 2:
			yaw += -joy.axis_value * gamepad_sensitivity * delta
		elif joy.axis == 3:
			var p_delta := joy.axis_value * gamepad_sensitivity * delta
			if Settings.invert_y:
				p_delta = -p_delta
			pitch = clampf(pitch + p_delta, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
		_apply()

func set_yaw(value: float) -> void:
	yaw = value
	_apply()

func set_pitch(value: float) -> void:
	pitch = clampf(value, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
	_apply()

func sync_from_transform(transform: Transform3D) -> void:
	yaw = transform.basis.get_euler().y
	_apply()

func get_flat_forward() -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))

func get_flat_right() -> Vector3:
	return Vector3(cos(yaw), 0.0, -sin(yaw))

func _apply() -> void:
	rotation.y = yaw
	spring.rotation.x = pitch
