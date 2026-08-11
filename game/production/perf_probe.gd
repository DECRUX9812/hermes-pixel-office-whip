extends Node
## TEMP performance probe — deleted after use. Instantiates the chapter, frames
## the arena and Dove's Row, prints real draw-call + triangle counts.

func _ready() -> void:
	await get_tree().process_frame
	var scene: PackedScene = load("res://scenes/world/chapter2_choir_below.tscn")
	var chapter := scene.instantiate()
	add_child(chapter)
	await get_tree().process_frame
	await get_tree().process_frame
	var player: Node3D = chapter.get_node("Player")
	if player == null:
		print("PERF: no player")
		get_tree().quit(1)
		return
	await _stage(player, Vector3(0.0, -7.9, -97.0))
	_print_stats("ARENA")
	await _stage(player, Vector3(0.0, 0.0, 2.0))
	_print_stats("DOVES_ROW")
	get_tree().quit(0)

func _stage(player: Node3D, pos: Vector3) -> void:
	player.global_position = pos
	for i in 40:
		await get_tree().physics_frame

func _print_stats(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var vp := get_viewport()
	var calls := vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,
		Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	var prims := vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,
		Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
	print("PERF %s draw_calls=%d primitives=%d" % [tag, calls, prims])
