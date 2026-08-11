extends Node
## AudioDirector — owns the slice's audio buses and all event-to-sound hooks.
##
## Every cue is generated at runtime by the Synth class (original placeholder
## synthesis; no external audio files). The director is deliberately thin:
## it maps game events to cues, applies per-bus volume from Settings, and keeps
## the ambient bed (music layer) in step with the story temperature.
##
## Bus layout (created in _ready, idempotent):
##   Master -> [SFX, Music, Voice, Ambience]
## All one-shots play on SFX; ambient beds and story stingers play on Music;
## dialogue subtitle blips play on Voice; long loops play on Ambience.
##
## This is a replaceable placeholder layer: a production audio pass swaps the
## Synth streams for authored clips and keeps the same hook API.

const SFX_BUS := "SFX"
const MUSIC_BUS := "Music"
const VOICE_BUS := "Voice"
const AMBIENCE_BUS := "Ambience"

const SFX_MAX_POLYPHONY := 8

var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _cue_cache: Dictionary = {}

func _ready() -> void:
	_setup_buses()
	_prepare_cues()
	_prepare_pool()
	_hook_events()
	_apply_volumes()

## Releases audio resources on shutdown so Godot's exit leak report stays clean
## (the engine otherwise warns that still-playing pool streams were never freed).
func _exit_tree() -> void:
	for player in _sfx_pool:
		if player and is_instance_valid(player):
			player.stop()
			player.stream = null
	if _music_player and is_instance_valid(_music_player):
		_music_player.stop()
		_music_player.stream = null
	if _ambience_player and is_instance_valid(_ambience_player):
		_ambience_player.stop()
		_ambience_player.stream = null
	_cue_cache.clear()

## --- Bus setup ----------------------------------------------------------------

func _setup_buses() -> void:
	_ensure_bus(SFX_BUS)
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(VOICE_BUS)
	_ensure_bus(AMBIENCE_BUS)

func _ensure_bus(name: String) -> void:
	if AudioServer.get_bus_index(name) >= 0:
		return
	var master := AudioServer.get_bus_index("Master")
	AudioServer.add_bus()
	var new_index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(new_index, name)
	if master >= 0:
		AudioServer.set_bus_send(new_index, "Master")

func _apply_volumes() -> void:
	_set_bus_db(SFX_BUS, Settings.sfx_volume)
	_set_bus_db(MUSIC_BUS, Settings.music_volume)
	_set_bus_db(VOICE_BUS, Settings.voice_volume)
	_set_bus_db(AMBIENCE_BUS, Settings.ambience_volume)

func _set_bus_db(bus: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))

## --- Cue synthesis ------------------------------------------------------------

func _prepare_cues() -> void:
	_cue_cache = {
		"impact": Synth.impact(),
		"impact_heavy": Synth.impact_heavy(),
		"whoosh": Synth.whoosh(),
		"telegraph": Synth.telegraph(),
		"requiem": Synth.requiem(),
		"heart_bind": Synth.heart_bind(),
		"truth_breach": Synth.truth_breach(),
		"chime": Synth.emerald_chime(),
		"click": Synth.ui_click(),
		"blip": Synth.dialogue_blip(),
		"sting": Synth.title_sting(),
		"music_doves_row": Synth.room_tone(),
		"music_weep": Synth.weep_drone(),
		"music_choir": Synth.choir_hum(),
		"music_warden": Synth.warden_choir(),
	}

func _cue(id: String) -> AudioStreamWAV:
	return _cue_cache.get(id) as AudioStreamWAV

## --- Pool (one-shots) ---------------------------------------------------------

func _prepare_pool() -> void:
	for i in SFX_MAX_POLYPHONY:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		player.volume_db = -2.0
		player.finished.connect(_recycle.bind(player))
		add_child(player)
		_sfx_pool.append(player)

func _recycle(player: AudioStreamPlayer) -> void:
	player.stream = null
	player.stop()

func play_sfx(id: String, volume_db := 0.0) -> void:
	var stream := _cue(id)
	if stream == null:
		return
	var player := _next_free()
	player.volume_db = volume_db
	player.stream = stream
	player.play()

func _next_free() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return _sfx_pool[0]

## --- Music / ambience ---------------------------------------------------------

func play_music(id: String, volume_db := -3.0) -> void:
	var stream := _cue(id)
	if stream == null:
		return
	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.bus = MUSIC_BUS
		add_child(_music_player)
	_music_player.volume_db = volume_db
	_music_player.stream = stream
	_music_player.play()

func play_ambience(id: String, volume_db := -8.0) -> void:
	var stream := _cue(id)
	if stream == null:
		return
	if _ambience_player == null:
		_ambience_player = AudioStreamPlayer.new()
		_ambience_player.bus = AMBIENCE_BUS
		add_child(_ambience_player)
	_ambience_player.volume_db = volume_db
	_ambience_player.stream = stream
	_ambience_player.play()

