class_name Synth
extends Object
## Procedural placeholder synthesis for the vertical slice.
##
## Every sound in the slice is generated here at runtime as raw 16-bit PCM
## (AudioStreamWAV) — there are NO external audio files. This is an original
## placeholder layer: the cues carry the world's *identity* (emerald chime for
## Hermes, copper thud for constructs, choir hum for the stratum) but every cue
## is a synthesised stand-in that a production sound-designer pass replaces.
##
## Design rules (aligns with docs/EMOTIONAL_PACING.md temperature scale):
##   - Layered-sine pads are loop-safe: partials and LFOs are integer-cycle
##     multiples of the loop length, so the head and tail match exactly.
##   - One-shots are short and dry; no reverb is baked into the signal.
##   - Silence is a sound too: Dove's Row's cold open is a near-black room tone.
##
## Synthesis is pure math (no engine audio devices touched), so it is safe to
## run headless and in unit tests.

const MIX_RATE := 22050
const LOOP_SECONDS := 4.0

## Renders a float sample buffer into a 16-bit mono AudioStreamWAV.
static func stream(samples: PackedFloat32Array, loop_seconds := -1.0) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = _to_pcm(samples)
	if loop_seconds > 0.0:
		var frames := int(loop_seconds * MIX_RATE)
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = mini(frames, samples.size())
	return wav

