extends CanvasLayer

## ===================================================================
## HUD —— 抬头显示（屏幕上固定的分数、金币、生命）
## ===================================================================
## 【专业术语】CanvasLayer(画布层) = 一层永远跟着屏幕走的图层。
##   如果不用 CanvasLayer，它会跟着相机滚出屏幕——这是新手最常见的翻车点。
## ===================================================================

@onready var score_label: Label = $ScoreLabel
@onready var coins_label: Label = $CoinsLabel
@onready var lives_label: Label = $LivesLabel


func _ready() -> void:
	## 订阅 GameState 的广播：分数一变，我就更新界面
	GameState.score_changed.connect(_on_score_changed)
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.lives_changed.connect(_on_lives_changed)

	## 先把当前值显示出来（防止中途重开关卡时数字不同步）
	_on_score_changed(GameState.score)
	_on_coins_changed(GameState.coins)
	_on_lives_changed(GameState.lives)


func _on_score_changed(new_score: int) -> void:
	## %06d = 显示成 6 位数字，不足的前面补 0，看起来像游戏机上的计分板
	score_label.text = "分数 " + ("%06d" % new_score)


func _on_coins_changed(new_coins: int) -> void:
	coins_label.text = "金币 x" + ("%02d" % new_coins)


func _on_lives_changed(new_lives: int) -> void:
	lives_label.text = "生命 x" + str(new_lives)
