extends Node2D

## ===================================================================
## 关卡基类 —— 每一关都挂这个脚本
## ===================================================================
## 它自动帮你做两件杂事，你就不用一关关重复劳动：
##   1. 自动把 HUD（分数面板）塞进场景
##   2. 按 TileMap 的实际大小，自动算好相机边界（做横向滚动的关键）
##
## 【专业术语】Node Path 节点路径：
##   $Level/TerrainTileMaps/TerrainBase
##   $ 表示从自己开始找，/ 表示下一层。和你电脑上文件夹路径一个道理。
## ===================================================================

@export var level_title: String = "未命名关卡"

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")


func _ready() -> void:
	_setup_hud()
	_setup_camera_limits()


func _setup_hud() -> void:
	var hud := HUD_SCENE.instantiate()   ## instantiate = 照着模板复制一个新的出来
	add_child(hud)                       ## add_child = 挂到自己底下，才会被显示


func _setup_camera_limits() -> void:
	## get_node_or_null = 找不到就返回 null，不会直接报错崩掉
	var terrain := get_node_or_null("Level/TerrainTileMaps/TerrainBase") as TileMapLayer
	var player := get_node_or_null("Level/ActorsAndCharacters/Player") as Node2D

	if terrain == null or player == null:
		push_warning("关卡里没找到 TerrainBase 或 Player，相机边界没设置")
		return

	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		push_warning("玩家身上没有 Camera2D，相机边界没设置")
		return

	## get_used_rect() = 这一层里所有画过格子的矩形范围（单位是"格"，不是像素）
	var used: Rect2i = terrain.get_used_rect()
	var tile_size: Vector2i = terrain.tile_set.tile_size
	var origin: Vector2 = terrain.global_position

	## Camera2D 的 limit_* 用的是世界坐标（像素），所以要把"格"乘回"像素"
	camera.limit_left = int(origin.x + used.position.x * tile_size.x)
	camera.limit_top = int(origin.y + used.position.y * tile_size.y)
	camera.limit_right = int(origin.x + used.end.x * tile_size.x)
	camera.limit_bottom = int(origin.y + used.end.y * tile_size.y)

	print("[关卡] ", level_title, " 相机边界已自动设置：",
		camera.limit_left, " ~ ", camera.limit_right)
