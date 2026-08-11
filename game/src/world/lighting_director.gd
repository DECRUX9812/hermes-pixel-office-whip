class_name LightingDirector
extends Node3D
## Authored lighting / color script for Chapter 2.
##
## Implements the world's color script (docs/WORLD_BIBLE §9, docs/EMOTIONAL_PACING
## §1) as a sequence of authored "rigs". Each beat of the slice has a defined
## temperature (1 ICE .. 10 WHITE) mapped to light color, energy, fog, and a
## restrained grade. Transitions tween so beats flow into one another instead of
## cutting — matching the slice's "no frequent hard cuts" pillar.
##
## This is a BLOCKOUT/PROTOTYPE lighting layer: the mapping table and tween
## plumbing are the production skeleton; a lighting artist replaces the values
## with a lit, rendered scene. Nothing here hides composition under darkness:
## every rig keeps ambient + a key light above readability thresholds.

const TWEEN_SECONDS := 1.8

@export_group("Nodes")
@export var environment_node_path: NodePath = ^""
@export var sun_path: NodePath = ^""
@export var emerald_key_path: NodePath = ^""
@export var copper_key_path: NodePath = ^""

@export_group("ICE — Dove's Row cold open")
@export var ice_ambient := Color(0.42, 0.46, 0.5, 1.0)
@export var ice_ambient_energy := 1.6
@export var ice_fog := Color(0.16, 0.18, 0.19, 1.0)
@export var ice_fog_density := 0.005
@export var ice_sun_energy := 1.1
@export var ice_emerald_energy := 1.6
@export var ice_copper_energy := 1.2
@export var ice_glow := 0.22

@export_group("ALERT — Weep descent, lumen-moss")
@export var weep_ambient := Color(0.26, 0.42, 0.38, 1.0)
@export var weep_ambient_energy := 1.5
@export var weep_fog := Color(0.08, 0.16, 0.14, 1.0)
@export var weep_fog_density := 0.009
@export var weep_sun_energy := 0.8
@export var weep_emerald_energy := 2.0
@export var weep_copper_energy := 1.2
@export var weep_glow := 0.26

@export_group("DRIVE — conduit, green past to copper present")
@export var conduit_ambient := Color(0.34, 0.42, 0.38, 1.0)
@export var conduit_ambient_energy := 1.55
@export var conduit_fog := Color(0.12, 0.15, 0.14, 1.0)
@export var conduit_fog_density := 0.007
@export var conduit_sun_energy := 1.0
@export var conduit_emerald_energy := 1.8
@export var conduit_copper_energy := 1.4
@export var conduit_glow := 0.24

@export_group("TENSION — Choir threshold")
@export var threshold_ambient := Color(0.44, 0.36, 0.28, 1.0)
@export var threshold_ambient_energy := 1.6
@export var threshold_fog := Color(0.18, 0.14, 0.1, 1.0)
@export var threshold_fog_density := 0.006
@export var threshold_sun_energy := 1.0
@export var threshold_emerald_energy := 1.8
@export var threshold_copper_energy := 2.0
@export var threshold_glow := 0.28

@export_group("HEAT — Warden arena, copper singing green")
@export var arena_ambient := Color(0.48, 0.36, 0.24, 1.0)
@export var arena_ambient_energy := 1.7
@export var arena_fog := Color(0.2, 0.13, 0.08, 1.0)
@export var arena_fog_density := 0.005
@export var arena_sun_energy := 1.05
@export var arena_emerald_energy := 2.2
@export var arena_copper_energy := 2.4
@export var arena_glow := 0.32

@export_group("ICE-peak — after the Warden falls")
@export var silence_ambient := Color(0.4, 0.44, 0.46, 1.0)
@export var silence_ambient_energy := 1.45
@export var silence_fog := Color(0.13, 0.15, 0.16, 1.0)
@export var silence_fog_density := 0.007
@export var silence_sun_energy := 0.85
@export var silence_emerald_energy := 1.5
@export var silence_copper_energy := 0.9
@export var silence_glow := 0.18

var _environment: Environment = null
var _sun: DirectionalLight3D = null
var _emerald_key: OmniLight3D = null
var _copper_key: OmniLight3D = null
var _active: String = ""

func _ready() -> void:
	var env_node := get_node_or_null(environment_node_path) as WorldEnvironment
	if env_node:
		_environment = env_node.environment
	_sun = get_node_or_null(sun_path) as DirectionalLight3D
	_emerald_key = get_node_or_null(emerald_key_path) as OmniLight3D
	_copper_key = get_node_or_null(copper_key_path) as OmniLight3D
	EventBus.objective_updated.connect(_on_objective_updated)
	EventBus.encounter_started.connect(_on_encounter_started)
	EventBus.encounter_completed.connect(_on_encounter_completed)
	Settings.settings_changed.connect(_on_setting_changed)
	_apply_quality()
	apply_rig("ice")