static func _to_pcm(samples: PackedFloat32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var s := clampf(samples[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(roundf(s * 32767.0)))
	return bytes

## --- Low-level building blocks -------------------------------------------------

static func _sine_at(phase: float) -> float:
	return sin(phase * TAU)

static func _noise_at(seed: int) -> float:
	return (hash(seed) % 1000) / 500.0 - 1.0

## One-pole low-pass (cutoff 0..1, higher = brighter).
static func _lowpass(input: PackedFloat32Array, cutoff: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(input.size())
	var y := 0.0
	var a := clampf(cutoff, 0.0, 0.999)
	for i in input.size():
		y += a * (input[i] - y)
		out[i] = y
	return out

## --- Pads (loop-safe ambience) -------------------------------------------------

## A layered-sine pad. `partials` are frequencies in Hz; every partial plus the
## amplitude LFO completes integer cycles over `loop_seconds`, making the loop
## seamless. `lfo_depth` (0..1) swells the loudness.
static func pad(partials: Array, loop_seconds := LOOP_SECONDS, lfo_depth := 0.25) -> AudioStreamWAV:
	var frames := int(loop_seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	for f in partials:
		var freq := float(f)
		if freq <= 0.0:
			continue
		var cycles := freq * loop_seconds
		if int(round(cycles)) < 1:
			continue
		var amp := 1.0 / float(partials.size())
		for i in frames:
			var t := float(i) / MIX_RATE
			var lfo := 1.0 - lfo_depth * 0.5 + lfo_depth * 0.5 * _sine_at(float(i) * TAU / frames)
			samples[i] += amp * lfo * _sine_at(freq * t)
	_normalize(samples)
	return stream(samples, loop_seconds)

## Cold-open room tone: the near-silence of Dove's Row. Mostly black, with a
## whisper of distant water so the absence of voices is legible, not dead air.
static func room_tone(loop_seconds := LOOP_SECONDS) -> AudioStreamWAV:
	var frames := int(loop_seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	for i in frames:
		var t := float(i) / MIX_RATE
		var grain := _noise_at(i) * 0.02
		samples[i] = grain + 0.008 * _sine_at(48.0 * t) + 0.006 * _sine_at(72.0 * t)
	_normalize(samples, 0.05)
	return stream(samples, loop_seconds)

## Choir Below: a warm, slightly beating low drone — the stratum's audible weight.
static func choir_hum(loop_seconds := LOOP_SECONDS) -> AudioStreamWAV:
	return pad([55.0, 82.5, 110.0, 123.5, 165.0], loop_seconds, 0.3)

## Flooded crypts: low drone plus periodic water drips.
static func weep_drone(loop_seconds := LOOP_SECONDS) -> AudioStreamWAV:
	var frames := int(loop_seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	var drip_interval := MIX_RATE / 2.4
	for i in frames:
		var t := float(i) / MIX_RATE
		var base := 0.14 * _sine_at(58.0 * t) + 0.09 * _sine_at(87.0 * t)
		samples[i] = base
	# Drip blips
	for d in int(loop_seconds * 2.4):
		var start := int(d * drip_interval)
		for j in int(0.06 * MIX_RATE):
			var idx := start + j
			if idx >= samples.size():
				break
			var decay := 1.0 - float(j) / (0.06 * MIX_RATE)
			samples[idx] += decay * 0.5 * _noise_at(idx + d * 7)
	_normalize(samples, 0.7)
	return stream(samples, loop_seconds)

## Warden arena: the choir hum drawn tighter and louder — copper singing green.
static func warden_choir(loop_seconds := LOOP_SECONDS) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var base := pad([110.0, 123.5, 165.0, 220.0, 247.5], loop_seconds, 0.35).data
	for i in base.size() / 2:
		samples.append(base.decode_s16(i * 2) / 32767.0)
	_normalize(samples, 0.9)
	return stream(samples, loop_seconds)

## --- One-shots -----------------------------------------------------------------

## Hermes voice: a pure, warm chime with a long decay. No hertz jitter — the
## voice "remembers" cleanly.
static func emerald_chime(seconds := 2.4) -> AudioStreamWAV:
	var frames := int(seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	for i in frames:
		var t := float(i) / MIX_RATE
		var env := exp(-t * 2.2)
		var partial := _sine_at(392.0 * t) + 0.5 * _sine_at(587.3 * t) + 0.3 * _sine_at(784.0 * t)
		samples[i] = env * 0.55 * partial
	_normalize(samples, 0.8)
	return stream(samples)

## Staff impact on a construct: noise crack + copper thump.
static func impact(seconds := 0.32) -> AudioStreamWAV:
	var frames := int(seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	for i in frames:
		var t := float(i) / MIX_RATE
		var env := exp(-t * 18.0)
		var crack := _noise_at(i) * env
		var thump := env * 0.8 * _sine_at(70.0 * t)
		samples[i] = crack * 0.7 + thump
	_normalize(samples, 0.85)
	return stream(samples)

## Heavy finisher: bigger, lower.
static func impact_heavy(seconds := 0.45) -> AudioStreamWAV:
	var frames := int(seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	for i in frames:
		var t := float(i) / MIX_RATE
		var env := exp(-t * 12.0)
		var crack := _noise_at(i) * env
		var thump := env * (0.6 * _sine_at(52.0 * t) + 0.4 * _sine_at(104.0 * t))
		samples[i] = crack * 0.5 + thump
	_normalize(samples, 0.9)
	return stream(samples)

## Dodge / staff swing: a filtered noise sweep.
static func whoosh(seconds := 0.28) -> AudioStreamWAV:
	var frames := int(seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	var raw := PackedFloat32Array()
	raw.resize(frames)
	for i in frames:
		raw[i] = _noise_at(i)
	for i in frames:
		var t := float(i) / frames
		var env := sin(t * PI)
		var cutoff := 0.12 + 0.6 * t
		# sliding one-pole over the raw noise
		var a := clampf(cutoff, 0.0, 0.999)
		raw[i] = a * raw[i] + (1.0 - a) * (raw[i - 1] if i > 0 else 0.0)
		samples[i] = env * raw[i]
	_normalize(samples, 0.55)
	return stream(samples)

## Custodian telegraph: a rising ping (readable warning).
static func telegraph(seconds := 0.5) -> AudioStreamWAV:
	var frames := int(seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	for i in frames:
		var t := float(i) / MIX_RATE
		var env := sin(t / seconds * PI)
		var freq := 440.0 + 640.0 * (t / seconds)
		samples[i] = env * 0.5 * _sine_at(freq * t)
	_normalize(samples, 0.5)
	return stream(samples)

## Warden requiem channel: a dissonant chord stab (minor-second cluster).
static func requiem(seconds := 0.8) -> AudioStreamWAV:
	var frames := int(seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	for i in frames:
		var t := float(i) / MIX_RATE
		var env := sin(t / seconds * PI) * 0.9
		var cluster := _sine_at(220.0 * t) + 0.9 * _sine_at(233.08 * t) + 0.7 * _sine_at(277.18 * t)
		samples[i] = env * 0.4 * cluster
	_normalize(samples, 0.7)
	return stream(samples)

## Brooklyn's Heart-Bind: a warm, rising two-note success.
static func heart_bind(seconds := 0.6) -> AudioStreamWAV:
	var frames := int(seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	for i in frames:
		var t := float(i) / MIX_RATE
		var env := exp(-t * 4.0)
		var note := _sine_at(440.0 * t) + 0.6 * _sine_at(659.25 * t)
		samples[i] = env * 0.5 * note
	_normalize(samples, 0.6)
	return stream(samples)

## Nous's Truth Breach: a dry digital glissando shimmer.
static func truth_breach(seconds := 0.5) -> AudioStreamWAV:
	var frames := int(seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	for i in frames:
		var t := float(i) / MIX_RATE
		var env := sin(t / seconds * PI)
		var freq := 600.0 + 1200.0 * (t / seconds)
		var shimmer := 0.6 * _sine_at(freq * t) + 0.3 * _sine_at(freq * 1.5 * t) + 0.2 * _noise_at(i)
		samples[i] = env * 0.35 * shimmer
	_normalize(samples, 0.5)
	return stream(samples)

## UI / dialogue ticks.
static func ui_click(seconds := 0.06) -> AudioStreamWAV:
	var frames := int(seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	for i in frames:
		var t := float(i) / MIX_RATE
		samples[i] = (1.0 - t / seconds) * 0.4 * _sine_at(1400.0 * t)
	_normalize(samples, 0.3)
	return stream(samples)

## Soft subtitle tick (voiced placeholder blip).
static func dialogue_blip(seconds := 0.09) -> AudioStreamWAV:
	var frames := int(seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	for i in frames:
		var t := float(i) / MIX_RATE
		var env := exp(-t * 30.0)
		samples[i] = env * 0.3 * (_sine_at(520.0 * t) + 0.4 * _sine_at(780.0 * t))
	_normalize(samples, 0.35)
	return stream(samples)

## Title-card / story beat sting: low swell resolving into an emerald chime.
static func title_sting(seconds := 1.8) -> AudioStreamWAV:
	var frames := int(seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	for i in frames:
		var t := float(i) / MIX_RATE
		var swell := minf(t / 0.6, 1.0)
		var low := swell * 0.35 * _sine_at(110.0 * t)
		var chime := _sine_at(523.25 * t) + 0.5 * _sine_at(784.0 * t)
		var chime_env := smoothstep(0.6, 0.9, t) * exp(-maxf(t - 0.6, 0.0) * 2.0)
		samples[i] = low + chime_env * 0.4 * chime
	_normalize(samples, 0.75)
	return stream(samples)

## --- Helpers -------------------------------------------------------------------

static func _normalize(samples: PackedFloat32Array, target := 1.0) -> void:
	var peak := 0.0
	for s in samples:
		peak = maxf(peak, absf(s))
	if peak < 0.0001:
		return
	var scale := target / peak
	for i in samples.size():
		samples[i] *= scale
