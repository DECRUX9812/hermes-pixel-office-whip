extends Node
## Cinematic action trailer — HERMES: THE LAST OPEN DOOR, Chapter 2.
##
## Movie-maker pattern driven capture. Staged ~40s ACTION cut that drives the
## existing systems for the combat beats so real gameplay VFX land on camera:
##   - SHOTS: camera keyframes (pos/look/fov) + lighting rigs + staging
##   - Shots 4-6 autoplay real combat (MeleeController, TargetingController,
##     EncounterController, CompanionController) — swing arcs, impact flashes,
##     telegraph rings, dodge afterimage and defeat dissolve all fire via the
##     existing CombatVfx/EventBus path.
##
## Movie usage (from game/):
##   godot4 --path . res://production/demo_capture.tscn --write-movie /tmp/raw.avi \
##          --fixed-fps 30 --resolution 1920x1080 [-- --test <seconds>]
##
## Pure capture: hides HUD/UI, stages the squad on the authored path and never
## changes gameplay scenes or assets.

const CHAPTER2 := "res://scenes/world/chapter2_choir_below.tscn"

## [dur, from_pos, from_look, to_pos, to_look, fov_from, fov_to, rig]
const SHOTS := [
	# 1 — street dolly (ice): wide dolly down the empty street, squad ahead
	[5.0, Vector3(3.4, 2.0, -26), Vector3(0, 1, -13.5), Vector3(2.6, 1.9, -16.5), Vector3(0, 1, -13.5), 60.0, 52.0, "ice"],
	# 2 — breach push (weep): squad silhouetted against the breach's emerald glow
	[5.0, Vector3(3.0, 1.7, -38.5), Vector3(0, 1, -44), Vector3(2.0, 1.6, -40.5), Vector3(0, 1, -44), 55.0, 55.0, "weep"],
	# 3 — threshold loom (threshold): low angle, the Custodians loom behind the squad
	[5.0, Vector3(1.5, -6.8, -81.6), Vector3(0, -6.4, -86.8), Vector3(0.9, -7.0, -82.6), Vector3(0, -6.4, -86.8), 58.0, 50.0, "threshold"],
	# 4 — arena combat two-shot (arena, 8s): player vs CustodianA with VFX
	[8.0, Vector3(3.2, -7.3, -92.8), Vector3(1.6, -6.8, -95.3), Vector3(2.2, -7.5, -94.2), Vector3(1.6, -6.8, -95.3), 52.0, 46.0, "arena"],
	# 5 — warden boss beat, low angle (arena, 8s): sweep, circle, heavy
	[8.0, Vector3(2.6, -7.6, -97.2), Vector3(0, -6.5, -100), Vector3(1.3, -7.9, -99.4), Vector3(0, -6.5, -100), 50.0, 44.0, "arena"],
	# 6 — companion flash (3s): Nous truth-breach violet ring on the Warden
	[3.0, Vector3(1.8, -7.4, -98.2), Vector3(0, -6.4, -100), Vector3(1.2, -7.4, -98.8), Vector3(0, -6.4, -100), 48.0, 48.0, "arena"],
	# 7 — door ending (silence): quiet push toward the Hermes door
	[6.0, Vector3(2.2, -7.4, -99.0), Vector3(0, -5.6, -110.5), Vector3(1.3, -7.7, -104.0), Vector3(0, -5.6, -110.5), 54.0, 45.0, "silence"],
]