## Applies the user's quality preset to the environment's post stack.
## "low" (Compatibility fallback / weak GPU) drops SSAO and lowers glow so the
## frame stays readable at 0.7x scale instead of smearing under effect load.
func _apply_quality() -> void:
	if _environment == null:
		return
	match Settings.quality_preset:
		"low":
			_environment.ssao_enabled = false
			_environment.glow_intensity = minf(_environment.glow_intensity, 0.2)
		"balanced":
			_environment.ssao_enabled = true
		"high":
			_environment.ssao_enabled = true

func _on_setting_changed(key: String, _value: Variant) -> void:
	if key == "quality_preset":
		_apply_quality()

## Public, test-friendly: applies (or tweens to) a named rig immediately.
func apply_rig(rig: String, immediate := false) -> void:
	if not _has_rig(rig):
		push_warning("LightingDirector: unknown rig %s" % rig)
		return
	if _active == rig and not immediate:
		return
	_active = rig
	var values := _rig_values(rig)
	if immediate:
		_set_direct(values)
	else:
		_tween_to(values)

func rig_state() -> String:
	return _active

## --- Wiring -------------------------------------------------------------------

func _on_objective_updated(objective: Objective) -> void:
	match objective.id:
		"investigate_doves_row", "learn_the_surrender", "reconstruct_the_surrender":
			apply_rig("ice")
		"descend_the_weep":
			apply_rig("weep")
		"cross_the_conduit":
			apply_rig("conduit")
		"clear_the_threshold", "the_voices_return":
			apply_rig("threshold")
		"open_the_choir_door", "talk_with_nous", "defeat_the_warden":
			apply_rig("arena")
		"hermes_speaks", "the_question":
			apply_rig("silence")

func _on_encounter_started(_encounter: Node) -> void:
	apply_rig("arena")

func _on_encounter_completed(_encounter: Node) -> void:
	apply_rig("silence")

## --- Rig table ----------------------------------------------------------------

func _has_rig(rig: String) -> bool:
	return _rig_values(rig) != {}

func _rig_values(rig: String) -> Dictionary:
	match rig:
		"ice":
			return _pack(ice_ambient, ice_ambient_energy, ice_fog, ice_fog_density, ice_sun_energy, ice_emerald_energy, ice_copper_energy, ice_glow)
		"weep":
			return _pack(weep_ambient, weep_ambient_energy, weep_fog, weep_fog_density, weep_sun_energy, weep_emerald_energy, weep_copper_energy, weep_glow)
		"conduit":
			return _pack(conduit_ambient, conduit_ambient_energy, conduit_fog, conduit_fog_density, conduit_sun_energy, conduit_emerald_energy, conduit_copper_energy, conduit_glow)
		"threshold":
			return _pack(threshold_ambient, threshold_ambient_energy, threshold_fog, threshold_fog_density, threshold_sun_energy, threshold_emerald_energy, threshold_copper_energy, threshold_glow)
		"arena":
			return _pack(arena_ambient, arena_ambient_energy, arena_fog, arena_fog_density, arena_sun_energy, arena_emerald_energy, arena_copper_energy, arena_glow)
		"silence":
			return _pack(silence_ambient, silence_ambient_energy, silence_fog, silence_fog_density, silence_sun_energy, silence_emerald_energy, silence_copper_energy, silence_glow)
	return {}

func _pack(ambient: Color, ambient_energy: float, fog: Color, fog_density: float, sun: float, emerald: float, copper: float, glow: float) -> Dictionary:
	return {
		"ambient": ambient, "ambient_energy": ambient_energy,
		"fog": fog, "fog_density": fog_density, "sun_energy": sun,
		"emerald_energy": emerald, "copper_energy": copper, "glow": glow,
	}

func _set_direct(values: Dictionary) -> void:
	if _environment:
		_environment.ambient_light_color = values["ambient"]
		_environment.ambient_light_energy = values["ambient_energy"]
		_environment.fog_light_color = values["fog"]
		_environment.fog_density = values["fog_density"]
		_environment.glow_intensity = values["glow"]
	if _sun:
		_sun.light_energy = values["sun_energy"]
	if _emerald_key:
		_emerald_key.light_energy = values["emerald_energy"]
	if _copper_key:
		_copper_key.light_energy = values["copper_energy"]

func _tween_to(values: Dictionary) -> void:
	if _environment:
		_create_tween(_environment, "ambient_light_color", values["ambient"])
		_create_tween(_environment, "ambient_light_energy", values["ambient_energy"])
		_create_tween(_environment, "fog_light_color", values["fog"])
		_create_tween(_environment, "fog_density", values["fog_density"])
		_create_tween(_environment, "glow_intensity", values["glow"])
	if _sun:
		_create_tween(_sun, "light_energy", values["sun_energy"])
	if _emerald_key:
		_create_tween(_emerald_key, "light_energy", values["emerald_energy"])
	if _copper_key:
		_create_tween(_copper_key, "light_energy", values["copper_energy"])

func _create_tween(target: Object, property: String, to: Variant) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, property, to, TWEEN_SECONDS)
