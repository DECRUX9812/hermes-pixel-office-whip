extends Node
## Scripted action scene — HERMES: THE LAST OPEN DOOR, Chapter 2 arena fight.
##
## Movie capture / autoplay combat demo. Instantiates chapter2_choir_below.tscn,
## hides HUD/PauseMenu/CombatTelemetry/TitleCard, stages the squad in the arena
## and AUTOPLAYS a scripted fight by driving the EXISTING systems only:
##   - MeleeController.try_light_attack / try_heavy_attack / is_attack_ready
##   - TargetingController.locked_target (lock-on drives the rig camera)
##   - EncounterController.begin() (the Beats/Arena/Encounter)
##   - CompanionController.try_command() (Nous truth-breach flash)
##   - synthesized input for the dodge action (player._poll_actions path)
##   - CombatVfx fires off EventBus as the fight plays (swing arcs, impact
##     flashes, telegraph rings, dodge afterimage, defeat dissolve)
## No gameplay scripts are edited and no new gameplay systems are added.
##
## Beat sequence: squad approaches through the columns -> lock CustodianA ->
## 3-hit light combo (HURT reactions) -> CustodianB advances, dodge + punish ->
## custodians fall -> Warden activates, sweep while player circles + heavy ->
## companion ability flash -> quiet ending facing the Hermes door, camera push.
##
## Usage (movie):
##   godot4 --path . res://production/combat_demo.tscn --write-movie /tmp/fight.avi \
##          --fixed-fps 30 --resolution 1920x1080
## Evidence (under a display / Xvfb):
##   godot4 --path . res://production/combat_demo.tscn -- --evidence
## Smoke test (headless):
##   godot4 --headless --path . res://production/combat_demo.tscn -- --test 20

const CHAPTER2 := "res://scenes/world/chapter2_choir_below.tscn"
const EVIDENCE_DIR := "res://production/evidence"
const FLOOR_Y := -8.0
const EVIDENCE_TIMES := { 1: 4.6, 3: 16.3 }

var world: Node3D
var player: Player
var warden: ChoirWarden
var custodian_a: Custodian
var custodian_b: Custodian
var nous: Node3D
var brooklyn: Node3D
var encounter: EncounterController
var lighting: LightingDirector

var _elapsed := 0.0
var _quit_at := 0.0
var _evidence := false
var _captured := {}
var _run_done := false
var _run_done_at := 0.0
var _finished := false
var _end_cam: Camera3D

func _ready() -> void:
	_parse_args()
	var scene: PackedScene = load(CHAPTER2)
	world = scene.instantiate()
	add_child(world)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var env_node := world.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env_node and env_node.environment:
		env_node.environment.glow_hdr_threshold = 1.05
	for ui in ["HUD", "PauseMenu", "CombatTelemetry", "TitleCard"]:
		var node := world.get_node_or_null(ui)
		if node:
			node.visible = false
	player = world.get_node("Player")
	warden = world.get_node("Beats/Arena/Warden")
	custodian_a = world.get_node("Beats/Arena/CustodianA")
	custodian_b = world.get_node("Beats/Arena/CustodianB")
	nous = world.get_node("Beats/Companions/Nous")
	brooklyn = world.get_node("Beats/Companions/Brooklyn")
	encounter = world.get_node("Beats/Arena/Encounter")
	lighting = world.get_node("LightingDirector")
	encounter.auto_trigger = false
	custodian_a.aggro_range = 0.0
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	_stage_arena()
	await get_tree().process_frame
	await get_tree().process_frame
	_run()

func _process(delta: float) -> void:
	_elapsed += delta
	if _evidence:
		for key in EVIDENCE_TIMES:
			if not _captured.has(key) and _elapsed >= float(EVIDENCE_TIMES[key]):
				_captured[key] = true
				_capture_evidence(int(key))
	if _quit_at > 0.0 and _elapsed >= _quit_at:
		_finish()
		return
	if _run_done and _elapsed >= _run_done_at:
		_finish()

## --- Staging -----------------------------------------------------------------

