extends Area2D

## ===================================================================
## 终点（碰到就进下一关）
## ===================================================================
## next_level_index 填 -1 时，表示"按 GameState.LEVELS 的顺序自动进下一关"。
## 你也可以手动填 0 / 1 / 2，做成跳关。
## ===================================================================

@export var next_level_index: int = -1
## 让玩家先"知道自己到了"，0.4 秒后再切场景，否则画面一闪而过很突兀
@export var delay_before_switch: float = 0.4

var _used: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _used:
		return
	if not body.is_in_group("player"):
		return
	_used = true

	GameState.add_score(500)
	print("[Goal] 到达终点！")

	## create_timer = 场景树自带的计时器，时间到会 timeout。
	## 这是 Godot 里最常用的"延迟一会儿再做某事"写法。
	get_tree().create_timer(delay_before_switch).timeout.connect(_go)


func _go() -> void:
	if next_level_index >= 0:
		GameState.goto_level(next_level_index)
	else:
		GameState.goto_next_level()
