extends CharacterBody2D

# --- CHỈ SỐ DI CHUYỂN ---
const SPEED = 100.0
const JUMP_VELOCITY = -250.0
const DOUBLE_JUMP_VELOCITY = -200.0

# --- CƠ CHẾ NHẢY ---
var jump_count = 0
const MAX_JUMPS = 2

# --- CƠ CHẾ ÁNH SÁNG SINH MỆNH ---
var light_energy: float = 1.0 # 100%
const DECAY_RATE: float = 0.05 # Tốc độ giảm lửa (giảm 5% mỗi giây)
var is_dead: bool = false

# --- TRỌNG LỰC & NODE ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim = $AnimatedSprite2D
@onready var point_light = $PointLight2D # Đảm bảo bạn đã thêm Node này và đặt đúng tên

func _physics_process(delta):
	# 0. NẾU CHẾT THÌ DỪNG MỌI THỨ
	if is_dead:
		return

	# 1. TRỌNG LỰC
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jump_count = 0 # Reset số lần nhảy khi chạm đất

	# 2. XỬ LÝ NHẢY (DOUBLE JUMP)
	if Input.is_action_just_pressed("move_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			jump_count = 1
		elif jump_count < MAX_JUMPS:
			velocity.y = DOUBLE_JUMP_VELOCITY
			jump_count += 1
			# Nếu bạn có animation "roll", hãy bật nó ở đây:
			# anim.play("roll")

	# 3. DI CHUYỂN TRÁI PHẢI & ANIMATION
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * SPEED
		anim.play("run")
		anim.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			anim.play("idle")

	move_and_slide()
	
	# 4. CẬP NHẬT ÁNH SÁNG
	handle_light_decay(delta)

# --- HÀM XỬ LÝ ÁNH SÁNG ---
func handle_light_decay(delta):
	if light_energy > 0:
		light_energy -= DECAY_RATE * delta
		# Cập nhật độ lớn của ánh sáng theo năng lượng còn lại
		if point_light:
			point_light.texture_scale = max(light_energy, 0.1) 
		
		if light_energy <= 0:
			die()

# --- HÀM KHI DÍNH SÁT THƯƠNG (Gai/Bánh cưa gọi hàm này) ---
func take_damage(amount: float):
	light_energy -= amount
	# Hiệu ứng nảy lên khi dính bẫy
	velocity.y = -200 
	print("Ouch! Còn lại: ", int(light_energy * 100), "% lửa")
	
	if light_energy <= 0:
		die()

# --- HÀM KHI CHẾT ---
func die():
	if is_dead: return
	is_dead = true
	velocity = Vector2.ZERO
	anim.play("death")
	print("Lửa đã tắt... Game Over!")

# --- HÀM KẾT NỐI TÍN HIỆU TỪ GAI (SPIKES) ---
# Cách làm: Chọn Area2D (Gai) -> Node -> body_entered -> Kết nối vào Player
func _on_spike_body_entered(body: Node2D) -> void:
	if body == self:
		take_damage(0.2) # Dính gai trừ 20% máu
