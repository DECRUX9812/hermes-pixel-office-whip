extends TestCase

var _streams: Array[AudioStreamWAV] = []

func _exit_tree() -> void:
	_streams.clear()

func _make(partials: Array, loop := -1.0) -> AudioStreamWAV:
	var stream := Synth.pad(partials, 4.0, 0.25) if loop > 0.0 else Synth.emerald_chime()
	_streams.append(stream)
	return stream

func test_pad_generates_pcm16_wav() -> void:
	var stream := _make([55.0, 110.0])
	check(stream != null, "pad produced a stream")
	check_eq(stream.mix_rate, Synth.MIX_RATE, "pad uses the synth mix rate")
	check_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS, "pad is 16-bit PCM")
	check(stream.data.size() > 0, "pad has PCM data")

func test_pad_loop_is_forward_and_short() -> void:
	var stream := _make([55.0, 82.5], 4.0)
	check_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "pad loops forward")
	check(stream.loop_end > stream.loop_begin, "loop range is non-empty")
	check(stream.loop_end <= stream.data.size() / 2, "loop_end within frame count")

func test_one_shot_is_non_looping() -> void:
	var stream := _make([392.0])
	check_eq(stream.loop_mode, AudioStreamWAV.LOOP_DISABLED, "one-shots do not loop")

func test_every_public_constructor_produces_data() -> void:
	var constructors: Array[Callable] = [
		Synth.emerald_chime,
		Synth.impact,
		Synth.impact_heavy,
		Synth.whoosh,
		Synth.telegraph,
		Synth.requiem,
		Synth.heart_bind,
		Synth.truth_breach,
		Synth.ui_click,
		Synth.dialogue_blip,
		Synth.title_sting,
	]
	for constructor in constructors:
		var stream := constructor.call() as AudioStreamWAV
		check(stream != null and stream.data.size() > 0,
			"%s produced PCM data" % constructor.get_method())
		if stream:
			_streams.append(stream)

func test_ambience_beds_are_looping() -> void:
	var beds: Array[AudioStreamWAV] = [
		Synth.room_tone(),
		Synth.weep_drone(),
		Synth.choir_hum(),
		Synth.warden_choir(),
	]
	for stream in beds:
		check(stream != null and stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,
			"ambience bed loops forward")
		check(stream.data.size() > 0, "ambience bed has PCM data")
		if stream:
			_streams.append(stream)