func stop_ambience() -> void:
	if _ambience_player:
		_ambience_player.stop()

## --- Event hooks --------------------------------------------------------------

func _hook_events() -> void:
	EventBus.player_dodged.connect(_on_dodge)
	EventBus.attack_landed.connect(_on_attack_landed)
	EventBus.player_hit_received.connect(_on_player_hit)
	EventBus.enemy_state_changed.connect(_on_enemy_state_changed)
	EventBus.custodian_converted.connect(_on_converted)
	EventBus.truth_revealed.connect(_on_truth_revealed)
	EventBus.combatant_defeated.connect(_on_combatant_defeated)
	EventBus.interaction_performed.connect(_on_interaction)
	EventBus.subtitle_requested.connect(_on_subtitle)
	EventBus.subtitle_requested_timed.connect(_on_subtitle_timed)
	EventBus.objective_updated.connect(_on_objective)
	EventBus.encounter_started.connect(_on_encounter_started)
	EventBus.encounter_completed.connect(_on_encounter_completed)
	EventBus.title_card_requested.connect(_on_title_card)
	EventBus.game_paused.connect(_on_pause)
	EventBus.game_unpaused.connect(_on_unpause)
	Settings.settings_changed.connect(_on_setting_changed)

func _on_dodge() -> void:
	play_sfx("whoosh", -6.0)

func _on_attack_landed(_attacker: Node, _target: Node, _damage: float, kind: String) -> void:
	play_sfx("impact_heavy" if kind == "heavy" else "impact", 2.0)

func _on_player_hit(_target: Node, _damage: float, _source: Node) -> void:
	play_sfx("impact", 4.0)

func _on_enemy_state_changed(enemy: Node, state: String) -> void:
	if not (enemy is ChoirWarden):
		if state == "WINDUP":
			play_sfx("telegraph", -4.0)
		return
	match state:
		"WINDUP_SWEEP":
			play_sfx("telegraph", -2.0)
		"REQUIEM_CHANNEL":
			play_sfx("requiem", 2.0)

func _on_converted(_custodian: Node, _duration: float) -> void:
	play_sfx("heart_bind", 1.0)

func _on_truth_revealed(_target: Node, _duration: float) -> void:
	play_sfx("truth_breach", 0.0)

func _on_combatant_defeated(combatant: Node) -> void:
	play_sfx("impact_heavy", 1.0)
	if combatant is ChoirWarden:
		play_sfx("chime", -4.0)

func _on_interaction(_interactable: Interactable) -> void:
	play_sfx("click", -8.0)

func _on_subtitle(_speaker: String, _text: String) -> void:
	play_sfx("blip", -14.0)

func _on_subtitle_timed(_speaker: String, _text: String, _seconds: float) -> void:
	play_sfx("blip", -14.0)

## Ambient bed follows the story temperature (docs/EMOTIONAL_PACING.md):
##  - Dove's Row cold open  -> near-silent room tone (temperature 1-2)
##  - Weep descent          -> flooded-crypt drone (temperature 4-5)
##  - Choir / threshold     -> the Choir's hum (temperature 5-7)
##  - Warden arena          -> the hum drawn tight (temperature 7-8)
##  - Post-Warden           -> the silence IS the cue (2.10-2.11)
func _on_objective(objective: Objective) -> void:
	match objective.id:
		"investigate_doves_row", "learn_the_surrender", "reconstruct_the_surrender":
			play_music("music_doves_row", -3.0)
		"descend_the_weep":
			play_music("music_weep", -2.0)
		"cross_the_conduit", "clear_the_threshold", "the_voices_return":
			play_music("music_choir", -1.0)
		"open_the_choir_door", "talk_with_nous", "defeat_the_warden":
			play_music("music_warden", 0.0)

func _on_encounter_started(_encounter: Node) -> void:
	play_ambience("music_warden", -4.0)

func _on_encounter_completed(_encounter: Node) -> void:
	stop_ambience()
	play_sfx("chime", -6.0)

func _on_title_card(_title: String) -> void:
	play_music("music_doves_row", -3.0)
	play_sfx("sting", 0.0)

func _on_pause() -> void:
	play_sfx("click", -10.0)

func _on_unpause() -> void:
	play_sfx("click", -10.0)

func _on_setting_changed(key: String, _value: Variant) -> void:
	match key:
		"sfx_volume":
			_set_bus_db(SFX_BUS, Settings.sfx_volume)
		"music_volume":
			_set_bus_db(MUSIC_BUS, Settings.music_volume)
		"voice_volume":
			_set_bus_db(VOICE_BUS, Settings.voice_volume)
		"ambience_volume":
			_set_bus_db(AMBIENCE_BUS, Settings.ambience_volume)
