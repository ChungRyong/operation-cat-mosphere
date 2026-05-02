extends Node

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
const POOL_SIZE: int = 8


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(sound_name: String) -> void:
	var player: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % POOL_SIZE
	if player.playing:
		player.stop()
	var stream: AudioStream = _generate_sound(sound_name)
	if stream == null:
		return
	player.stream = stream
	player.play()


func _generate_sound(_name: String) -> AudioStream:
	return null
