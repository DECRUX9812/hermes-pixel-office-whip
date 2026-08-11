class_name CombatVfx
extends Node3D
## Readable, cheap combat feedback for the prototype slice.
##
## Every effect is a short-lived procedural primitive (no textures, no particle
## systems — a handful of draw calls each, freed on completion) so combat reads
## clearly on the target GPU (Radeon Pro W6400 / 4 GB) without a VFX budget.
## This is the PROTOTYPE VFX layer: the language (emerald swing, copper sparks,
## violet truth rings) is the production language; a VFX artist replaces the
## primitives with authored effects.
##
## Hooks (EventBus):
##   - attack_started      -> staff swing arc at the attacker
##   - attack_landed       -> impact flash + sparks at the target
##   - player_dodged       -> brief emerald afterimage at the player
##   - enemy_state_changed -> telegraph ring under windups
##   - truth_revealed      -> violet ring over the revealed target
##   - combatant_defeated  -> dissolve flash
##
## All effects self-free; the node never leaks meshes.

const DURATION_SHORT := 0.22
const DURATION_TELEGRAPH := 0.8

const EMERALD := Color(0.0, 1.0, 0.6)
const COPPER := Color(1.0, 0.6, 0.25)
const VIOLET := Color(0.75, 0.45, 1.0)

func _ready() -> void:
	EventBus.attack_started.connect(_on_attack_started)
	EventBus.attack_landed.connect(_on_attack_landed)
	EventBus.player_dodged.connect(_on_dodged)
	EventBus.enemy_state_changed.connect(_on_enemy_state_changed)
	EventBus.truth_revealed.connect(_on_truth_revealed)
	EventBus.combatant_defeated.connect(_on_defeated)

## --- Event handlers -----------------------------------------------------------

func _on_attack_started(attacker: Node, _kind: String) -> void:
	if attacker is Node3D:
		_spawn_arc(attacker as Node3D)

func _on_attack_landed(_attacker: Node, target: Node, _damage: float, kind: String) -> void:
	if target is Node3D:
		_spawn_impact(target as Node3D, kind == "heavy")

func _on_dodged() -> void:
	var player := _find_player()
	if player:
		_spawn_afterimage(player)

func _on_enemy_state_changed(enemy: Node, state: String) -> void:
	if enemy is Node3D:
		match state:
			"WINDUP", "WINDUP_SWEEP":
				_spawn_telegraph(enemy as Node3D)
			"REQUIEM_CHANNEL":
				_spawn_requiem_ring(enemy as Node3D)

func _on_truth_revealed(target: Node, _duration: float) -> void:
	if target is Node3D:
		_spawn_truth_ring(target as Node3D)

func _on_defeated(combatant: Node) -> void:
	if combatant is Node3D:
		_spawn_defeat_flash(combatant as Node3D)

## --- Effects ------------------------------------------------------------------

func _spawn_arc(attacker: Node3D) -> void:
	# A curved emerald slash in front of the attacker, billboarded loosely.
	var effect := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.1
	torus.rings = 24
	torus.ring_segments = 6
	effect.mesh = torus
	effect.material_override = _glow_material(EMERALD, 2.0)
	effect.position = Vector3(0.0, 0.8, -0.9)
	effect.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	add_child(effect)
	_fade_effect(effect, DURATION_SHORT, Vector3.ONE, Vector3.ONE * 1.15)

func _spawn_impact(target: Node3D, heavy: bool) -> void:
	var color := COPPER if heavy else EMERALD
	var scale_max := 1.5 if heavy else 1.0
	# Flash sphere
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.28
	sphere.height = 0.56
	sphere.radial_segments = 12
	sphere.rings = 6
	flash.mesh = sphere
	flash.material_override = _glow_material(color, 3.0)
	flash.position = target.global_position + Vector3(0.0, 1.0, 0.0)
	add_child(flash)
	_fade_effect(flash, 0.16, Vector3.ONE * 0.4, Vector3.ONE * scale_max)
	# Ring
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.5
	torus.outer_radius = 0.62
	torus.rings = 20
	torus.ring_segments = 5
	ring.mesh = torus
	ring.material_override = _glow_material(color, 2.4)
	ring.position = target.global_position + Vector3(0.0, 0.15, 0.0)
	add_child(ring)
	_fade_effect(ring, 0.3, Vector3.ONE * 0.5, Vector3.ONE * 1.4)

func _spawn_afterimage(player: Node3D) -> void:
	var effect := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.5
	effect.mesh = capsule
	var mat := _glow_material(EMERALD, 1.2)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	effect.material_override = mat
	effect.position = player.global_position + Vector3(0.0, 1.0, 0.0)
	add_child(effect)
	_fade_effect(effect, 0.3, Vector3.ONE, Vector3.ONE * 1.1)

func _spawn_telegraph(enemy: Node3D) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.3
	torus.outer_radius = 1.45
	torus.rings = 28
	torus.ring_segments = 6
	ring.mesh = torus
	ring.material_override = _glow_material(COPPER, 1.8)
	ring.position = enemy.global_position + Vector3(0.0, 0.1, 0.0)
	add_child(ring)
	_fade_effect(ring, DURATION_TELEGRAPH, Vector3.ONE * 0.8, Vector3.ONE * 1.3)

func _spawn_requiem_ring(enemy: Node3D) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 2.6
	torus.outer_radius = 2.8
	torus.rings = 32
	torus.ring_segments = 6
	ring.mesh = torus
	ring.material_override = _glow_material(EMERALD, 2.2)
	ring.position = enemy.global_position + Vector3(0.0, 0.15, 0.0)
	add_child(ring)
	_fade_effect(ring, 0.5, Vector3.ONE * 0.6, Vector3.ONE * 1.25)

func _spawn_truth_ring(target: Node3D) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.05
	torus.rings = 24
	torus.ring_segments = 5
	ring.mesh = torus
	ring.material_override = _glow_material(VIOLET, 2.0)
	ring.position = target.global_position + Vector3(0.0, 0.12, 0.0)
	add_child(ring)
	_fade_effect(ring, 0.4, Vector3.ONE, Vector3.ONE * 1.2)

func _spawn_defeat_flash(combatant: Node3D) -> void:
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.6
	sphere.height = 1.2
	sphere.radial_segments = 14
	sphere.rings = 7
	flash.mesh = sphere
	flash.material_override = _glow_material(EMERALD, 2.5)
	flash.position = combatant.global_position + Vector3(0.0, 1.2, 0.0)
	add_child(flash)
	_fade_effect(flash, 0.4, Vector3.ONE, Vector3.ONE * 1.6)

## --- Helpers ------------------------------------------------------------------

func _glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func _fade_effect(mesh: MeshInstance3D, duration: float, from: Vector3, to: Vector3) -> void:
	var mat := mesh.material_override as StandardMaterial3D
	mesh.scale = from
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(mesh, "scale", to, duration)
	tween.tween_property(mat, "albedo_color:a", 0.0, duration)
	tween.set_parallel(false)
	tween.tween_callback(mesh.queue_free)

func _find_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Node3D
