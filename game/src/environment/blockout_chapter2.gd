class_name BlockoutChapter2
extends Node3D
## Clearly-labelled procedural PROTOTYPE layer for Chapter 2: The Choir Below.
##
## This builds the entire static environment out of primitives so the slice is
## playable before any production art exists. Every beat lives in its own named
## Node3D container (Beats/<BeatName>) so a final Blender / authored layer can
## replace the blockout without touching gameplay systems. Replace the Blockout
## node in chapter2_choir_below.tscn, not the systems.

const STONE := preload("res://assets/blockout/materials/stone_black.tres")
const OBSIDIAN := preload("res://assets/blockout/materials/stone_obsidian.tres")
const COPPER := preload("res://assets/blockout/materials/copper.tres")
const EMERALD := preload("res://assets/blockout/materials/emerald_glow.tres")
const COPPER_GLOW := preload("res://assets/blockout/materials/copper_glow.tres")
const WATER := preload("res://assets/blockout/materials/water.tres")

const WORLD_LAYER := 1

var beats: Node3D

func _ready() -> void:
	beats = Node3D.new()
	beats.name = "Beats"
	add_child(beats)
	_build_doves_row()
	_build_weep_entrance()
	_build_weep_descent()
	_build_collapsed_conduit()
	_build_choir_threshold()
	_build_choir_arena()
	_add_prototype_guide()

## --- Helpers ----------------------------------------------------------------

func _beat(name: String) -> Node3D:
	var beat := Node3D.new()
	beat.name = name
	beats.add_child(beat)
	return beat

