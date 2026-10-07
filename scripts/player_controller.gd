extends CharacterBody2D

## ===================================================================
## 玩家控制器（教学增强版）
## ===================================================================
## 在你原来那份的基础上加了 6 样东西：
##   1. 用"想跳多高"反推重力，不用再靠猜数字
##   2. 土狼时间 coyote time：刚走出平台边缘的一瞬间还能跳（手感救星）
##   3. 跳跃缓冲 jump buffer：落地前提前按跳，落地瞬间自动跳出去
##   4. 长短跳：轻点 W 小跳，按住 W 大跳
##   5. 受伤无敌帧 + 被弹开 + 死亡演出
##   6. 原来的"双击空格飞行"默认关掉了（allow_fly_toggle），想开自己去检查器勾选
##
## 【专业术语】CharacterBody2D = 由我们自己写脚本控制移动的身体。
##   它自带的 velocity（速度）和 move_and_slide()，能自动处理撞墙、站地面。
## ===================================================================

@export_category("移动")
@export var move_speed: float = 90.0
@export var acceleration: float = 800.0
@export var deceleration: float = 1000.0

@export_category("跳跃")
## jump_height 单位是像素。瓦片是 18 像素，所以 54 = 正好 3 格高度。
@export var jump_height: float = 65.0
@export var jump_time_to_apex: float = 0.33
@export var max_fall_speed: float = 380.0
@export var short_jump_ratio: float = 0.45

@export_category("手感补丁")
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

@export_category("受伤与死亡")
@export var invincible_time: float = 1.2
@export var knockback_x: float = 90.0
@export var knockback_y: float = -140.0
@export var death_fall_y: float = 500.0

@export_category("调试")
@export var allow_fly_toggle: bool = false

@export var dash_speed: float = 300.0
@export var dash_time: float = 0.15
var dash_timer: float = 0.0
var dash_cooldown: float = 0.0
var dash_direction: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

## 这两个不用 @export，因为它们是算出来的，不给你手动改
var gravity: float = 980.0
var jump_speed: float = -300.0

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var invincible: bool = false
var flying: bool = false
var dead: bool = false

var last_space_press_time: float = -1000.0
var double_press_interval: float = 0.3


func _ready() -> void:
	recalculate_jump()
	## add_to_group = 给玩家贴个"标签"。
	## 金币尖刺那边用 body.is_in_group("player") 就能快速认出你。
	add_to_group("player")


## -------------------------------------------------------------------
## 这套公式是《蔚蓝》那种精调手感的行业标准写法：
##   已知"想跳多高"和"多久到最高点"，反推出该用多大的重力。
##   gravity    = 2 * 高度 / 上升时间²
##   jump_speed = -2 * 高度 / 上升时间
## 用 jump_height=54、time=0.33 算出来：gravity≈991，jump_speed≈-327
## -------------------------------------------------------------------
func recalculate_jump() -> void:
	gravity = 2.0 * jump_height / (jump_time_to_apex * jump_time_to_apex)
	jump_speed = -2.0 * jump_height / jump_time_to_apex


func _physics_process(delta: float) -> void:
	if dead:
		return

	## 掉出地图兜底
	if global_position.y > death_fall_y:
		out_of_bounds()
		return

	if flying:
		handle_vertical_movement(delta)
	else:
		apply_gravity(delta)
		update_jump_timers(delta)
		handle_jump()
		handle_short_jump()

	handle_dash(delta)
	handle_horizontal_movement(delta)
	update_sprite_direction()

	## move_and_slide() = 拿当前的 velocity 去移动，遇到墙自动处理。
	## 【重要】所有改 velocity 的代码都必须写在它前面！
	move_and_slide()


func apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
		return
	## minf(a, b) = 取小的那个。用来限制最大下落速度，
	## 否则掉久了速度会无限大，可能直接穿过地面。
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


func update_jump_timers(delta: float) -> void:
	## ---- 土狼时间 ----
	## 站在地上就把计时器填满；一旦离地，它开始倒数。
	## 倒数没归零之前都算"还能跳"。
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	## ---- 跳跃缓冲 ----
	## 按了跳就把计时器填满；它会短暂记住你按过。
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)


