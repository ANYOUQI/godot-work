extends Control

## ===================================================================
## 游戏结束画面
## ===================================================================

@onready var title_label: Label = $Title


func _ready() -> void:
	## 这里的 GameState 是自动加载的，所以哪怕关卡已经切了 N 次，数据还在
	title_label.text = "游戏结束\n最终分数 " + str(GameState.score)


## 这个函数是被 Button 按钮的 pressed 信号调用的。
## 连接关系是写在 scenes/ui/game_over.tscn 文件最后那一行的 [connection] 里，
## 你也可以在编辑器里手动连：选中 Button -> 右上角"节点"面板 -> 双击 pressed 信号。
func _on_restart_pressed() -> void:
	GameState.reset_run()
	GameState.goto_level(0)