func _add_box(parent: Node3D, box_name: String, size: Vector3, position: Vector3,
		material: Material, rotation := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name + "_Body"
	body.position = position
	body.rotation = rotation
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	parent.add_child(body)

	var mesh := MeshInstance3D.new()
	mesh.name = box_name + "_Mesh"
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.material_override = material
	body.add_child(mesh)

	var collider := CollisionShape3D.new()
	collider.name = box_name + "_Shape"
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	collider.shape = box_shape
	body.add_child(collider)
	return body

func _add_cylinder(parent: Node3D, cyl_name: String, radius: float, height: float,
		position: Vector3, material: Material, rotation := Vector3.ZERO,
		collidable := false) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = cyl_name + "_Body"
	body.position = position
	body.rotation = rotation
	body.collision_layer = WORLD_LAYER if collidable else 0
	body.collision_mask = 0
	parent.add_child(body)

	var mesh := MeshInstance3D.new()
	mesh.name = cyl_name + "_Mesh"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 20
	mesh.mesh = cylinder
	mesh.material_override = material
	body.add_child(mesh)

	if collidable:
		var collider := CollisionShape3D.new()
		collider.name = cyl_name + "_Shape"
		var cylinder_shape := CylinderShape3D.new()
		cylinder_shape.radius = radius
		cylinder_shape.height = height
		collider.shape = cylinder_shape
		body.add_child(collider)
	return body

func _add_visual_box(parent: Node3D, box_name: String, size: Vector3, position: Vector3,
		material: Material, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = box_name
	mesh.position = position
	mesh.rotation = rotation
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh

func _add_visual_cylinder(parent: Node3D, cyl_name: String, radius: float, height: float,
		position: Vector3, material: Material, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = cyl_name
	mesh.position = position
	mesh.rotation = rotation
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 20
	mesh.mesh = cylinder
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh

func _add_visual_sphere(parent: Node3D, sphere_name: String, radius: float, position: Vector3,
		material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = sphere_name
	mesh.position = position
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	mesh.mesh = sphere_mesh
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh

func _add_plaque(parent: Node3D, plaque_name: String, text: String, position: Vector3,
		color := Color(0.0, 0.9, 0.55)) -> Label3D:
	var label := Label3D.new()
	label.name = plaque_name
	label.text = text
	label.position = position
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 48
	label.pixel_size = 0.01
	label.outline_size = 12
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	label.modulate = color
	parent.add_child(label)
	return label

## --- Beat 1: Dove's Row (cold open) ----------------------------------------

func _build_doves_row() -> void:
	var beat := _beat("BeatDovesRow")
	# Street ground, running +Z (toward the Weep) to -Z; reaches the Weep wall so
	# there is no void gap between the tenements and the breach.
	_add_box(beat, "StreetGround", Vector3(16.0, 1.0, 50.0), Vector3(0.0, -0.5, -21.0), STONE)
	# Left tenement blocks
	_add_box(beat, "LeftBlock_1", Vector3(5.0, 7.0, 10.0), Vector3(-8.5, 3.0, -5.0), STONE)
	_add_box(beat, "LeftBlock_2", Vector3(5.0, 7.0, 10.0), Vector3(-8.5, 3.0, -16.0), STONE)
	_add_box(beat, "LeftBlock_3", Vector3(5.0, 7.0, 10.0), Vector3(-8.5, 3.0, -27.0), STONE)
	_add_box(beat, "LeftBlock_4", Vector3(5.0, 7.0, 10.0), Vector3(-8.5, 3.0, -38.0), STONE)
	# Right tenement blocks
	_add_box(beat, "RightBlock_1", Vector3(5.0, 7.0, 10.0), Vector3(8.5, 3.0, -5.0), STONE)
	_add_box(beat, "RightBlock_2", Vector3(5.0, 7.0, 10.0), Vector3(8.5, 3.0, -16.0), STONE)
	_add_box(beat, "RightBlock_3", Vector3(5.0, 7.0, 10.0), Vector3(8.5, 3.0, -27.0), STONE)
	_add_box(beat, "RightBlock_4", Vector3(5.0, 7.0, 10.0), Vector3(8.5, 3.0, -38.0), STONE)
	# Copper curbs along the street
	_add_box(beat, "CurbLeft", Vector3(0.5, 0.25, 46.0), Vector3(-5.0, 0.05, -20.0), COPPER)
	_add_box(beat, "CurbRight", Vector3(0.5, 0.25, 46.0), Vector3(5.0, 0.05, -20.0), COPPER)

	# Juno's house doorstep (left block at z=-16) — the open door set-piece
	_add_box(beat, "JunoStoop", Vector3(1.6, 0.3, 0.9), Vector3(-6.9, 0.15, -16.0), STONE)
	_add_visual_box(beat, "JunoDoorOpen", Vector3(1.4, 2.6, 0.15), Vector3(-6.9, 1.3, -16.5), COPPER,
		Vector3(0.0, -0.6, 0.0))
	_add_visual_cylinder(beat, "KettleBoiledDry", 0.16, 0.24, Vector3(-6.6, 0.22, -16.6), COPPER)
	_add_plaque(beat, "PlaqueJunoHouse", "JUNO'S HOUSE", Vector3(-6.9, 3.6, -16.0), Color(0.66, 0.4, 0.22))

	# Dead lamppost with cold emerald lumen
	_add_cylinder(beat, "LampPost", 0.06, 2.4, Vector3(-3.0, 1.2, -2.0), OBSIDIAN)
	_add_visual_sphere(beat, "DeadLumen", 0.18, Vector3(-3.0, 2.6, -2.0), EMERALD)
	_add_plaque(beat, "PlaqueStreet", "DOVE'S ROW", Vector3(0.0, 0.2, -4.0), Color(0.0, 0.9, 0.55))

## --- Beat 2: The Weep entrance (service breach) -----------------------------

func _build_weep_entrance() -> void:
	var beat := _beat("BeatWeepEntrance")
	# Retaining wall with a doorway gap at centre (x -1.5..1.5) so the player can
	# actually walk through the breach into the Weep.
	_add_box(beat, "WallLeft", Vector3(6.0, 7.0, 1.0), Vector3(-4.5, 3.5, -46.0), STONE)
	_add_box(beat, "WallRight", Vector3(6.0, 7.0, 1.0), Vector3(4.5, 3.5, -46.0), STONE)
	_add_box(beat, "WallLintel", Vector3(4.5, 1.0, 1.0), Vector3(0.0, 6.5, -46.0), STONE)
	# Door jamb markers and the breach glow inside the opening
	_add_visual_box(beat, "JambLeft", Vector3(0.3, 4.5, 0.2), Vector3(-1.7, 2.25, -45.85), COPPER)
	_add_visual_box(beat, "JambRight", Vector3(0.3, 4.5, 0.2), Vector3(1.7, 2.25, -45.85), COPPER)
	_add_visual_box(beat, "BreachGlow", Vector3(3.0, 0.2, 0.1), Vector3(0.0, 0.6, -45.8), EMERALD)
	_add_plaque(beat, "PlaqueWeep", "THE WEEP", Vector3(0.0, 3.9, -45.2), Color(0.0, 0.9, 0.55))

## --- Beat 3: The Weep descent (service stairs) ------------------------------

func _build_weep_descent() -> void:
	var beat := _beat("BeatWeepDescent")
	# Upper gallery just inside the breach (z -46..-50). The truth-layer
	# fragments live here; the gate below blocks the steps until the
	# reconstruction completes.
	_add_box(beat, "GalleryFloor", Vector3(4.5, 0.5, 4.0), Vector3(0.0, -0.25, -48.0), STONE)
	_add_box(beat, "GalleryWallLeft", Vector3(0.5, 4.5, 4.0), Vector3(-2.5, 2.0, -48.0), STONE)
	_add_box(beat, "GalleryWallRight", Vector3(0.5, 4.5, 4.0), Vector3(2.5, 2.0, -48.0), STONE)
	# Real descending staircase: step 0 is flush with the gallery floor (top
	# y ≈ 0), each step drops 0.66 m down to ≈ -7.93 at the crypt floor. The
	# stairs run -Z from the gallery gate down to the conduit landing.
	var step_z := -50.5
	for i in 13:
		var depth := 1.0
		var height := 0.66
		var step_y := -height * (i + 0.5) - 0.01
		_add_box(beat, "Step_%02d" % i, Vector3(5.0, height, depth),
			Vector3(0.0, step_y, step_z + depth * 0.5), STONE)
		step_z -= depth
	# Landing at the base of the descent (top y ≈ -7.6, flush with the conduit)
	_add_box(beat, "DescentLanding", Vector3(5.0, 0.5, 3.0), Vector3(0.0, -7.85, -64.0), STONE)
	# Side walls flanking the stairs (the stairs fill the corridor between them)
	_add_box(beat, "DescentWallLeft", Vector3(0.5, 9.0, 16.0), Vector3(-3.0, -3.5, -55.5), STONE)
	_add_box(beat, "DescentWallRight", Vector3(0.5, 9.0, 16.0), Vector3(3.0, -3.5, -55.5), STONE)
	# Copper conduit pipes running down the walls
	_add_cylinder(beat, "PipeLeft", 0.18, 14.0, Vector3(-2.6, -3.5, -55.5), COPPER, Vector3(0.0, 0.0, 1.5708))
	_add_cylinder(beat, "PipeRight", 0.18, 14.0, Vector3(2.6, -3.5, -55.5), COPPER, Vector3(0.0, 0.0, 1.5708))
	# Flooded crypt water below the landing
	_add_visual_box(beat, "CryptWater", Vector3(8.0, 0.1, 8.0), Vector3(0.0, -8.6, -56.0), WATER)
	# Green lumen-moss accents on the walls
	for i in 5:
		_add_visual_sphere(beat, "LumenMoss_%d" % i, 0.12,
			Vector3(-2.3, -1.0 - i * 1.3, -49.5 - i * 1.5), EMERALD)
		_add_visual_sphere(beat, "LumenMossR_%d" % i, 0.12,
			Vector3(2.3, -1.0 - i * 1.3, -49.5 - i * 1.5), EMERALD)
	_add_plaque(beat, "PlaqueDescent", "SERVICE BREACH — SECTOR WEEP-9", Vector3(0.0, -2.5, -54.0),
		Color(0.66, 0.4, 0.22))
	# Reconstruction fragment markers in the gallery
	_add_plaque(beat, "PlaqueFragment_1", "SUBSTRATE FRAGMENT 1/3 — THE GATHERING", Vector3(-1.7, 2.6, -47.2),
		Color(0.0, 0.9, 0.55))
	_add_plaque(beat, "PlaqueFragment_2", "SUBSTRATE FRAGMENT 2/3 — A FAREWELL", Vector3(1.7, 2.6, -48.4),
		Color(0.0, 0.9, 0.55))
	_add_plaque(beat, "PlaqueFragment_3", "SUBSTRATE FRAGMENT 3/3 — JUNO'S GOODBYE", Vector3(0.0, 2.6, -49.2),
		Color(0.0, 0.9, 0.55))

## --- Beat 4: Collapsed inference conduit (traversal) ------------------------

func _build_collapsed_conduit() -> void:
	var beat := _beat("BeatCollapsedConduit")
	# Bridge, two segments with a broken gap at the centre
	_add_box(beat, "ConduitNear", Vector3(3.2, 0.4, 7.0), Vector3(0.0, -7.8, -67.5), OBSIDIAN)
	_add_box(beat, "ConduitFar", Vector3(3.2, 0.4, 6.4), Vector3(0.0, -7.8, -76.9), OBSIDIAN)
	# Stepping-stone debris in the gap
	_add_box(beat, "DebrisStep", Vector3(1.6, 0.3, 1.2), Vector3(0.0, -7.9, -72.6), OBSIDIAN)
	# Side guard rails (open, broken in places)
	_add_box(beat, "RailLeft", Vector3(0.2, 0.9, 13.0), Vector3(-2.1, -7.2, -72.0), COPPER)
	_add_box(beat, "RailRight", Vector3(0.2, 0.9, 13.0), Vector3(2.1, -7.2, -72.0), COPPER)
	# Copper support trusses above
	for z in [-65.0, -70.0, -75.0, -78.5]:
		_add_box(beat, "Truss_%d" % int(abs(z)), Vector3(4.5, 0.3, 0.5), Vector3(0.0, -5.6, z), COPPER)
	# Drowned open-century water far below
	_add_visual_box(beat, "ConduitWater", Vector3(14.0, 0.1, 10.0), Vector3(0.0, -12.0, -72.0), WATER)
	# Cracked conduit panels on the bridge surface (visual)
	_add_visual_box(beat, "CrackPanel_1", Vector3(0.9, 0.06, 1.6), Vector3(-0.8, -7.55, -66.0), COPPER)
	_add_visual_box(beat, "CrackPanel_2", Vector3(0.9, 0.06, 1.2), Vector3(0.8, -7.55, -75.5), COPPER,
		Vector3(0.0, 0.0, 0.2))
	_add_plaque(beat, "PlaqueConduit", "COLLAPSED INFERENCE CONDUIT — STRATA 1–2",
		Vector3(0.0, -5.2, -68.0), Color(0.0, 0.9, 0.55))

## --- Beat 5: Choir threshold (first contact) --------------------------------

func _build_choir_threshold() -> void:
	var beat := _beat("BeatChoirThreshold")
	_add_box(beat, "ThresholdFloor", Vector3(10.0, 1.0, 12.0), Vector3(0.0, -8.5, -85.0), OBSIDIAN)
	_add_box(beat, "ThresholdWallLeft", Vector3(1.0, 6.0, 12.0), Vector3(-5.2, -5.5, -85.0), STONE)
	_add_box(beat, "ThresholdWallRight", Vector3(1.0, 6.0, 12.0), Vector3(5.2, -5.5, -85.0), STONE)
	_add_box(beat, "ThresholdBack", Vector3(10.0, 6.0, 1.0), Vector3(0.0, -5.5, -80.4), STONE)
	# Resonator pipes on the side walls
	for i in 4:
		_add_cylinder(beat, "WallPipeL_%d" % i, 0.24, 8.0, Vector3(-4.4, -5.0 + i, -85.0), COPPER,
			Vector3(1.5708, 0.0, 0.0))
		_add_cylinder(beat, "WallPipeR_%d" % i, 0.24, 8.0, Vector3(4.4, -5.0 + i, -85.0), COPPER,
			Vector3(1.5708, 0.0, 0.0))
	# Hanging resonator bell
	_add_visual_sphere(beat, "ResonatorBell", 0.7, Vector3(-2.5, -3.6, -86.0), COPPER_GLOW)
	_add_plaque(beat, "PlaqueThreshold", "CHOIR THRESHOLD", Vector3(0.0, -3.8, -81.0),
		Color(0.66, 0.4, 0.22))

## --- Beat 6: Warden's choir-house (arena) -----------------------------------

func _build_choir_arena() -> void:
	var beat := _beat("BeatChoirArena")
	_add_box(beat, "ArenaFloor", Vector3(16.0, 1.0, 24.0), Vector3(0.0, -8.5, -101.0), OBSIDIAN)
	# Copper columns in two rows
	for row in [-5.0, 5.0]:
		for i in 5:
			_add_cylinder(beat, "Column_%d_%d" % [int(row), i], 0.5, 7.0,
				Vector3(row, -4.5, -92.0 - i * 4.0), COPPER)
	# Pipe organ wall along the back
	for i in 9:
		_add_cylinder(beat, "OrganPipe_%d" % i, 0.28 + i * 0.02, 4.5 + i * 0.25,
			Vector3(-4.0 + i * 1.0, -3.5, -109.5), COPPER, Vector3(0.0, 0.0, 1.5708))
	# Hanging resonator bells
	for i in 5:
		_add_visual_sphere(beat, "ChoirBell_%d" % i, 0.8, Vector3(-6.0 + i * 3.0, -3.2, -96.0 - i * 2.0),
			COPPER_GLOW)
	# Hermes beacon: emerald door of light at the far end
	_add_visual_box(beat, "HermesDoor", Vector3(4.0, 4.0, 0.3), Vector3(0.0, -6.0, -110.5), EMERALD)
	_add_plaque(beat, "PlaqueArena", "THE DOOR IS WAITING", Vector3(0.0, -2.8, -110.0),
		Color(0.0, 0.95, 0.55))

## --- Prototype guide --------------------------------------------------------

func _add_prototype_guide() -> void:
	var guide := _beat("BeatPrototypeGuide")
	var label := _add_plaque(guide, "GuideLabel",
		"PROTOTYPE BLOCKOUT — replaceable by authored art\nWASD move · Shift sprint · LMB light · RMB heavy · Q dodge · Tab lock-on\nE interact · F companion command · C switch companion · F3 telemetry",
		Vector3(0.0, 2.2, 4.0), Color(0.6, 0.65, 0.7))
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
