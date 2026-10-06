extends Area2D

@export var rotate_speed: float = 3.0

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	sprite.rotation += rotate_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(global_position)