func _stage_arena() -> void:
	warden.global_position = Vector3(0, FLOOR_Y, -100)
	custodian_a.global_position = Vector3(4, FLOOR_Y, -95)
	custodian_b.global_position = Vector3(-4, FLOOR_Y, -105)
	player.global_position = Vector3(0, FLOOR_Y, -89.5)
	player.set_visual_facing(Vector3(0, 0, -1))
	nous.global_position = Vector3(-1.4, FLOOR_Y, -88.8)
	brooklyn.global_position = Vector3(1.6, FLOOR_Y, -88.6)

## --- The fight ---------------------------------------------------------------

func _run() -> void:
	lighting.apply_rig("arena", true)
	# Beat 1: squad approaches through the columns.
	await _walk_to(Vector3(2.6, FLOOR_Y, -93.6), 2.6)
	# Beat 2: lock CustodianA, land a 3-hit light combo (HURT reactions).
	await _lock(custodian_a)
	await _seconds(0.3)
	await _attack_chain(custodian_a, false, 3)
	# Beat 3: CustodianB advances, player dodges and counter-attacks.
	await _walk_to(Vector3(-2.8, FLOOR_Y, -100.6), 1.6)
	await _lock(custodian_b)
	await _seconds(0.2)
	await _await_until(func(): return custodian_b.state == Custodian.State.ATTACK)
	await _seconds(0.1)
	await _dodge(&"move_right")
	if _evidence:
		_capture_evidence(2)
	await _seconds(0.35)
	var bpos := custodian_b.global_position
	await _move_over(Vector3(bpos.x + 1.5, FLOOR_Y, bpos.z + 3.0), 0.8)
	await _attack_chain(custodian_b, true, 2)
	await _attack_chain(custodian_b, false, 3)
	await _seconds(1.2)
	# Beat 4: custodians fall -> Warden activates, sweeps, player circles + heavy.
	await _stage_warden_beat()
	# Beat 5: quiet ending facing the Hermes door.
	await _ending()
	_run_done = true
	_run_done_at = _elapsed + 1.2

func _stage_warden_beat() -> void:
	player.global_position = Vector3(-1.2, FLOOR_Y, -98.5)
	player.set_visual_facing(warden.global_position - player.global_position)
	await _lock(warden)
	encounter.begin()
	await _await_until(func(): return warden.state == ChoirWarden.State.WINDUP_SWEEP)
	await _warden_circle(1.35)
	await _await_until(func(): return warden.state == ChoirWarden.State.RECOVER)
	await _dash_in(1.4)
	await _attack_chain(warden, true, 1)
	warden.active = false
	await _seconds(0.2)
	# Companion ability flash at the scripted moment (Nous truth-breach).
	if not player.companions.try_command(player):
		warden.truth_reveal(5.0)
	await _seconds(1.0)

func _ending() -> void:
	lighting.apply_rig("silence")
	player.global_position = Vector3(0, FLOOR_Y, -107.0)
	player.set_visual_facing(Vector3(0, 0, -1))
	nous.global_position = Vector3(1.6, FLOOR_Y, -106.6)
	brooklyn.global_position = Vector3(-1.7, FLOOR_Y, -107.0)
	warden.active = false
	var cam := Camera3D.new()
	cam.name = "EndCam"
	add_child(cam)
	cam.current = true
	cam.fov = 54.0
	_end_cam = cam
	var from := Vector3(2.2, -7.4, -99.0)
	var to := Vector3(1.3, -7.7, -104.0)
	var look := Vector3(0, -5.6, -110.5)
	for i in 360:
		var t := float(i + 1) / 360.0
		var e := smoothstep(0.0, 1.0, t)
		cam.global_position = from.lerp(to, e)
		cam.look_at(look, Vector3.UP)
		cam.fov = lerpf(54.0, 45.0, e)
		await get_tree().physics_frame

## --- Combat choreography helpers (drive existing systems) --------------------

func _walk_to(pos: Vector3, duration: float) -> void:
	var start := player.global_position
	var frames := maxi(1, int(round(duration * 60.0)))
	for i in frames:
		var t := float(i + 1) / float(frames)
		player.global_position = start.lerp(pos, smoothstep(0.0, 1.0, t))
		player.set_visual_facing(pos - start)
		await get_tree().physics_frame
	player.global_position = pos

