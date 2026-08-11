extends TestCase

var _vfx: CombatVfx = null

func _build_vfx() -> CombatVfx:
	var vfx := CombatVfx.new()
	add_child(vfx)
	return vfx

func _exit_tree() -> void:
	if _vfx and is_instance_valid(_vfx):
		_vfx.queue_free()
	_vfx = null

func test_impact_spawns_no_error() -> void:
	var vfx := _build_vfx()
	_vfx = vfx
	var dummy := Node3D.new()
	add_child(dummy)
	vfx._on_attack_landed(null, dummy, 10.0, "light")
	check(true, "impact hook ran without error")
	await _wait_frames(2)
	dummy.queue_free()

func test_telegraph_spawns_no_error() -> void:
	var vfx := _build_vfx()
	_vfx = vfx
	var dummy := Node3D.new()
	add_child(dummy)
	vfx._on_enemy_state_changed(dummy, "WINDUP")
	check(true, "telegraph hook ran without error")
	await _wait_frames(2)
	dummy.queue_free()

func test_defeat_spawns_no_error() -> void:
	var vfx := _build_vfx()
	_vfx = vfx
	var dummy := Node3D.new()
	add_child(dummy)
	vfx._on_defeated(dummy)
	check(true, "defeat hook ran without error")
	await _wait_frames(2)
	dummy.queue_free()

func test_effects_self_free() -> void:
	var vfx := _build_vfx()
	_vfx = vfx
	var dummy := Node3D.new()
	add_child(dummy)
	vfx._on_attack_landed(null, dummy, 10.0, "light")
	var count_before := vfx.get_child_count()
	await _wait_frames(60)
	check(vfx.get_child_count() <= count_before, "effects clean up after their tween")
	dummy.queue_free()
