extends Area2D

@export var swing_speed: float = 2.0
@export var max_angle: float = 2.5

var time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time += delta
	rotation = sin(time * swing_speed) * max_angle

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(global_position)