func handle_jump() -> void:
	## 两个计时器都还没归零 => 允许起跳
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_speed
		jump_buffer_timer = 0.0
		coyote_timer = 0.0


func handle_short_jump() -> void:
	## 松开 W 时，如果还在上升，就把上升速度打折 => 变成小跳
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= short_jump_ratio


func handle_horizontal_movement(delta: float) -> void:
	## get_axis(左, 右) 返回 -1 / 0 / +1，没按就是 0
	if dash_timer > 0.0:
		return
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := direction * move_speed

	if direction != 0.0:
		## move_toward(现在, 目标, 每帧最多变多少) = 平滑加速
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)


func handle_vertical_movement(delta: float) -> void:
	var direction := Input.get_axis("squat", "jump")
	var target_speed := direction * jump_speed
	if direction != 0.0:
		velocity.y = move_toward(velocity.y, target_speed, acceleration * delta)
	else:
		velocity.y = move_toward(velocity.y, 0.0, acceleration * delta)


func update_sprite_direction() -> void:
	if velocity.x != 0.0:
		sprite.flip_h = velocity.x < 0.0


## ===================================================================
## 下面这几个函数是"留给别人调用的"
## ===================================================================

## 被弹簧调用：把自己弹上天，并短暂无敌
## （防止弹到一半被刺扎死，那种死法很让人火大）
func bounce(speed: float) -> void:
	velocity.y = speed
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	invincible = true
	get_tree().create_timer(0.3).timeout.connect(_end_invincible)


## 被尖刺调用：hazard_position 是尖刺的坐标，用来判断往哪边弹
func take_damage(hazard_position: Vector2) -> void:
	if invincible or dead:
		return
	GameState.lose_life()
	if GameState.lives <= 0:
		die()
		return
	_knockback(hazard_position)


func _knockback(hazard_position: Vector2) -> void:
	## signf() 只返回 -1 / 0 / +1，代表"正还是负"
	var direction := signf(global_position.x - hazard_position.x)
	if direction == 0.0:
		direction = -1.0
	velocity = Vector2(knockback_x * direction, knockback_y)

	invincible = true
	_start_blinking()
	get_tree().create_timer(invincible_time).timeout.connect(_end_invincible)


## 闪烁 = 把贴图透明度在 0.25 和 1 之间来回切
func _start_blinking() -> void:
	var tween := create_tween()
	tween.set_loops(int(invincible_time / 0.2))
	tween.tween_property(sprite, "modulate:a", 0.25, 0.1)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)


func _end_invincible() -> void:
	invincible = false
	sprite.modulate.a = 1.0


## 掉出地图：扣一条命然后重开本关（没命了则由 die() 接管）
func out_of_bounds() -> void:
	if dead:
		return
	GameState.lose_life()
	if GameState.lives <= 0:
		die()
		return
	get_tree().reload_current_scene()


func die() -> void:
	dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)      ## 关掉物理处理，玩家彻底不动

	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(sprite, "rotation", TAU, 0.6)
	tween.chain().tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")
	)


## ===================================================================
## 飞行模式（原始雏形自带的调试功能，现在默认关闭）
## 想打开：编辑器里选中 Player -> 检查器里勾选 Allow Fly Toggle
## ===================================================================
func _unhandled_input(event: InputEvent) -> void:
	if not allow_fly_toggle:
		return
	if event.is_action_pressed("fly") and not event.is_echo():
		_toggle_flying()


func _toggle_flying() -> void:
	var now := Time.get_ticks_msec()
	if now - last_space_press_time <= double_press_interval * 1000.0:
		flying = not flying
		last_space_press_time = -1000.0
	else:
		last_space_press_time = now
func handle_dash(delta: float) -> void:
	dash_cooldown = maxf(dash_cooldown - delta, 0.0)
	
	if dash_timer > 0.0:
		dash_timer -= delta
		velocity.x = dash_direction * dash_speed
		return
	
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0:
		dash_direction = Input.get_axis("move_left", "move_right")
		if dash_direction == 0.0:
			dash_direction = -1.0 if sprite.flip_h else 1.0
		dash_timer = dash_time
		dash_cooldown = 1.2
