extends Node
## Character art pass — adds stylized identity to the blockout characters.
## Run: godot4 --headless --path game res://production/character_pass.tscn
## Loads each character scene, adds primitive meshes/materials under VisualRoot,
## packs and saves in place. Gameplay nodes/collisions are untouched.

const MATERIALS := {
	"black": "res://assets/characters/materials/char_black.tres",
	"obsidian": "res://assets/characters/materials/char_obsidian.tres",
	"copper": "res://assets/characters/materials/char_copper.tres",
	"emerald": "res://assets/characters/materials/char_emerald.tres",
	"emerald_bright": "res://assets/characters/materials/char_emerald_bright.tres",
	"orange": "res://assets/characters/materials/char_orange.tres",
	"white": "res://assets/characters/materials/char_white.tres",
	"purple": "res://assets/characters/materials/char_purple.tres",
	"pink": "res://assets/characters/materials/char_pink.tres",
	"cyan": "res://assets/characters/materials/char_cyan.tres",
}

var mats := {}


func _ready() -> void:
	for key in MATERIALS:
		mats[key] = load(MATERIALS[key])
	var jobs := [
		["res://scenes/player/player.tscn", _player],
		["res://scenes/world/entities/custodian.tscn", _custodian],
		["res://scenes/world/entities/choir_warden.tscn", _warden],
		["res://scenes/world/entities/companions/nous.tscn", _nous],
		["res://scenes/world/entities/companions/brooklyn.tscn", _brooklyn],
	]
	var failures := 0
	for job in jobs:
		var scene: PackedScene = load(job[0])
		if scene == null:
			push_error("character_pass: cannot load %s" % job[0])
			failures += 1
			continue
		var root := scene.instantiate()
		var visual := root.get_node_or_null("VisualRoot")
		if visual == null:
			push_error("character_pass: no VisualRoot in %s" % job[0])
			failures += 1
			continue
		job[1].call(root, visual)
		var packed := PackedScene.new()
		var err := packed.pack(root)
		if err != OK:
			push_error("character_pass: pack failed %s (%d)" % [job[0], err])
			failures += 1
			continue
		var path := ProjectSettings.globalize_path(job[0])
		err = ResourceSaver.save(packed, path)
		if err != OK:
			push_error("character_pass: save failed %s (%d)" % [job[0], err])
			failures += 1
			continue
		print("CHARACTER_PASS_OK %s" % job[0])
	get_tree().quit(0 if failures == 0 else 1)


## --- builders ---------------------------------------------------------------

