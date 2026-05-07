extends Node2D
class_name VFX

enum Type { EXPLOSION, STUN, REFLECT, ULTIMATE }

var _type: Type = Type.EXPLOSION
var _lifetime: float = 0.0
var _max_lifetime: float = 0.5
var _particles: Array[Dictionary] = []
var _color: Color = Color.WHITE


static func spawn(parent: Node, pos: Vector2, type: Type, color: Color = Color.WHITE) -> void:
	var vfx := preload("res://scenes/vfx/vfx.tscn").instantiate() as Node2D
	vfx._type = type
	vfx._color = color
	vfx.global_position = pos
	vfx.z_index = 10
	match type:
		Type.EXPLOSION:
			vfx._max_lifetime = 0.4
			vfx._init_explosion(color)
		Type.STUN:
			vfx._max_lifetime = 0.6
			vfx._init_stun()
		Type.REFLECT:
			vfx._max_lifetime = 0.35
			vfx._init_reflect()
		Type.ULTIMATE:
			vfx._max_lifetime = 0.8
			vfx._init_ultimate()
	parent.add_child(vfx)


func _process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= _max_lifetime:
		queue_free()
		return
	for p in _particles:
		p["pos"] += p["vel"] * delta
		p["vel"] *= 0.92
	queue_redraw()


func _draw() -> void:
	var t: float = _lifetime / _max_lifetime
	match _type:
		Type.EXPLOSION:
			_draw_explosion(t)
		Type.STUN:
			_draw_stun(t)
		Type.REFLECT:
			_draw_reflect(t)
		Type.ULTIMATE:
			_draw_ultimate(t)


func _init_explosion(color: Color) -> void:
	for i in 8:
		var angle: float = TAU * i / 8.0 + randf_range(-0.3, 0.3)
		var speed: float = randf_range(60.0, 120.0)
		_particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"size": randf_range(2.0, 4.5),
			"color": color.lerp(Color.YELLOW, randf_range(0.0, 0.4)),
		})


func _draw_explosion(t: float) -> void:
	var alpha: float = 1.0 - t
	var ring_radius: float = t * 20.0
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 16, Color(1.0, 0.8, 0.3, alpha * 0.5), 2.0)
	for p in _particles:
		var c: Color = p["color"]
		c.a = alpha
		var s: float = p["size"] * (1.0 - t * 0.6)
		draw_circle(p["pos"], s, c)


func _init_stun() -> void:
	for i in 5:
		var angle: float = TAU * i / 5.0
		_particles.append({
			"pos": Vector2(cos(angle), sin(angle)) * 12.0,
			"vel": Vector2.ZERO,
			"angle": angle,
		})


func _draw_stun(t: float) -> void:
	var alpha: float = 1.0 - t
	var spin: float = _lifetime * 6.0
	for p in _particles:
		var a: float = p["angle"] + spin
		var r: float = 14.0 + sin(t * TAU * 2.0) * 4.0
		var pos := Vector2(cos(a), sin(a)) * r
		_draw_star(pos, 3.5 * (1.0 - t * 0.3), Color(1.0, 1.0, 0.2, alpha))


func _draw_star(center: Vector2, size: float, color: Color) -> void:
	var points: PackedVector2Array = []
	for i in 10:
		var a: float = TAU * i / 10.0 - PI * 0.5
		var r: float = size if i % 2 == 0 else size * 0.4
		points.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(points, color)


func _init_reflect() -> void:
	for i in 6:
		var angle: float = TAU * i / 6.0 + randf_range(-0.2, 0.2)
		var speed: float = randf_range(40.0, 80.0)
		_particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"size": randf_range(1.5, 3.0),
		})


func _draw_reflect(t: float) -> void:
	var alpha: float = 1.0 - t
	var flash: float = max(1.0 - t * 4.0, 0.0)
	if flash > 0.0:
		draw_circle(Vector2.ZERO, 16.0 * flash, Color(0.8, 0.9, 1.0, flash * 0.7))
	var ring_r: float = t * 24.0
	draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 16, Color(0.7, 0.85, 1.0, alpha * 0.6), 1.5)
	for p in _particles:
		var c := Color(0.8, 0.9, 1.0, alpha)
		draw_circle(p["pos"], p["size"] * (1.0 - t * 0.5), c)


func _init_ultimate() -> void:
	for i in 16:
		var angle: float = TAU * i / 16.0
		var speed: float = randf_range(100.0, 200.0)
		_particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"size": randf_range(3.0, 6.0),
			"color": [Color(1.0, 0.6, 0.2), Color(1.0, 0.3, 0.1), Color(1.0, 0.9, 0.3)].pick_random(),
		})


func _draw_ultimate(t: float) -> void:
	var alpha: float = 1.0 - t
	var flash: float = max(1.0 - t * 3.0, 0.0)
	if flash > 0.0:
		draw_circle(Vector2.ZERO, 60.0 * flash, Color(1.0, 0.9, 0.5, flash * 0.4))
	var ring1: float = t * 80.0
	var ring2: float = t * 50.0
	draw_arc(Vector2.ZERO, ring1, 0.0, TAU, 32, Color(1.0, 0.5, 0.1, alpha * 0.5), 3.0)
	draw_arc(Vector2.ZERO, ring2, 0.0, TAU, 32, Color(1.0, 0.8, 0.3, alpha * 0.4), 2.0)
	for p in _particles:
		var c: Color = p["color"]
		c.a = alpha
		draw_circle(p["pos"], p["size"] * (1.0 - t * 0.4), c)