## Staging per shot: player walk [from, to], then nous / brooklyn anchors (they
## follow the player anyway; anchors just set the opening composition).
const STAGE := [
	{"player": [Vector3(0, 0, -10.5), Vector3(0, 0, -14.5)], "nous": Vector3(1.4, 0, -14), "brooklyn": Vector3(-1.6, 0, -14.5)},
	{"player": [Vector3(0, 0, -42), Vector3(0, 0, -44.5)], "nous": Vector3(1.2, 0, -43.2), "brooklyn": Vector3(-1.2, 0, -43.9)},
	{"player": [Vector3(0, -8, -82.2), Vector3(0, -8, -83.0)], "nous": Vector3(1.5, -8, -82.8), "brooklyn": Vector3(-1.6, -8, -83.2)},
	{"player": [Vector3(2.4, -8, -93.4), Vector3(2.4, -8, -93.4)], "nous": Vector3(0.5, -8, -92.4), "brooklyn": Vector3(-0.8, -8, -93.0)},
	{"player": [Vector3(-1.2, -8, -98.4), Vector3(-1.2, -8, -98.4)], "nous": Vector3(-3.2, -8, -97.6), "brooklyn": Vector3(-3.8, -8, -99.2)},
	{"player": [Vector3(0, -8, -97.4), Vector3(0, -8, -97.4)], "nous": Vector3(1.4, -8, -99.0), "brooklyn": Vector3(-1.5, -8, -99.3)},
	{"player": [Vector3(0, -8, -105.5), Vector3(0, -8, -107.2)], "nous": Vector3(1.8, -8, -106.8), "brooklyn": Vector3(-1.8, -8, -107.1)},
]

const FLOOR_Y := -8.0

var world: Node3D
var cam: Camera3D
var player: Player
var nous: Node3D
var brooklyn: Node3D
var warden: ChoirWarden
var custodian_a: Custodian
var custodian_b: Custodian
var encounter: EncounterController
var lighting: LightingDirector
var shot_index := 0
var shot_time := 0.0
var test_seconds := 0.0
var _elapsed := 0.0
var _movie_frames := 0
var _finished := false
var _advancing := false

## Hard safety: the movie is fixed at 30fps, so _process calls == movie frames.
## Cap at the planned cut (40s) + 15s margin; fires even if a frame errors.
const TOTAL_SECONDS := 40.0
const MAX_MOVIE_FRAMES := (TOTAL_SECONDS + 15.0) * 30.0

func _physics_process(_delta: float) -> void:
	if _finished:
		return
	if _movie_frames > int(MAX_MOVIE_FRAMES):
		_finish()

func _ready() -> void:
	var scene: PackedScene = load(CHAPTER2)
	world = scene.instantiate()
	add_child(world)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var env_node := world.get_node("WorldEnvironment") as WorldEnvironment
	if env_node and env_node.environment:
		env_node.environment.glow_hdr_threshold = 1.05
	for ui in ["HUD", "PauseMenu", "CombatTelemetry", "TitleCard"]:
		var node := world.get_node_or_null(ui)
		if node:
			node.visible = false
	player = world.get_node("Player")
	nous = world.get_node("Beats/Companions/Nous")
	brooklyn = world.get_node("Beats/Companions/Brooklyn")
	warden = world.get_node("Beats/Arena/Warden")
	custodian_a = world.get_node("Beats/Arena/CustodianA")
	custodian_b = world.get_node("Beats/Arena/CustodianB")
	encounter = world.get_node("Beats/Arena/Encounter")
	lighting = world.get_node("LightingDirector")
	# Stand the threshold dressing down so the trailer owns its staging.
	var guard := world.get_node_or_null("Beats/FirstContactCustodian")
	if guard:
		guard.visible = false
	var dummy := world.get_node_or_null("Beats/DummyThreshold")
	if dummy:
		dummy.visible = false
	# Arena combatants are props for the staged beats — no wandering aggro.
	custodian_a.aggro_range = 0.0
	custodian_b.aggro_range = 0.0
	encounter.auto_trigger = false
	cam = Camera3D.new()
	cam.name = "TrailerCam"
	world.add_child(cam)
	cam.current = true
	cam.fov = 60.0
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var args := OS.get_cmdline_user_args()
	var start_shot := 0
	for i in args.size():
		if args[i] == "--test" and i + 1 < args.size():
			test_seconds = float(args[i + 1])
		if args[i] == "--start" and i + 1 < args.size():
			start_shot = clampi(int(args[i + 1]), 0, SHOTS.size() - 1)
	await get_tree().process_frame
	await get_tree().process_frame
	_setup_shot(start_shot)

