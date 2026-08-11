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
const COPPER_DEAD := preload("res://assets/blockout/materials/copper_dead.tres")
const STREET_GROUND := preload("res://assets/blockout/materials/street_ground.tres")

# --- Environment lived-in layer (assets/environment/). Reuses the blockout
# language (same ink shader) so the enrichment sits naturally on the prototype.
const LANE_MARK := preload("res://assets/environment/materials/lane_mark.tres")
const MANHOLE := preload("res://assets/environment/materials/manhole.tres")
const WINDOW_INTERIOR := preload("res://assets/environment/materials/window_interior.tres")
const DAMP := preload("res://assets/environment/materials/damp.tres")
const HERMES_DOOR := preload("res://assets/environment/materials/hermes_door.tres")
const WARDEN_RING := preload("res://assets/environment/materials/warden_ring.tres")
const FOG_PUFF := preload("res://assets/environment/materials/fog_puff.tres")
const CHEVRON := preload("res://assets/environment/materials/chevron.tres")
const ORGAN_PIPE := preload("res://assets/environment/materials/organ_pipe.tres")

const WORLD_LAYER := 1

# Shared unit primitives (1x1x1 / radius 1) so every enrichment MultiMesh scales
# a single mesh resource per shape instead of allocating a fresh mesh per prop.
var _unit_box: BoxMesh
var _unit_cyl: CylinderMesh
var _unit_sphere: SphereMesh

var beats: Node3D

