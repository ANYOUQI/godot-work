extends Node

## ===================================================================
## GameState —— 全局状态（站在最外面管账的人）
## ===================================================================
## 为什么要有它？
##   分数、金币、生命，这些数据要在"关卡1 -> 关卡2 -> 关卡3"之间一直活着，
##   而且要被三个不同的地方读写（金币 +1、HUD 显示、关卡切换）。
##   如果写成普通变量，你就得在场景里到处找节点，改一处崩三处。
##
## 【专业术语】AutoLoad 自动加载 = 引擎一启动就自动放进场景树的东西，
##   任何脚本里都能直接写 "GameState.xxx" 访问它，永远不会被关卡切换删掉。
##
## 注册方法（已经帮你写进 project.godot 了，你可以去这里核对）：
##   顶部菜单 Project(项目) -> Project Settings(项目设置) -> Globals(自动加载) 标签页
## ===================================================================

## signal(信号) = "我会大喊一声，谁关心谁来接"。
## HUD 会来接这些信号，一接就更新屏幕上的数字。
## 好处：金币根本不需要知道 HUD 长什么样，两边互不依赖。
signal score_changed(new_score: int)
signal coins_changed(new_coins: int)
signal lives_changed(new_lives: int)


var score: int = 0
var coins: int = 0
var lives: int = 5
var deaths: int = 0
var level_index: int = 0

## Array[String] = "一串文字"的容器。这里按顺序存着每一关的场景文件路径。
## const = 常量，运行时不许改，防止自己手滑写坏。
const LEVELS: Array[String] = [
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
	"res://scenes/levels/level_03.tscn",
]


func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)   ## emit = 喊一声（触发信号）
	print("[GameState] 分数变成: ", score)


func add_coin(amount: int = 1) -> void:
	coins += amount
	coins_changed.emit(coins)
	add_score(10)


func lose_life() -> void:
	deaths += 1
	lives -= 1
	lives_changed.emit(lives)
	print("[GameState] 掉了一条命，还剩: ", lives)


## 掉出地图、摔死的时候调用这个：直接重开当前关
func respawn() -> void:
	get_tree().reload_current_scene()


## 跳到第 N 关（N 从 0 开始数，所以第一关是 0）
func goto_level(index: int) -> void:
	if index >= LEVELS.size():
		print("[GameState] 没有第 ", index, " 关，已经全部通关！")
		return
	level_index = index
	get_tree().change_scene_to_file(LEVELS[index])


func goto_next_level() -> void:
	goto_level(level_index + 1)


func reset_run() -> void:
	score = 0
	coins = 0
	lives = 5
	deaths = 0
	level_index = 0
	print("[GameState] 数据已重置，准备重新开始")