func _setup_shot(i: int) -> void:
	shot_index = i
	shot_time = 0.0
	var s: Array = SHOTS[i]
	lighting.apply_rig(s[7])
	var stage: Dictionary = STAGE[i]
	player.global_position = (stage["player"] as Array)[0]
	nous.global_position = stage["nous"]
	brooklyn.global_position = stage["brooklyn"]
	match i:
		3:
			custodian_a.global_position = Vector3(3.2, FLOOR_Y, -88.5)
			custodian_b.global_position = Vector3(-3.2, FLOOR_Y, -89.5)
		4:
			custodian_a.global_position = Vector3(4, FLOOR_Y, -95)
			custodian_b.global_position = Vector3(-4, FLOOR_Y, -105)
			_combat_shot4()
		5:
			custodian_a.global_position = Vector3(4, FLOOR_Y, -95)
			custodian_b.global_position = Vector3(-4, FLOOR_Y, -105)
			_combat_shot5()
		6:
			_combat_shot6()

func _process(delta: float) -> void:
	_elapsed += delta
	shot_time += delta
	_movie_frames += 1
	# Advance/quit FIRST — an error later in this frame must never stall the cut.
	var s: Array = SHOTS[shot_index]
	var dur: float = s[0]
	if shot_time >= dur and not _advancing:
		if shot_index >= SHOTS.size() - 1:
			_finish()
			return
		_advancing = true
		_setup_shot(shot_index + 1)
		_advancing = false
	var ease := smoothstep(0.0, 1.0, clampf(shot_time / dur, 0.0, 1.0))
	var pos: Vector3 = (s[1] as Vector3).lerp(s[2] as Vector3, ease)
	var look: Vector3 = (s[3] as Vector3).lerp(s[4] as Vector3, ease)
	pos.x += sin(shot_time * 1.3) * 0.04
	pos.y += sin(shot_time * 0.9 + 1.7) * 0.03
	cam.global_position = pos
	if pos.distance_to(look) > 0.5:
		cam.look_at(look, Vector3.UP)
	cam.fov = lerpf(s[5], s[6], ease)
	cam.current = true
	# Squad walk on the street / threshold / door shots; combat directors own the
	# player during the arena beats.
	var stage: Dictionary = STAGE[shot_index]
	var walk: Array = stage["player"]
	var walk_from: Vector3 = walk[0]
	var walk_to: Vector3 = walk[1]
	if walk_from != walk_to:
		player.global_position = walk_from.lerp(walk_to, ease)
		player.set_visual_facing(walk_to - walk_from)
	if test_seconds > 0.0 and _elapsed >= test_seconds:
		_finish()
		return
	if _finished:
		return

## --- Shot 4: arena combat two-shot (player vs CustodianA) --------------------

func _combat_shot4() -> void:
	await _seconds(0.4)
	await _lock(custodian_a)
	await _seconds(0.3)
	await _attack_chain(custodian_a, false, 3)
	await _seconds(0.2)
	await _dodge(&"move_left")
	await _seconds(0.3)
	await _attack_chain(custodian_a, true, 2)

## --- Shot 5: warden boss beat (sweep, circle, heavy stagger) -----------------

func _combat_shot5() -> void:
	await _seconds(0.3)
	if not custodian_a.health.is_dead():
		custodian_a.health.take_damage(999.0)
	if not custodian_b.health.is_dead():
		custodian_b.health.take_damage(999.0)
	await _seconds(0.2)
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

## --- Shot 6: companion ability flash ------------------------------------------

func _combat_shot6() -> void:
	await _seconds(0.35)
	if not player.companions.try_command(player):
		warden.truth_reveal(5.0)

## --- Choreography helpers (drive existing systems only) -----------------------

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

func _move_over(pos: Vector3, duration: float) -> void:
	var start := player.global_position
	var frames := maxi(1, int(round(duration * 60.0)))
	for i in frames:
		var t := float(i + 1) / float(frames)
		player.global_position = start.lerp(pos, smoothstep(0.0, 1.0, t))
		await get_tree().physics_frame
	player.global_position = pos

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
	push_warning("demo_capture: await timeout on %s" % cond)
	return false

func _finish() -> void:
	if _finished:
		return
	_finished = true
	print("DEMO_CAPTURE_DONE %d shots (%.1fs)" % [SHOTS.size(), _elapsed])
	get_tree().quit(0)