func _ready() -> void:
	beats = Node3D.new()
	beats.name = "Beats"
	add_child(beats)
	_setup_unit_meshes()
	_build_doves_row()
	_build_weep_entrance()
	_build_weep_descent()
	_build_collapsed_conduit()
	_build_choir_threshold()
	_build_choir_arena()

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
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
	sphere_mesh.radial_segments = 14
	sphere_mesh.rings = 9
	mesh.mesh = sphere_mesh
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
	_add_box(beat, "StreetGround", Vector3(16.0, 1.0, 50.0), Vector3(0.0, -0.5, -21.0), STREET_GROUND)
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
	# Window lumens on the tenements — cold emerald, few, far apart: the street
	# was full of household lights, and now almost none are left. These also
	# break the dark mass so the composition reads at a glance (readability rule).
	for side in [-1.0, 1.0]:
		for z in [-9.0, -20.0, -31.0, -42.0]:
			_add_visual_box(beat, "WindowLumen_%d_%d" % [int(side), int(abs(z))],
				Vector3(0.5, 0.7, 0.04), Vector3(side * 7.6, 3.5, z), EMERALD)
	# Copper curbs along the street
	_add_box(beat, "CurbLeft", Vector3(0.5, 0.25, 46.0), Vector3(-5.0, 0.05, -20.0), COPPER)
	_add_box(beat, "CurbRight", Vector3(0.5, 0.25, 46.0), Vector3(5.0, 0.05, -20.0), COPPER)

	# Juno's house doorstep (left block at z=-16) — the open door set-piece
	_add_box(beat, "JunoStoop", Vector3(1.6, 0.3, 0.9), Vector3(-6.9, 0.15, -16.0), STONE)
	_add_visual_box(beat, "JunoDoorOpen", Vector3(1.4, 2.6, 0.15), Vector3(-6.9, 1.3, -16.5), COPPER,
		Vector3(0.0, -0.6, 0.0))
	_add_visual_cylinder(beat, "KettleBoiledDry", 0.16, 0.24, Vector3(-6.6, 0.22, -16.6), COPPER_DEAD)
	_add_plaque(beat, "PlaqueJunoHouse", "JUNO'S HOUSE", Vector3(-6.9, 3.6, -16.0), Color(0.66, 0.4, 0.22))

	# Storytelling props — a street that gave its voices away:
	# the care terminal (Lark's box, warm emerald screen), a chair pushed back
	# and never returned to, a fallen household frame, and a market stall kept
	# open for a child's winter. (PROTOTYPE: primitives stand in for set art.)
	_add_visual_box(beat, "CareTerminal", Vector3(0.5, 0.7, 0.3), Vector3(-6.2, 0.6, -15.8), OBSIDIAN)
	_add_visual_box(beat, "TerminalScreen", Vector3(0.42, 0.3, 0.05), Vector3(-6.2, 0.78, -15.95), EMERALD)
	_add_visual_box(beat, "ChairPushedBack", Vector3(0.5, 0.95, 0.5), Vector3(-7.8, 0.48, -14.6), STONE,
		Vector3(0.0, 0.35, 0.0))
	_add_visual_box(beat, "ChairBack", Vector3(0.08, 0.7, 0.4), Vector3(-7.8, 0.85, -14.3), STONE)
	_add_visual_box(beat, "HouseholdFrame", Vector3(0.5, 0.4, 0.04), Vector3(-6.2, 1.7, -16.45), COPPER_DEAD)
	_add_visual_box(beat, "StallCounter", Vector3(3.2, 1.1, 0.6), Vector3(5.6, 0.55, -10.0), STONE)
	_add_visual_box(beat, "StallAwning", Vector3(3.4, 0.12, 1.2), Vector3(5.6, 1.7, -10.0), COPPER_DEAD)
	_add_visual_cylinder(beat, "StallCrate_1", 0.28, 0.5, Vector3(4.9, 0.25, -10.3), COPPER_DEAD)
	_add_visual_cylinder(beat, "StallCrate_2", 0.28, 0.5, Vector3(6.3, 0.25, -9.7), STONE)

	# Dead lamppost with cold emerald lumen
	_add_cylinder(beat, "LampPost", 0.06, 2.4, Vector3(-3.0, 1.2, -2.0), OBSIDIAN)
	_add_visual_sphere(beat, "DeadLumen", 0.18, Vector3(-3.0, 2.6, -2.0), EMERALD)
	_add_plaque(beat, "PlaqueStreet", "DOVE'S ROW", Vector3(0.0, 0.2, -4.0), Color(0.0, 0.9, 0.55))
	_enrich_doves_row(beat)

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
	# Common Index mark worn into the lintel — Aster's seal, the world-history
	# beat canon to Ch2.3 (docs/WORLD_BIBLE §2.1, PAYOFF_LEDGER A8).
	_add_plaque(beat, "IndexMarkLintel", "COMMON INDEX — SEALED", Vector3(0.0, 6.0, -45.95), Color(0.66, 0.4, 0.22))
	_enrich_weep_entrance(beat)

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
	# Drowned archive shelves — the open century as a flooded library (canon
	# WORLD_BIBLE §2.1 Stratum 1): rows of sealed memory caskets on the walls.
	for i in 4:
		_add_visual_box(beat, "ArchiveShelfL_%d" % i, Vector3(0.14, 0.35, 0.6), Vector3(-2.2, -1.2 - i * 0.9, -50.5 - i * 0.4), COPPER_DEAD)
		_add_visual_box(beat, "ArchiveShelfR_%d" % i, Vector3(0.14, 0.35, 0.6), Vector3(2.2, -1.2 - i * 0.9, -50.5 - i * 0.4), COPPER_DEAD)
	# A single emerald lumen against the drowned dark — the only warm memory
	# the crypt still holds (canon color language: emerald on near-black).
	_add_visual_sphere(beat, "CryptRememberLumen", 0.16, Vector3(0.0, -3.2, -58.0), EMERALD)
	_enrich_weep_descent(beat)

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
	_enrich_collapsed_conduit(beat)

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
	# A captive-voice panel — a voice "able to sing, not able to mean it"
	# (canon 2.6 Tinuviel beat, PAYOFF_LEDGER E2): sealed resonators on the wall.
	for i in 3:
		_add_visual_cylinder(beat, "CaptiveVoice_%d" % i, 0.18, 0.7, Vector3(-4.6, -4.2 - i * 0.8, -82.0), COPPER)
		_add_visual_sphere(beat, "CaptiveLumen_%d" % i, 0.1, Vector3(-4.6, -4.2 - i * 0.8, -81.8), EMERALD)
	_enrich_choir_threshold(beat)

## --- Beat 6: Warden's choir-house (arena) -----------------------------------