func _move_over(pos: Vector3, duration: float) -> void:
	var start := player.global_position
	var frames := maxi(1, int(round(duration * 60.0)))
	for i in frames:
		var t := float(i + 1) / float(frames)
		player.global_position = start.lerp(pos, smoothstep(0.0, 1.0, t))
		await get_tree().physics_frame
	player.global_position = pos

func _stand_face(target: Node3D, distance: float) -> void:
	var dir := target.global_position - player.global_position
	dir.y = 0.0
	if dir.length() < 0.01:
		dir = Vector3(0, 0, -1)
	dir = dir.normalized()
	var pos := target.global_position - dir * distance
	pos.y = FLOOR_Y
	player.global_position = pos
	player.set_visual_facing(target.global_position - pos)
	await get_tree().physics_frame

func _lock(target: Node3D) -> void:
	player.targeting.locked_target = target
	await get_tree().physics_frame

func _attack_chain(target: Node3D, heavy: bool, steps: int) -> void:
	for i in steps:
		await _stand_face(target, 1.35)
		while not player.melee.is_attack_ready():
			await get_tree().physics_frame
		var ok := false
		if heavy:
			ok = player.melee.try_heavy_attack()
		else:
			ok = player.melee.try_light_attack()
		if not ok:
			await get_tree().physics_frame
			continue
		await player.melee.attack_finished
		await get_tree().physics_frame
		if target is Combatant and (target as Combatant).dead:
			break

func _dodge(move_action: StringName) -> void:
	Input.action_press(move_action)
	Input.action_press(&"dodge")
	await get_tree().physics_frame
	Input.action_release(&"dodge")
	await get_tree().physics_frame
	Input.action_release(move_action)

func _warden_circle(duration: float) -> void:
	var frames := int(duration * 60.0)
	for i in frames:
		var t := float(i + 1) / float(frames)
		var a := _player_angle_around() + t * 1.7
		var radius := lerpf(2.0, 3.85, minf(1.0, t * 2.2))
		var pos := warden.global_position + Vector3(cos(a) * radius, 0.0, sin(a) * radius)
		pos.y = FLOOR_Y
		player.global_position = pos
		player.set_visual_facing(warden.global_position - pos)
		await get_tree().physics_frame

func _player_angle_around() -> float:
	var off := player.global_position - warden.global_position
	return atan2(off.z, off.x)

func _dash_in(distance: float) -> void:
	var off := player.global_position - warden.global_position
	off.y = 0.0
	var dir := off.normalized() if off.length() > 0.01 else Vector3(0, 0, -1)
	await _move_over(warden.global_position + dir * distance, 0.4)
	player.set_visual_facing(warden.global_position - player.global_position)

func _seconds(sec: float) -> void:
	var frames := maxi(1, int(round(sec * 60.0)))
	for _i in frames:
		await get_tree().physics_frame

func _await_until(cond: Callable, max_seconds := 12.0) -> bool:
	var frames := int(max_seconds * 60.0)
	for _i in frames:
		if cond.call():
			return true
		await get_tree().physics_frame
	push_warning("combat_demo: await timeout on %s" % cond)
	return false

## --- Evidence capture --------------------------------------------------------

func _capture_evidence(key: int) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/demo_combat%d.png" % [EVIDENCE_DIR, key]
	var err := img.save_png(ProjectSettings.globalize_path(path))
	if err == OK:
		print("EVIDENCE_OK %s" % path)
	else:
		push_error("combat_demo: evidence save failed (%d) %s" % [err, path])

## --- Args / quit --------------------------------------------------------------

func _parse_args() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--test":
				if i + 1 < args.size():
					_quit_at = float(args[i + 1])
					i += 1
			"--evidence":
				_evidence = true
		i += 1
	if _evidence and _quit_at <= 0.0:
		_quit_at = float(EVIDENCE_TIMES[3]) + 1.5

func _finish() -> void:
	if _finished:
		return
	_finished = true
	print("COMBAT_DEMO_DONE %.1fs" % _elapsed)
	get_tree().quit(0)
