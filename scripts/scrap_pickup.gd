extends Area2D

signal collected(amount: int)

var amount: int = 10
var _bob_time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 1


func _process(delta: float) -> void:
	_bob_time += delta
	position.y += sin(_bob_time * 3.0) * 0.3
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("hero"):
		ResourceManager.add_scrap(amount)
		collected.emit(amount)
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(-8, -8, 16, 16), Color(0.7, 0.55, 0.3, 1.0))
	draw_rect(Rect2(-6, -6, 12, 12), Color(0.9, 0.75, 0.4, 1.0))
	draw_rect(Rect2(-8, -8, 16, 16), Color(1.0, 0.85, 0.5, 0.6), false, 1.0)
