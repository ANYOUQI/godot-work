extends CharacterBody2D

@export var speed: float = 60.0
@export var left_bound: float = -100.0
@export var right_bound: float = 100.0
@export var shoot_interval: float = 2.0

var direction: float = 1.0
var gravity: float = 980.0
var shoot_timer: float = 0.0

var bullet_scene = preload("res://scenes/prefabs/enemies/bullet.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $HitBox

func _ready() -> void:
	print("小怪脚本运行了！")
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	add_to_group("enemies")
	print("我的组: ", get_groups())
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	velocity.x = direction * speed

	if global_position.x < left_bound:
		direction = 1.0
	elif global_position.x > right_bound:
		direction = -1.0

	sprite.flip_h = direction < 0.0
	move_and_slide()

	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		shoot_bullet()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(global_position)
func shoot_bullet() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	var spawn_pos = sprite.global_position
	bullet.global_position = spawn_pos
	bullet.direction = (player.global_position - spawn_pos).normalized()
