extends Area2D

## ===================================================================
## 收集品（金币 / 宝石）
## ===================================================================
## 【专业术语】Area2D = "区域"。它不会挡住你，只负责"感觉"到有东西进来。
##   脚下踩的地面用 StaticBody2D（会挡人），捡的东西用 Area2D（不挡人）。
##
## body_entered 信号 = 有"实体"踏进我这片区域时，引擎自动帮我喊一声。
##   我只要在 _ready() 里把这个信号接到 _on_body_entered 函数上就行了。
## ===================================================================

## @export = 这个变量会出现在编辑器的 Inspector(检查器) 面板里，
##   你可以不写代码、直接拖滑块改数值。
@export var score_value: int = 10
@export var is_coin: bool = true

## @onready = "等我准备好了（子节点都生成完了）再拿这个节点"。
##   写成 @onready 是因为 _ready() 之前 $Sprite 还不存在，直接取会报错。
@onready var sprite: Sprite2D = $Sprite

var _collected: bool = false
var _time: float = 0.0
var _base_y: float = 0.0


func _ready() -> void:
	## connect = "把这个信号接到那个函数上"。
	## 以后只要有身体进来，_on_body_entered 就会自动被调用一次。
	body_entered.connect(_on_body_entered)
	_base_y = sprite.position.y


func _process(delta: float) -> void:
	_time += delta
	## sin() 会在 -1 和 1 之间来回摆，乘 2.0 就是上下浮动 2 像素。
	## 这行纯装饰，删掉游戏也能跑，但加上立刻显得"有生命感"。
	sprite.position.y = _base_y + sin(_time * 3.0) * 2.0


func _on_body_entered(body: Node2D) -> void:
	## 防重复：一次捡到就够了
	if _collected:
		return
	## 不是玩家碰的，不理会（比如以后你加个敌人滚过来）
	if not body.is_in_group("player"):
		return

	_collected = true

	if is_coin:
		GameState.add_coin()
	else:
		GameState.add_score(score_value)

	_pop_effect()


func _pop_effect() -> void:
	## 立刻停止检测，避免动画播放期间又被触发一次
	monitoring = false

	## Tween(补间动画) = "帮我在 X 秒内把某个数值从 A 变成 B"。
	## 这是 Godot 里做动画最省事的工具，不用自己写循环。
	var tween := create_tween()
	tween.set_parallel(true)                                        ## 两条同时播
	tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.15)  ## 放大
	tween.tween_property(sprite, "modulate:a", 0.0, 0.15)           ## 变透明
	## chain() = 等上面播完，再执行下面这一步：把自己销毁
	tween.chain().tween_callback(queue_free)