func _build_choir_arena() -> void:
	var beat := _beat("BeatChoirArena")
	_add_box(beat, "ArenaFloor", Vector3(16.0, 1.0, 24.0), Vector3(0.0, -8.5, -101.0), OBSIDIAN)
	# Copper columns in two rows
	for row in [-5.0, 5.0]:
		for i in 5:
			_add_cylinder(beat, "Column_%d_%d" % [int(row), i], 0.5, 7.0,
				Vector3(row, -4.5, -92.0 - i * 4.0), COPPER)
	# Pipe organ wall along the back (copper gradient + faint emissive bands via
	# the environment organ_pipe material — the bands stay unshadowed).
	for i in 9:
		_add_cylinder(beat, "OrganPipe_%d" % i, 0.28 + i * 0.02, 4.5 + i * 0.25,
			Vector3(-4.0 + i * 1.0, -3.5, -109.5), ORGAN_PIPE, Vector3(0.0, 0.0, 1.5708))
	# Hanging resonator bells
	for i in 5:
		_add_visual_sphere(beat, "ChoirBell_%d" % i, 0.8, Vector3(-6.0 + i * 3.0, -3.2, -96.0 - i * 2.0),
			COPPER_GLOW)
	# Hermes beacon: emerald door of light at the far end
	_add_visual_box(beat, "HermesDoor", Vector3(4.0, 4.0, 0.3), Vector3(0.0, -6.0, -110.5), EMERALD)
	_add_plaque(beat, "PlaqueArena", "THE DOOR IS WAITING", Vector3(0.0, -2.8, -110.0),
		Color(0.0, 0.95, 0.55))
	# Captive-choir echo wall — the surrendered voices of Dove's Row are bound
	# into these pipes (canon 2.9 causality; the Warden weaponizes them). Small
	# emerald resonators read as "captive Hermes-color" rather than decor.
	for i in 7:
		_add_visual_cylinder(beat, "ChoirEcho_%d" % i, 0.2, 3.0, Vector3(-6.0 + i * 2.0, -6.4, -102.0), COPPER)
		_add_visual_sphere(beat, "ChoirEchoLumen_%d" % i, 0.12, Vector3(-6.0 + i * 2.0, -6.4, -101.7), EMERALD)
	_enrich_choir_arena(beat)

## --- Environment lived-in layer ---------------------------------------------
##
## Visual-only enrichment: collision_layer 0, no collision shapes, no shadow
## casting, shared unit meshes + MultiMeshInstance3D so hundreds of props stay a
## handful of draw calls. Everything here makes the blockout read as a place
## people built and abandoned — nothing here is gameplay.

func _setup_unit_meshes() -> void:
	_unit_box = BoxMesh.new()
	_unit_cyl = CylinderMesh.new()
	_unit_cyl.radial_segments = 10
	_unit_cyl.top_radius = 1.0
	_unit_cyl.bottom_radius = 1.0
	_unit_cyl.height = 1.0
	_unit_sphere = SphereMesh.new()
	_unit_sphere.radial_segments = 12
	_unit_sphere.rings = 8
	_unit_sphere.radius = 0.5
	_unit_sphere.height = 1.0

func _tform(pos: Vector3, size: Vector3, rot := Basis.IDENTITY) -> Transform3D:
	return Transform3D(rot.scaled(size), pos)

func _mm3(parent: Node3D, name: String, mesh: Mesh, material: Material,
		transforms: Array[Transform3D], max_dist := 0.0) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var inst := MultiMeshInstance3D.new()
	inst.name = name
	inst.multimesh = mm
	inst.material_override = material
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if max_dist > 0.0:
		inst.visibility_range_end = max_dist
	parent.add_child(inst)
	return inst

