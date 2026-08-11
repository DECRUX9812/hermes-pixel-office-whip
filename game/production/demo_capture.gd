extends Node
## Cinematic demo capture — HERMES: THE LAST OPEN DOOR, Chapter 2.
##
## Staged trailer-style sequence driven by the Movie Maker:
##   VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.json \
##   godot4 --path . res://production/demo_capture.tscn --write-movie /tmp/raw.avi \
##          --fixed-fps 30 --resolution 1920x1080 [-- --test <seconds>]
##
## Hides HUD/UI, stages the squad on the authored path (Dove's Row -> Weep ->
## Threshold -> Arena), and runs scripted camera moves with the lighting rigs.
## Coordinates are from blockout_chapter2.gd so cameras never clip geometry.
## Pure capture: never changes gameplay scenes or assets.

const CHAPTER2 := "res://scenes/world/chapter2_choir_below.tscn"
const FPS := 30.0

const SHOTS := [
	# [dur, from_pos, from_look, to_pos, to_look, fov_from, fov_to, rig]
	# 1 — Dove's Row: wide dolly down the empty street, squad ahead
	[7.5, Vector3(3.4, 2.0, -26), Vector3(0, 1, -13.5), Vector3(2.6, 1.9, -16.5), Vector3(0, 1, -13.5), 60.0, 52.0, "ice"],
	# 2 — Squad orbit: sweep across their front, street-sign depth behind
	[6.0, Vector3(2.6, 1.9, -16.5), Vector3(0, 1, -13.5), Vector3(-2.6, 1.9, -15.5), Vector3(0, 1, -13.5), 52.0, 52.0, "ice"],
	# 3 — The Weep: squad silhouetted against the breach's emerald glow
	[6.0, Vector3(3.0, 1.7, -38.5), Vector3(0, 1, -44), Vector3(2.0, 1.6, -40.5), Vector3(0, 1, -44), 55.0, 55.0, "weep"],
	# 4 — Choir threshold: low angle, Custodian loom behind the squad
	[6.0, Vector3(2.9, -6.9, -87.8), Vector3(0, -6.8, -83.5), Vector3(1.4, -7.1, -85.2), Vector3(0, -6.8, -83.5), 58.0, 50.0, "threshold"],
	# 5 — Warden reveal: low push through the columns, organ wall behind
	[7.0, Vector3(2.6, -6.3, -90.5), Vector3(0, -6.2, -100), Vector3(1.3, -6.8, -93.2), Vector3(0, -6.2, -100), 50.0, 46.0, "arena"],
	# 6 — The door is waiting: pull toward the emerald door of light
	[6.0, Vector3(2.4, -6.9, -94.8), Vector3(0, -6, -110), Vector3(1.6, -6.8, -97.5), Vector3(0, -6, -110), 46.0, 46.0, "silence"],
]

## Squad staging per shot index: player, nous, brooklyn.
const STAGE := [
	[Vector3(0, 0, -12), Vector3(1.4, 0, -14), Vector3(-1.6, 0, -14.5)],
	[Vector3(0, 0, -12), Vector3(1.4, 0, -14), Vector3(-1.6, 0, -14.5)],
	[Vector3(0, 0, -43.5), Vector3(1.2, 0, -43.2), Vector3(-1.2, 0, -43.9)],
	[Vector3(0, -8, -82.5), Vector3(1.6, -8, -83.5), Vector3(-1.8, -8, -83.8)],
	[Vector3(0, -7.7, -94), Vector3(1.8, -8, -95.5), Vector3(-2, -8, -95.7)],
	[Vector3(0, -7.7, -95.5), Vector3(1.8, -8, -97), Vector3(-2, -8, -97.2)],
]

var world: Node3D
var cam: Camera3D
var player: Node3D
var nous: Node3D
var brooklyn: Node3D
var lighting: Node3D
var shot_index := 0
var shot_time := 0.0
var test_seconds := 0.0

func _ready() -> void:
	var scene: PackedScene = load(CHAPTER2)
	world = scene.instantiate()
	add_child(world)
	# Smooth the blockout edges; 4x MSAA is cheap and deterministic in movie mode.
	get_viewport().msaa_3d = Viewport.MSAA_4X
	# Tame orb blowout: only the brightest pixels bloom (0.9 default washes the
	# companion orbs out at trailer exposure).
	var env_node := world.get_node("WorldEnvironment") as WorldEnvironment
	if env_node and env_node.environment:
		env_node.environment.glow_hdr_threshold = 1.05
	world.get_node("HUD").visible = false
	world.get_node("PauseMenu").visible = false
	world.get_node("CombatTelemetry").visible = false
	world.get_node("TitleCard").visible = false
	player = world.get_node("Player")
	nous = world.get_node("Beats/Companions/Nous")
	brooklyn = world.get_node("Beats/Companions/Brooklyn")
	lighting = world.get_node("LightingDirector")
	cam = Camera3D.new()
	world.add_child(cam)
	cam.current = true
	cam.fov = 60.0
	# Mute the runtime synth — the trailer carries its own score/narration.
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--test" and i + 1 < args.size():
			test_seconds = float(args[i + 1])
	await get_tree().process_frame
	await get_tree().process_frame
	_setup_shot(0)

func _setup_shot(i: int) -> void:
	shot_index = i
	shot_time = 0.0
	var s: Array = SHOTS[i]
	lighting.apply_rig(s[7])
	var stage: Array = STAGE[i]
	player.global_position = stage[0]
	nous.global_position = stage[1]
	brooklyn.global_position = stage[2]
	if shot_index == 4:
		var cust := world.get_node_or_null("Beats/Arena/CustodianA")
		if cust:
			cust.global_position = Vector3(3.2, -8, -97.5)

func _process(delta: float) -> void:
	shot_time += delta
	var s: Array = SHOTS[shot_index]
	var dur: float = s[0]
	var ease := smoothstep(0.0, 1.0, clampf(shot_time / dur, 0.0, 1.0))
	var pos: Vector3 = (s[1] as Vector3).lerp(s[2] as Vector3, ease)
	var look: Vector3 = (s[3] as Vector3).lerp(s[4] as Vector3, ease)
	# Micro handheld drift — reads as life, not shake.
	pos.x += sin(shot_time * 1.3) * 0.04
	pos.y += sin(shot_time * 0.9 + 1.7) * 0.03
	cam.global_position = pos
	if pos.distance_to(look) > 0.5:
		cam.look_at(look, Vector3.UP)
	cam.fov = lerpf(s[5], s[6], ease)
	cam.current = true
	if test_seconds > 0.0 and shot_time + dur * shot_index >= test_seconds:
		get_tree().quit(0)
		return
	if shot_time >= dur:
		if shot_index >= SHOTS.size() - 1:
			print("DEMO_CAPTURE_DONE %d shots" % SHOTS.size())
			get_tree().quit(0)
			return
		_setup_shot(shot_index + 1)
