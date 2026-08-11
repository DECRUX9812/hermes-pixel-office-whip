extends Node
## Headless-to-frame capture harness for visual evidence.
##
## Usage (from game/, under a display — xvfb counts):
##   xvfb-run -a godot4 --path . res://production/capture_frames.tscn -- --scene <path> --out <path.png>
## The .gd entry must be loaded as a scene (capture_frames.tscn), not passed
## directly to the engine: a bare Node script as the main entry never starts.
##
## Loads the scene, lets it simulate `--frames` physics frames so the blockout,
## lighting rig, and HUD settle, then renders the current camera view to a PNG.
## This is the evidence gate for "visually verified" claims in reports:
## frames are written to disk where a supervisor (or CI) can inspect them.
##
## NOTE: this must run under a display (Xvfb counts); `--headless` cannot
## capture pixels. It never changes the scene.

const DEFAULT_SCENE := "res://scenes/world/chapter2_choir_below.tscn"
const DEFAULT_FRAMES := 60
const DEFAULT_OUT := "user://capture_frame.png"

func _ready() -> void:
	_run()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path := _arg(args, "--scene", DEFAULT_SCENE)
	var frames := int(_arg(args, "--frames", str(DEFAULT_FRAMES)))
	var out_path := _arg(args, "--out", DEFAULT_OUT)
	var pos_arg := _arg(args, "--pos", "")
	var yaw_arg := _arg(args, "--yaw", "")
	var rig_arg := _arg(args, "--rig", "")

	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("capture: cannot load %s" % scene_path)
		get_tree().quit(1)
		return
	var root := scene.instantiate()
	add_child(root)
	await get_tree().process_frame
	await get_tree().process_frame

	if pos_arg != "":
		_move_player(root, pos_arg, yaw_arg)
	if rig_arg != "":
		_apply_rig(root, rig_arg)

	for _i in frames:
		await get_tree().physics_frame

	var viewport := get_viewport()
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var err := image.save_png(ProjectSettings.globalize_path(out_path))
	if err == OK:
		print("CAPTURE_OK %s" % out_path)
		get_tree().quit(0)
	else:
		push_error("capture: save failed (%d) %s" % [err, out_path])
		get_tree().quit(1)

func _arg(args: PackedStringArray, key: String, default: String) -> String:
	for i in args.size():
		if args[i] == key and i + 1 < args.size():
			return args[i + 1]
	return default

## Teleports the player (and rotates the camera) so a later beat can be framed
## without playing the whole slice. --pos "x,y,z" and optional --yaw degrees.
func _move_player(root: Node, pos_arg: String, yaw_arg: String) -> void:
	var parts := pos_arg.split(",")
	if parts.size() != 3:
		return
	var player := root.get_node_or_null("Player") as Player
	if player == null:
		return
	player.global_position = Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
	if yaw_arg != "":
		var camera := player.get_node_or_null("CameraRig") as CameraRig
		if camera:
			camera.set_yaw(deg_to_rad(float(yaw_arg)))
	await get_tree().physics_frame

## Applies a named lighting rig immediately (ICE/weep/conduit/threshold/arena/
## silence) so a later beat can be captured without replaying the whole slice.
func _apply_rig(root: Node, rig: String) -> void:
	var director := root.get_node_or_null("LightingDirector") as LightingDirector
	if director:
		director.apply_rig(rig, true)
