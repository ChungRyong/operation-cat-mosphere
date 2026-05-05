extends Node

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
const POOL_SIZE: int = 8
const MIX_RATE: int = 22050

var _bgm_player: AudioStreamPlayer
var _current_bgm: String = ""
var _cache: Dictionary = {}


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.volume_db = -10.0
	add_child(_bgm_player)
	_bgm_player.finished.connect(_on_bgm_finished)
	_precache()


func play(sound_name: String) -> void:
	if sound_name not in _cache:
		return
	var player: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % POOL_SIZE
	if player.playing:
		player.stop()
	player.stream = _cache[sound_name]
	player.play()


func play_bgm(track: String) -> void:
	if track == _current_bgm and _bgm_player.playing:
		return
	_current_bgm = track
	if track not in _cache:
		_bgm_player.stop()
		return
	_bgm_player.stream = _cache[track]
	_bgm_player.play()


func stop_bgm() -> void:
	_current_bgm = ""
	_bgm_player.stop()


func _on_bgm_finished() -> void:
	if _current_bgm != "":
		_bgm_player.play()


func _precache() -> void:
	_cache["shoot"] = _tone(800, 0.06, 0.25)
	_cache["hit"] = _tone(200, 0.08, 0.3)
	_cache["enemy_die"] = _sweep(600, 200, 0.1, 0.25)
	_cache["build"] = _sweep(300, 600, 0.18, 0.35)
	_cache["sell"] = _chord([800, 1000, 1200], 0.1, 0.25)
	_cache["repair"] = _sweep(400, 550, 0.12, 0.25)
	_cache["punch"] = _noise(0.06, 0.4)
	_cache["parry"] = _tone(1200, 0.1, 0.3)
	_cache["ultimate"] = _sweep(200, 1000, 0.35, 0.45)
	_cache["hero_hit"] = _sweep(400, 200, 0.1, 0.35)
	_cache["ui_click"] = _tone(1000, 0.03, 0.15)
	_cache["wave_start"] = _sweep(300, 800, 0.2, 0.3)
	_cache["wave_clear"] = _chord([523, 659, 784], 0.25, 0.3)
	_cache["level_up"] = _arpeggio([400, 500, 600, 800], 0.08, 0.25)
	_cache["game_over"] = _sweep(400, 100, 0.4, 0.35)
	_cache["boss_roar"] = _noise(0.3, 0.5)
	_cache["collapse"] = _noise(0.12, 0.35)
	_cache["tower_hit"] = _tone(150, 0.06, 0.2)
	_cache["bgm_day"] = _melody([523, 587, 659, 587, 523, 494, 440, 494], 0.3, 0.12)
	_cache["bgm_night"] = _melody([330, 311, 294, 277, 294, 311, 330, 294], 0.25, 0.12)
	_cache["bgm_dawn"] = _melody([523, 659, 784, 1047, 784, 659, 523, 659], 0.35, 0.1)
	_cache["bgm_menu"] = _melody([440, 523, 659, 523, 440, 392, 349, 392], 0.4, 0.08)


func _wav() -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX_RATE
	w.stereo = false
	return w


func _write_sample(data: PackedByteArray, index: int, value: float) -> void:
	var s: int = clampi(int(value * 32767.0), -32768, 32767)
	data[index * 2] = s & 0xFF
	data[index * 2 + 1] = (s >> 8) & 0xFF


func _tone(freq: float, duration: float, vol: float) -> AudioStreamWAV:
	var frames: int = int(MIX_RATE * duration)
	var w := _wav()
	var data := PackedByteArray()
	data.resize(frames * 2)
	var phase: float = 0.0
	for i in frames:
		var env: float = 1.0 - float(i) / float(frames)
		phase += freq / MIX_RATE * TAU
		_write_sample(data, i, sin(phase) * vol * env)
	w.data = data
	return w


func _sweep(freq_start: float, freq_end: float, duration: float, vol: float) -> AudioStreamWAV:
	var frames: int = int(MIX_RATE * duration)
	var w := _wav()
	var data := PackedByteArray()
	data.resize(frames * 2)
	var phase: float = 0.0
	for i in frames:
		var p: float = float(i) / float(frames)
		var freq: float = lerp(freq_start, freq_end, p)
		phase += freq / MIX_RATE * TAU
		var env: float = 1.0 - p
		_write_sample(data, i, sin(phase) * vol * env)
	w.data = data
	return w


func _noise(duration: float, vol: float) -> AudioStreamWAV:
	var frames: int = int(MIX_RATE * duration)
	var w := _wav()
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var env: float = 1.0 - float(i) / float(frames)
		_write_sample(data, i, (randf() * 2.0 - 1.0) * vol * env)
	w.data = data
	return w


func _chord(freqs: Array, duration: float, vol: float) -> AudioStreamWAV:
	var frames: int = int(MIX_RATE * duration)
	var w := _wav()
	var data := PackedByteArray()
	data.resize(frames * 2)
	var phases: Array[float] = []
	for f in freqs:
		phases.append(0.0)
	var per_vol: float = vol / freqs.size()
	for i in frames:
		var env: float = 1.0 - float(i) / float(frames)
		var sample: float = 0.0
		for j in freqs.size():
			phases[j] += float(freqs[j]) / MIX_RATE * TAU
			sample += sin(phases[j]) * per_vol
		_write_sample(data, i, sample * env)
	w.data = data
	return w


func _arpeggio(freqs: Array, note_dur: float, vol: float) -> AudioStreamWAV:
	var total_dur: float = note_dur * freqs.size()
	var frames: int = int(MIX_RATE * total_dur)
	var note_frames: int = int(MIX_RATE * note_dur)
	var w := _wav()
	var data := PackedByteArray()
	data.resize(frames * 2)
	var phase: float = 0.0
	for i in frames:
		var note_idx: int = mini(i / note_frames, freqs.size() - 1)
		var local_i: int = i - note_idx * note_frames
		var env: float = 1.0 - float(local_i) / float(note_frames)
		phase += float(freqs[note_idx]) / MIX_RATE * TAU
		_write_sample(data, i, sin(phase) * vol * env)
	w.data = data
	return w


func _melody(freqs: Array, note_dur: float, vol: float) -> AudioStreamWAV:
	var total_dur: float = note_dur * freqs.size()
	var frames: int = int(MIX_RATE * total_dur)
	var note_frames: int = int(MIX_RATE * note_dur)
	var w := _wav()
	var data := PackedByteArray()
	data.resize(frames * 2)
	var phase: float = 0.0
	for i in frames:
		var note_idx: int = mini(i / note_frames, freqs.size() - 1)
		var local_i: int = i - note_idx * note_frames
		var env: float = clampf(1.0 - float(local_i) / float(note_frames) * 0.3, 0.7, 1.0)
		var freq: float = float(freqs[note_idx])
		phase += freq / MIX_RATE * TAU
		var sample: float = sin(phase) * vol * env
		sample += sin(phase * 2.0) * vol * env * 0.15
		_write_sample(data, i, sample)
	w.data = data
	return w
