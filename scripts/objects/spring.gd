extends Area2D

## ===================================================================
## 弹簧
## ===================================================================
## 关键逻辑：只有"从上方落下来"才会被弹飞。
##   如果不加这个判断，你从侧面蹭一下就飞了，手感很难受。
## ===================================================================

@export var bounce_speed: float = -420.0

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not body.has_method("bounce"):
		return

	## Godot 的 2D 坐标系：Y 越小越靠上，-Y 是往上。
	## 所以"玩家的中心 比 弹簧的中心 更高" = 玩家 y 值更小 = 从上方来的。
	## 留 6 像素的余量，防止站在地面边缘时反复触发。
	if body.global_position.y > global_position.y - 6.0:
		return

	body.bounce(bounce_speed)
	_squash_animation()


func _squash_animation() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.4, 0.6), 0.06)  ## 压扁
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.14)  ## 弹回原样
