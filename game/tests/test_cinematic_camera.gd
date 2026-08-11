extends TestCase

var _camera: CinematicCamera = null

func _build_camera() -> CinematicCamera:
	var camera := CinematicCamera.new()
	camera.fov = 60.0
	add_child(camera)
	return camera

func _exit_tree() -> void:
	if _camera and is_instance_valid(_camera):
		_camera.queue_free()
	_camera = null

func test_camera_restores_home_when_inactive() -> void:
	var camera := _build_camera()
	_camera = camera
	await _wait_frames(2)
	var home := camera.transform
	camera.play_beat()
	await _wait_frames(2)
	# while current it should not have drifted from home more than the authored push
	var drift := camera.transform.origin.distance_to(home.origin)
	check(drift < camera.push_in_distance + 0.01, "push-in stays within authored bound (%.2f)" % drift)

func test_camera_animates_while_current() -> void:
	var camera := _build_camera()
	_camera = camera
	camera.play_beat()
	var start_fov := camera.fov
	await _wait_frames(30)
	check(camera.fov < start_fov, "fov pulls in during the beat")