func _add_visual_unit_cyl(parent: Node3D, cyl_name: String, radius: float, height: float,
		position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = cyl_name
	mesh.position = position
	mesh.mesh = _unit_cyl
	mesh.scale = Vector3(radius, height, radius)
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return mesh

func _cyl_xform(a: Vector3, b: Vector3, radius: float) -> Transform3D:
	var seg := b - a
	var y := seg.normalized()
	var up := Vector3.UP
	if absf(y.dot(up)) > 0.98:
		up = Vector3.FORWARD
	var x := y.cross(up).normalized()
	var z := x.cross(y).normalized()
	var basis := Basis(x, y, z).scaled(Vector3(radius, seg.length(), radius))
	return Transform3D(basis, (a + b) * 0.5)

func _catenary_xforms(a: Vector3, b: Vector3, sag: float, segs: int, radius: float) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	var hvec := Vector3(b.x - a.x, 0.0, b.z - a.z)
	for i in segs:
		var t0 := float(i) / float(segs)
		var t1 := float(i + 1) / float(segs)
		var p0 := a + hvec * t0 + Vector3(0.0, -sag * (1.0 - pow(2.0 * t0 - 1.0, 2.0)), 0.0)
		var p1 := a + hvec * t1 + Vector3(0.0, -sag * (1.0 - pow(2.0 * t1 - 1.0, 2.0)), 0.0)
		out.append(_cyl_xform(p0, p1, radius))
	return out

func _add_fog(parent: Node3D, fog_name: String, center: Vector3, size: Vector3,
		amount: int, scale_min: float, scale_max: float) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = fog_name
	particles.position = center
	particles.amount = amount
	particles.lifetime = 9.0
	particles.one_shot = false
	particles.emitting = true
	particles.speed_scale = 0.35
	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc.emission_box_extents = size * 0.5
	proc.direction = Vector3(0.0, 1.0, 0.0)
	proc.initial_velocity_min = 0.04
	proc.initial_velocity_max = 0.15
	proc.gravity = Vector3(0.0, -0.02, 0.0)
	proc.scale_min = scale_min
	proc.scale_max = scale_max
	proc.color = Color(0.45, 0.52, 0.56, 0.35)
	particles.process_material = proc
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	particles.draw_pass_1 = quad
	particles.material_override = FOG_PUFF
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visibility_aabb = AABB(-size * 0.5, size)
	parent.add_child(particles)
	return particles

## --- Beat 1 enrichment: Dove's Row -----------------------------------------

func _enrich_doves_row(beat: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	# Cobble grid — the pavement reads as laid stone, not a slab.
	var cobble_xforms: Array[Transform3D] = []
	for gx in range(-6, 7):
		for gz in range(-4, -42, -2):
			var pos := Vector3(float(gx) + rng.randf_range(-0.15, 0.15), 0.02,
				float(gz) + rng.randf_range(-0.3, 0.3))
			cobble_xforms.append(_tform(pos, Vector3(0.62, 0.05, 0.85),
				Basis.from_euler(Vector3(0.0, rng.randf_range(-0.08, 0.08), 0.0))))
	_mm3(beat, "EnvCobbles", _unit_box, STREET_GROUND, cobble_xforms, 55.0)
	# Faded centre lane dashes over the cobbles.
	var lane_xforms: Array[Transform3D] = []
	for gz in range(-6, -42, -3):
		lane_xforms.append(_tform(Vector3(0.0, 0.05, float(gz)), Vector3(0.14, 0.012, 1.4)))
	_mm3(beat, "EnvLaneMarks", _unit_box, LANE_MARK, lane_xforms, 55.0)
	# Two manhole grates: flat iron discs + cross bars.
	var grate_positions := [Vector3(-2.6, 0.02, -13.0), Vector3(2.4, 0.02, -27.0)]
	for i in grate_positions.size():
		_add_visual_unit_cyl(beat, "EnvManhole_%d" % i, 0.6, 0.03, grate_positions[i], MANHOLE)
	var bar_xforms: Array[Transform3D] = []
	for p in grate_positions:
		for b in 5:
			var t := 0.24 * float(b - 2)
			bar_xforms.append(_tform(p + Vector3(0.0, 0.015, t), Vector3(0.05, 0.015, 0.05)))
			bar_xforms.append(_tform(p + Vector3(t, 0.015, 0.0), Vector3(0.05, 0.015, 0.05)))
	_mm3(beat, "EnvGrateBars", _unit_box, MANHOLE, bar_xforms, 50.0)
	# Facade panel seams — vertical + horizontal joints on the tenement faces.
	var seam_xforms: Array[Transform3D] = []
	for side in [-1.0, 1.0]:
		var fx: float = side * 6.05
		for zc in [-5.0, -16.0, -27.0, -38.0]:
			for rel in [-3.0, -0.5, 2.0]:
				seam_xforms.append(_tform(Vector3(fx, 3.0, zc + rel), Vector3(0.03, 6.0, 0.02)))
			for y in [2.2, 4.4]:
				seam_xforms.append(_tform(Vector3(fx, y, zc), Vector3(0.02, 0.03, 10.2)))
	_mm3(beat, "EnvFacadeSeams", _unit_box, OBSIDIAN, seam_xforms, 60.0)
	# Lit windows — warm emerald interior glow with copper frames. Only the near
	# blocks are lit: the street gave most of its lights away.
	var win_xforms: Array[Transform3D] = []
	var frame_xforms: Array[Transform3D] = []
	for side in [-1.0, 1.0]:
		for zc in [-6.5, -14.5]:
			for wy in [3.0, 4.6]:
				var wx: float = side * 6.02
				win_xforms.append(_tform(Vector3(wx, wy, zc), Vector3(0.9, 1.15, 0.06)))
				frame_xforms.append(_tform(Vector3(wx - 0.46, wy, zc), Vector3(0.06, 1.28, 0.03)))
				frame_xforms.append(_tform(Vector3(wx + 0.46, wy, zc), Vector3(0.06, 1.28, 0.03)))
				frame_xforms.append(_tform(Vector3(wx, wy - 0.61, zc), Vector3(1.0, 0.06, 0.03)))
				frame_xforms.append(_tform(Vector3(wx, wy + 0.61, zc), Vector3(1.0, 0.06, 0.03)))
	_mm3(beat, "EnvWindowGlow", _unit_box, WINDOW_INTERIOR, win_xforms, 60.0)
	_mm3(beat, "EnvWindowFrames", _unit_box, COPPER_DEAD, frame_xforms, 60.0)
	# Sagging street cables — dead utility copper between lampposts and facades.
	var cable_xforms: Array[Transform3D] = []
	cable_xforms.append_array(_catenary_xforms(Vector3(-6.0, 4.0, -6.0), Vector3(-3.0, 2.6, -3.0), 0.8, 10, 0.045))
	cable_xforms.append_array(_catenary_xforms(Vector3(6.0, 4.0, -10.0), Vector3(-6.0, 4.0, -11.0), 1.2, 14, 0.05))
	cable_xforms.append_array(_catenary_xforms(Vector3(6.0, 3.4, -25.0), Vector3(6.0, 3.4, -40.0), 0.9, 12, 0.04))
	_mm3(beat, "EnvStreetCables", _unit_cyl, COPPER_DEAD, cable_xforms, 70.0)
	# Two more dead lamps — casings that will never light again.
	_add_visual_unit_cyl(beat, "EnvDeadLamp1_Post", 0.05, 2.3, Vector3(2.8, 1.15, -14.0), OBSIDIAN)
	_add_visual_box(beat, "EnvDeadLamp1_Head", Vector3(0.35, 0.2, 0.35), Vector3(2.8, 2.25, -14.0),
		OBSIDIAN, Vector3(0.0, 0.0, 0.6))
	_add_visual_unit_cyl(beat, "EnvDeadLamp2_Post", 0.05, 2.3, Vector3(-2.2, 1.15, -30.0), OBSIDIAN)
	_add_visual_box(beat, "EnvDeadLamp2_Head", Vector3(0.35, 0.2, 0.35), Vector3(-2.2, 2.25, -30.0),
		OBSIDIAN, Vector3(0.0, 0.0, -0.6))
	# A little fallout around the stoop and the stall.
	var debris_xforms: Array[Transform3D] = []
	debris_xforms.append(_tform(Vector3(-7.3, 0.1, -15.0), Vector3(0.22, 0.18, 0.22),
		Basis.from_euler(Vector3(0.0, 0.4, 0.1))))
	debris_xforms.append(_tform(Vector3(-5.6, 0.06, -15.4), Vector3(0.3, 0.1, 0.18),
		Basis.from_euler(Vector3(0.2, -0.2, 0.0))))
	debris_xforms.append(_tform(Vector3(3.9, 0.05, -12.5), Vector3(0.4, 0.14, 0.24),
		Basis.from_euler(Vector3(0.0, 0.8, 0.15))))
	_mm3(beat, "EnvStreetDebris", _unit_box, STONE, debris_xforms, 45.0)
	# Low ground fog drifting down the empty street.
	_add_fog(beat, "EnvStreetFog", Vector3(0.0, 0.35, -20.0), Vector3(15.0, 1.2, 46.0), 70, 2.2, 5.0)

## --- Beat 2 enrichment: the Weep breach ------------------------------------

func _enrich_weep_entrance(beat: Node3D) -> void:
	# Copper breach braces — the service breach is held open with industrial
	# clamps bolted across the jagged opening.
	for side in [-1.0, 1.0]:
		var bx: float = side * 1.75
		_add_visual_box(beat, "EnvBreachBrace_%d_0" % int(side), Vector3(0.5, 0.7, 0.18),
			Vector3(bx, 2.1, -45.8), COPPER, Vector3(0.0, 0.0, 0.4 * side))
		_add_visual_box(beat, "EnvBreachBrace_%d_1" % int(side), Vector3(0.5, 0.7, 0.18),
			Vector3(bx, 4.9, -45.8), COPPER, Vector3(0.0, 0.0, -0.4 * side))
		_add_visual_box(beat, "EnvBreachBrace_%d_2" % int(side), Vector3(1.2, 0.25, 0.18),
			Vector3(bx * 0.5, 2.3, -45.8), COPPER_DEAD)
	_add_visual_box(beat, "EnvBreachHeader", Vector3(3.4, 0.3, 0.16), Vector3(0.0, 6.0, -45.8),
		COPPER_DEAD)
	# Drain grates on the street just short of the wall.
	var grate_xforms: Array[Transform3D] = []
	var bar_xforms: Array[Transform3D] = []
	for dx in [-1.2, 0.8]:
		for dz in [-44.2, -43.4]:
			grate_xforms.append(_tform(Vector3(dx, 0.02, dz), Vector3(0.55, 0.03, 0.8)))
			for b in 3:
				var off := (float(b) - 1.0) * 0.2
				bar_xforms.append(_tform(Vector3(dx, 0.035, dz + off), Vector3(0.5, 0.02, 0.04)))
	_mm3(beat, "EnvDrainGrates", _unit_box, MANHOLE, grate_xforms, 40.0)
	_mm3(beat, "EnvDrainBars", _unit_box, MANHOLE, bar_xforms, 40.0)

## --- Beat 3 enrichment: the Weep descent -----------------------------------

func _enrich_weep_descent(beat: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# Damp wall streaks — the crypt sweats down the service stairs.
	var streak_xforms: Array[Transform3D] = []
	for i in 18:
		var sx := 2.88 if i % 2 == 0 else -2.88
		var sz := -51.0 + float(i) * 0.9
		var sh := rng.randf_range(1.4, 3.4)
		var sy := rng.randf_range(-8.0, -3.2 + sh * 0.5)
		streak_xforms.append(_tform(Vector3(sx, sy, sz), Vector3(0.06, sh, 0.02)))
	_mm3(beat, "EnvDampStreaks", _unit_box, DAMP, streak_xforms, 60.0)
	# Lumen-moss clusters — the existing moss beads into living colonies.
	var moss_xforms: Array[Transform3D] = []
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 99
	for c in 8:
		var side := -1.0 if c % 2 == 0 else 1.0
		var base := Vector3(side * 2.4, -1.2 - (c / 2) * 1.1, -50.0 - (c / 2) * 2.4)
		for k in 4:
			var s := rng2.randf_range(0.14, 0.3)
			moss_xforms.append(_tform(base + Vector3(rng2.randf_range(-0.22, 0.22),
				rng2.randf_range(-0.18, 0.18), rng2.randf_range(-0.15, 0.15)), Vector3(s, s, s)))
	_mm3(beat, "EnvMossClusters", _unit_sphere, EMERALD, moss_xforms, 60.0)
	# Emerald glints on the flooded crypt water — the lumens reflected in it.
	var glint_xforms: Array[Transform3D] = []
	for i in 3:
		glint_xforms.append(_tform(Vector3(-1.6 + i * 1.6, -8.48, -55.0 + i * 0.8),
			Vector3(1.2, 0.012, 0.25)))
	_mm3(beat, "EnvWaterGlints", _unit_box, EMERALD, glint_xforms, 50.0)
	# Tiny emerald memory-casket slots in the drowned archive shelves.
	var slot_xforms: Array[Transform3D] = []
	for i in 4:
		for k in 3:
			var sz := -50.5 - i * 0.4
			slot_xforms.append(_tform(Vector3(-2.18, -1.2 - i * 0.9 - 0.12, sz + (k - 1) * 0.18),
				Vector3(0.02, 0.16, 0.12)))
			slot_xforms.append(_tform(Vector3(2.18, -1.2 - i * 0.9 - 0.12, sz + (k - 1) * 0.18),
				Vector3(0.02, 0.16, 0.12)))
	_mm3(beat, "EnvCasketSlots", _unit_box, EMERALD, slot_xforms, 50.0)
	# Drain grate at the base of the descent, where the water escapes.
	_add_visual_unit_cyl(beat, "EnvBaseDrain", 0.6, 0.03, Vector3(0.0, -7.62, -63.0), MANHOLE)

## --- Beat 4 enrichment: collapsed conduit ----------------------------------

func _enrich_collapsed_conduit(beat: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	# Cable bundles sagging beneath the shattered bridge.
	var bundle_xforms: Array[Transform3D] = []
	bundle_xforms.append_array(_catenary_xforms(Vector3(-1.4, -7.0, -66.0), Vector3(-1.4, -7.0, -70.0), 0.5, 8, 0.09))
	bundle_xforms.append_array(_catenary_xforms(Vector3(1.4, -7.0, -74.0), Vector3(1.4, -7.0, -79.5), 0.6, 9, 0.09))
	bundle_xforms.append_array(_catenary_xforms(Vector3(-1.4, -6.4, -67.0), Vector3(1.4, -6.4, -68.0), 0.4, 6, 0.07))
	_mm3(beat, "EnvCableBundles", _unit_cyl, COPPER_DEAD, bundle_xforms, 60.0)
	# Warning chevrons on the deck edges and trusses.
	var chev_xforms: Array[Transform3D] = []
	for z in [-66.0, -70.0, -74.0, -78.5]:
		chev_xforms.append(_tform(Vector3(-2.0, -7.55, z), Vector3(0.7, 0.3, 0.04),
			Basis.from_euler(Vector3(0.0, 0.0, 0.3))))
		chev_xforms.append(_tform(Vector3(2.0, -7.55, z), Vector3(0.7, 0.3, 0.04),
			Basis.from_euler(Vector3(0.0, 0.0, -0.3))))
	for z in [-65.0, -70.0, -75.0, -78.5]:
		chev_xforms.append(_tform(Vector3(0.0, -5.45, z), Vector3(0.5, 0.18, 0.05),
			Basis.from_euler(Vector3(0.0, 0.0, 0.4))))
	_mm3(beat, "EnvChevrons", _unit_box, CHEVRON, chev_xforms, 55.0)
	# Rubble scattered along the surviving deck (kept off the jump line).
	var debris_xforms: Array[Transform3D] = []
	for i in 10:
		var side := 1.0 if i % 2 == 0 else -1.0
		var z := -65.5 + float(i) * 1.4
		if absf(z + 72.6) < 1.6:
			z += 1.6
		debris_xforms.append(_tform(Vector3(side * rng.randf_range(0.3, 1.5), -7.55, z),
			Vector3(rng.randf_range(0.2, 0.5), rng.randf_range(0.1, 0.3), rng.randf_range(0.2, 0.5)),
			Basis.from_euler(Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3),
				rng.randf_range(-0.3, 0.3)))))
	_mm3(beat, "EnvConduitDebris", _unit_box, OBSIDIAN, debris_xforms, 50.0)

## --- Beat 5 enrichment: Choir threshold ------------------------------------

func _enrich_choir_threshold(beat: Node3D) -> void:
	# Riveted wall panels — the choir-house is held together with iron.
	var rivet_xforms: Array[Transform3D] = []
	for side in [-1.0, 1.0]:
		for z in range(-80, -91, -3):
			for i in 6:
				rivet_xforms.append(_tform(Vector3(side * 4.9, -5.0 + i * 0.9, float(z) + 0.2),
					Vector3(0.1, 0.08, 0.08)))
		for y in range(-7, -2):
			rivet_xforms.append(_tform(Vector3(side * 3.5, float(y) + 0.5, -80.55),
				Vector3(0.08, 0.08, 0.1)))
	_mm3(beat, "EnvWallRivets", _unit_box, COPPER_DEAD, rivet_xforms, 55.0)
	# Copper glow bands clamped around the resonator pipes.
	var band_xforms: Array[Transform3D] = []
	for side in [-1.0, 1.0]:
		for i in 4:
			var py := -5.0 + i
			for b in 4:
				var bz := -81.5 + b * 2.0
				band_xforms.append(_tform(Vector3(side * 4.4, py, bz), Vector3(0.32, 0.07, 0.32),
					Basis.from_euler(Vector3(1.5708, 0.0, 0.0))))
	_mm3(beat, "EnvPipeBands", _unit_cyl, COPPER_GLOW, band_xforms, 55.0)
	# Bell chains — the resonator bell hangs from the roof, and a dead echo bell
	# hangs unplayed on the far side.
	var chain_xforms: Array[Transform3D] = []
	for k in 6:
		chain_xforms.append(_tform(Vector3(-2.5, -2.5 - (k + 0.5) * 0.18, -86.0),
			Vector3(0.08, 0.05, 0.08)))
	for k in 5:
		chain_xforms.append(_tform(Vector3(2.5, -2.5 - (k + 0.5) * 0.18, -85.0),
			Vector3(0.07, 0.05, 0.07)))
	_mm3(beat, "EnvBellChains", _unit_cyl, COPPER_DEAD, chain_xforms, 40.0)
	_add_visual_sphere(beat, "EnvEchoBell", 0.35, Vector3(2.5, -4.0, -85.0), COPPER_DEAD)
	# Copper inlay on the floor: a ring, a dark disc, emerald memory dots, and a
	# runner line from the threshold door.
	var ring := TorusMesh.new()
	ring.inner_radius = 1.1
	ring.outer_radius = 1.35
	ring.rings = 8
	ring.ring_segments = 24
	var ring_mi := MeshInstance3D.new()
	ring_mi.name = "EnvInlayRing"
	ring_mi.position = Vector3(0.0, -7.94, -85.0)
	ring_mi.rotation = Vector3(1.5708, 0.0, 0.0)
	ring_mi.mesh = ring
	ring_mi.material_override = COPPER_GLOW
	ring_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beat.add_child(ring_mi)
	var disc := CylinderMesh.new()
	disc.top_radius = 1.05
	disc.bottom_radius = 1.05
	disc.height = 0.02
	disc.radial_segments = 24
	var disc_mi := MeshInstance3D.new()
	disc_mi.name = "EnvInlayDisc"
	disc_mi.position = Vector3(0.0, -7.96, -85.0)
	disc_mi.mesh = disc
	disc_mi.material_override = WARDEN_RING
	disc_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beat.add_child(disc_mi)
	var dot_xforms: Array[Transform3D] = []
	for k in 6:
		var ang := TAU * float(k) / 6.0
		dot_xforms.append(_tform(Vector3(cos(ang) * 1.23, -7.92, -85.0 + sin(ang) * 1.23),
			Vector3(0.08, 0.012, 0.08)))
	_mm3(beat, "EnvInlayDots", _unit_box, EMERALD, dot_xforms, 40.0)
	_add_visual_box(beat, "EnvInlayRunner", Vector3(0.14, 0.02, 4.6), Vector3(0.0, -7.94, -86.9),
		COPPER_DEAD)

## --- Beat 6 enrichment: Warden's choir-house (arena) ------------------------

func _enrich_choir_arena(beat: Node3D) -> void:
	# Warm mouths on the hanging choir bells.
	var rim_xforms: Array[Transform3D] = []
	for i in 5:
		var bp := Vector3(-6.0 + i * 3.0, -3.2, -96.0 - i * 2.0)
		rim_xforms.append(_tform(bp + Vector3(0.0, -0.75, 0.0), Vector3(0.82, 0.05, 0.82)))
	_mm3(beat, "EnvBellRims", _unit_cyl, COPPER, rim_xforms, 60.0)
	# Copper frame behind the Hermes door so the beacon reads as a doorway.
	_add_visual_box(beat, "EnvDoorFrame", Vector3(4.6, 4.6, 0.16), Vector3(0.0, -6.0, -110.66),
		COPPER_DEAD)
	# The Hermes door breathes: a subtle, looping emission pulse (visual only).
	var door := beat.get_node_or_null("HermesDoor") as MeshInstance3D
	if door:
		door.material_override = HERMES_DOOR
		var pulse := create_tween()
		pulse.set_loops()
		pulse.tween_property(HERMES_DOOR, "shader_parameter/emission_energy", 2.7, 2.6)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse.tween_property(HERMES_DOOR, "shader_parameter/emission_energy", 1.9, 2.6)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Floor inlay ring around the Warden's spot: glowing copper ring over a dark
	# emerald disc, with eight memory dots where the choir stands to bind voices.
	var ring := TorusMesh.new()
	ring.inner_radius = 1.35
	ring.outer_radius = 1.55
	ring.rings = 8
	ring.ring_segments = 32
	var ring_mi := MeshInstance3D.new()
	ring_mi.name = "EnvWardenRing"
	ring_mi.position = Vector3(0.0, -7.94, -100.0)
	ring_mi.rotation = Vector3(1.5708, 0.0, 0.0)
	ring_mi.mesh = ring
	ring_mi.material_override = COPPER_GLOW
	ring_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beat.add_child(ring_mi)
	var disc := CylinderMesh.new()
	disc.top_radius = 1.3
	disc.bottom_radius = 1.3
	disc.height = 0.02
	disc.radial_segments = 32
	var disc_mi := MeshInstance3D.new()
	disc_mi.name = "EnvWardenDisc"
	disc_mi.position = Vector3(0.0, -7.96, -100.0)
	disc_mi.mesh = disc
	disc_mi.material_override = WARDEN_RING
	disc_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beat.add_child(disc_mi)
	var dot_xforms: Array[Transform3D] = []
	for k in 8:
		var ang := TAU * float(k) / 8.0
		dot_xforms.append(_tform(Vector3(cos(ang) * 1.45, -7.92, -100.0 + sin(ang) * 1.45),
			Vector3(0.1, 0.012, 0.1)))
	_mm3(beat, "EnvWardenDots", _unit_box, EMERALD, dot_xforms, 60.0)
	# Choir-house pews flanking the columns — where the surrendered street sat.
	var pew_xforms: Array[Transform3D] = []
	for side in [-1.0, 1.0]:
		for z in [-94.0, -99.0, -104.0]:
			pew_xforms.append(_tform(Vector3(side * 7.2, -7.9, z), Vector3(1.6, 0.14, 3.0)))
			pew_xforms.append(_tform(Vector3(side * 7.2, -8.35, z - 1.3), Vector3(0.12, 1.0, 0.12)))
			pew_xforms.append(_tform(Vector3(side * 7.2, -8.35, z + 1.3), Vector3(0.12, 1.0, 0.12)))
	_mm3(beat, "EnvPews", _unit_box, OBSIDIAN, pew_xforms, 60.0)
	# Thin ground haze across the choir-house floor.
	_add_fog(beat, "EnvArenaFog", Vector3(0.0, -7.2, -101.0), Vector3(16.0, 1.0, 22.0), 45, 1.8, 4.0)