func _add_mesh(visual: Node3D, name: String, mesh: Mesh, mat: Material,
		pos: Vector3, rot := Vector3.ZERO, scale := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scale
	visual.add_child(mi)
	return mi


func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 20
	return m


func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


func _sphere(r: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	return m


func _torus(inner: float, outer: float) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	return m


## --- per-character art --------------------------------------------------------

func _player(root: Node3D, visual: Node3D) -> void:
	# Hooded silhouette: cone hood over the head, emerald visor slit
	_add_mesh(visual, "Hood", _cyl(0.02, 0.34, 0.5), mats["black"], Vector3(0, 2.12, 0))
	_add_mesh(visual, "VisorSlit", _box(Vector3(0.3, 0.06, 0.05)), mats["emerald_bright"], Vector3(0, 2.28, 0.3))
	# Shoulder pads + copper hem ring + chest core
	_add_mesh(visual, "ShoulderL", _box(Vector3(0.28, 0.16, 0.22)), mats["obsidian"], Vector3(-0.36, 1.32, 0), Vector3(0, 0, 0.15))
	_add_mesh(visual, "ShoulderR", _box(Vector3(0.28, 0.16, 0.22)), mats["obsidian"], Vector3(0.36, 1.32, 0), Vector3(0, 0, -0.15))
	_add_mesh(visual, "CoatHem", _torus(0.46, 0.54), mats["copper"], Vector3(0, 0.12, 0), Vector3(90, 0, 0))
	_add_mesh(visual, "ChestCore", _sphere(0.07), mats["emerald_bright"], Vector3(0, 1.32, 0.32))
	var band := visual.get_node_or_null("Headband") as MeshInstance3D
	if band:
		band.material_override = mats["copper"]


func _custodian(root: Node3D, visual: Node3D) -> void:
	# Helmet dome + copper crest, pauldrons, chest plate with copper inlay
	_add_mesh(visual, "Helmet", _cyl(0.16, 0.36, 0.55), mats["obsidian"], Vector3(0, 2.28, 0))
	_add_mesh(visual, "HelmetCrest", _box(Vector3(0.2, 0.12, 0.08)), mats["copper"], Vector3(0, 2.56, 0))
	_add_mesh(visual, "PauldronL", _box(Vector3(0.34, 0.14, 0.28)), mats["obsidian"], Vector3(-0.52, 1.28, 0), Vector3(0, 0, -0.18))
	_add_mesh(visual, "PauldronR", _box(Vector3(0.34, 0.14, 0.28)), mats["obsidian"], Vector3(0.52, 1.28, 0), Vector3(0, 0, 0.18))
	_add_mesh(visual, "ChestPlate", _box(Vector3(0.56, 0.46, 0.16)), mats["obsidian"], Vector3(0, 1.18, 0.3))
	_add_mesh(visual, "ChestInlay", _box(Vector3(0.4, 0.08, 0.05)), mats["copper"], Vector3(0, 1.18, 0.4))
	# Brighter visor (canon: street allegiance stays emerald)
	var visor := visual.get_node_or_null("Visor") as MeshInstance3D
	if visor:
		visor.material_override = mats["emerald"]


func _warden(root: Node3D, visual: Node3D) -> void:
	# Heavier crown, copper shoulder spikes, chest sigil, copper belt
	var crown := visual.get_node_or_null("CrownBand") as MeshInstance3D
	if crown:
		crown.scale = Vector3(1.35, 1.15, 1.35)
	_add_mesh(visual, "ShoulderSpikeL", _box(Vector3(0.1, 0.4, 0.1)), mats["copper"], Vector3(-0.62, 1.5, 0), Vector3(0, 0, 0.7))
	_add_mesh(visual, "ShoulderSpikeR", _box(Vector3(0.1, 0.4, 0.1)), mats["copper"], Vector3(0.62, 1.5, 0), Vector3(0, 0, -0.7))
	_add_mesh(visual, "ChestSigil", _box(Vector3(0.22, 0.22, 0.06)), mats["emerald"], Vector3(0, 1.75, 0.36))
	_add_mesh(visual, "Belt", _torus(0.6, 0.68), mats["copper"], Vector3(0, 1.35, 0), Vector3(90, 0, 0))


func _nous(root: Node3D, visual: Node3D) -> void:
	# Purple-black hair, cyan headphone rings, white jacket front
	_add_mesh(visual, "HairBun", _sphere(0.15), mats["purple"], Vector3(0, 2.14, -0.1))
	_add_mesh(visual, "HairSideL", _sphere(0.11), mats["purple"], Vector3(-0.14, 2.06, 0.12))
	_add_mesh(visual, "HairSideR", _sphere(0.11), mats["purple"], Vector3(0.14, 2.06, 0.12))
	_add_mesh(visual, "Jacket", _box(Vector3(0.62, 0.6, 0.2)), mats["white"], Vector3(0, 1.0, 0.3))
	_add_mesh(visual, "RingL", _torus(0.1, 0.14), mats["cyan"], Vector3(-0.3, 2.02, 0.02), Vector3(0, 0, 90))
	_add_mesh(visual, "RingR", _torus(0.1, 0.14), mats["cyan"], Vector3(0.3, 2.02, 0.02), Vector3(0, 0, -90))


func _brooklyn(root: Node3D, visual: Node3D) -> void:
	# Bell skirt, hair bun, capelet, warm lantern light
	_add_mesh(visual, "Skirt", _cyl(0.34, 0.5, 0.45), mats["pink"], Vector3(0, 0.42, 0))
	_add_mesh(visual, "HairBun", _sphere(0.13), mats["pink"], Vector3(0, 2.08, -0.08))
	_add_mesh(visual, "Capelet", _torus(0.36, 0.44), mats["pink"], Vector3(0, 1.18, 0), Vector3(90, 0, 0))
	var light := OmniLight3D.new()
	light.name = "LanternLight"
	light.light_color = Color(1, 0.75, 0.55)
	light.light_energy = 2.0
	light.omni_range = 4.0
	light.position = Vector3(0, 0.95, 0.35)
	visual.add_child(light)
