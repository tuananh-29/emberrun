extends CharacterBody2D

# ══════════════════════════════
#  CHỈ SỐ DI CHUYỂN
# ══════════════════════════════
const SPEED = 100.0
const JUMP_VELOCITY = -250.0
const DOUBLE_JUMP_VELOCITY = -200.0

# ══════════════════════════════
#  CƠ CHẾ NHẢY
# ══════════════════════════════
var jump_count = 0
const MAX_JUMPS = 2

# ══════════════════════════════
#  CƠ CHẾ ÁNH SÁNG SINH MỆNH
# ══════════════════════════════
var light_energy: float = 1.0         # 1.0 = 100%
const DECAY_RATE: float = 0.02        # giảm 2% mỗi giây → sống ~50s nếu không chạm gì
const LIGHT_MAX_SCALE: float = 3.0    # kích thước vòng sáng tối đa
const LIGHT_MIN_SCALE: float = 0.3    # kích thước vòng sáng tối thiểu

# ══════════════════════════════
#  CƠ CHẾ GAI (SPIKES)
# ══════════════════════════════
var on_spikes: bool = false
var spike_timer: float = 0.0
const SPIKE_DAMAGE_INTERVAL: float = 1.2  # hit lại mỗi 1.2s nếu đứng yên trên gai

# ══════════════════════════════
#  TRẠNG THÁI
# ══════════════════════════════
var is_dead: bool = false
var is_hit: bool = false

# ══════════════════════════════
#  TRỌNG LỰC & NODE
# ══════════════════════════════
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim        = $AnimatedSprite2D
@onready var point_light = $PointLight2D


# ══════════════════════════════
#  KHỞI TẠO
# ══════════════════════════════
func _ready():
	anim.animation_finished.connect(_on_animation_finished)


# ══════════════════════════════
#  VÒNG LẶP CHÍNH
# ══════════════════════════════
func _physics_process(delta):
	if is_dead:
		return

	# 1. TRỌNG LỰC
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jump_count = 0

	# 2. NHẢY (DOUBLE JUMP)
	if Input.is_action_just_pressed("move_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			jump_count = 1
		elif jump_count < MAX_JUMPS:
			velocity.y = DOUBLE_JUMP_VELOCITY
			jump_count += 1

	# 3. DI CHUYỂN TRÁI PHẢI
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		anim.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# 4. ANIMATION
	_update_animation()

	# 5. ÁNH SÁNG DECAY
	_handle_light_decay(delta)

	# 6. DAMAGE LIÊN TỤC KHI ĐỨNG TRÊN GAI
	if on_spikes:
		spike_timer -= delta
		if spike_timer <= 0:
			take_damage(0.10)
			spike_timer = SPIKE_DAMAGE_INTERVAL


# ══════════════════════════════
#  ANIMATION
# ══════════════════════════════
func _update_animation():
	if is_hit or is_dead:
		return

	if not is_on_floor():
		anim.play("jump")
	elif Input.get_axis("move_left", "move_right") != 0:
		anim.play("run")
	else:
		anim.play("idle")

func _on_animation_finished(anim_name: StringName):
	if anim_name == "hit":
		is_hit = false
	elif anim_name == "death":
		pass


# ══════════════════════════════
#  ÁNH SÁNG
# ══════════════════════════════
func _handle_light_decay(delta):
	if light_energy <= 0:
		return

	light_energy -= DECAY_RATE * delta
	light_energy = max(light_energy, 0.0)

	if point_light:
		point_light.texture_scale = lerp(LIGHT_MIN_SCALE, LIGHT_MAX_SCALE, light_energy)

	if light_energy <= 0:
		die()

func add_energy(amount: float):
	# Gọi khi nhặt than/củi
	light_energy = min(light_energy + amount, 1.0)


# ══════════════════════════════
#  NHẬN SÁT THƯƠNG
# ══════════════════════════════
func take_damage(amount: float):
	if is_dead or is_hit:
		return

	light_energy -= amount
	light_energy = max(light_energy, 0.0)
	velocity.y = -200

	is_hit = true
	anim.play("hit")
	
	await get_tree().create_timer(0.2).timeout
	if not is_dead:
		is_hit = false

	if light_energy <= 0:
		die()


# ══════════════════════════════
#  CHẾT
# ══════════════════════════════
func die():
	if is_dead:
		return
	is_dead = true
	on_spikes = false
	velocity = Vector2.ZERO
	anim.play("death")

	if point_light:
		point_light.enabled = false

	await get_tree().create_timer(1.5).timeout
	get_tree().call_deferred("reload_current_scene")


# ══════════════════════════════
#  SIGNAL TỪ GAI (SPIKES)
#  Editor: Spikes → body_entered  → _on_spikes_body_entered
#          Spikes → body_exited   → _on_spikes_body_exited
# ══════════════════════════════
func _on_spikes_body_entered(body: Node2D) -> void:
	if body == self:
		on_spikes = true
		spike_timer = 0.0    # hit ngay lập tức khi bước vào

func _on_spikes_body_exited(body: Node2D) -> void:
	if body == self:
		on_spikes = false    # bước ra → dừng hoàn toàn


# ══════════════════════════════
#  SIGNAL TỪ BÁNH CƯA (SAWBLADE)
#  Editor: Sawblade → body_entered → _on_sawblade_body_entered
# ══════════════════════════════
func _on_sawblade_body_entered(body: Node2D) -> void:
	if body == self:
		take_damage(0.20)    # bánh cưa trừ 20% một lần


func _on_torch_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_torch_2_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
