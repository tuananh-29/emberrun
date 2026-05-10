extends Area2D

# ══════════════════════════════
#  ĐUỐC CHECKPOINT
#  Setup trong Editor:
#  1. Tạo scene Torch.tscn → root node = Area2D
#  2. Thêm con: CollisionShape2D (CircleShape2D r=28)
#  3. Thêm con: AnimatedSprite2D (animation "off" và "on")
#  4. Thêm con: PointLight2D
#       - Texture: GradientTexture2D (Radial, trắng → trong suốt)
#       - Energy: 0.0 (tắt lúc đầu)
#       - Color: #FF8C20 (cam ấm)
#       - Texture Scale: 2.0
#  5. Attach script này vào node Area2D
# ══════════════════════════════

@export var energy_on_activate: float = 0.30   # hồi 30% khi thắp đuốc
@export var light_energy_active: float = 1.5   # độ sáng khi bật
@export var flicker_speed: float = 8.0         # tốc độ nhấp nháy

var activated: bool = false
var _time: float = 0.0

@onready var point_light  = $PointLight2D
@onready var anim         = $AnimatedSprite2D


func _ready():
	body_entered.connect(_on_body_entered)
	# Đuốc tắt lúc đầu
	if point_light:
		point_light.energy = 0.0


func _process(delta):
	if not activated:
		return
	# Hiệu ứng nhấp nháy khi đuốc đang cháy
	_time += delta
	if point_light:
		var flicker = sin(_time * flicker_speed) * 0.15
		point_light.energy = light_energy_active + flicker


func _on_body_entered(body: Node2D) -> void:
	if activated:
		return
	if not body.has_method("add_energy"):
		return

	# Thắp đuốc
	activated = true
	body.add_energy(energy_on_activate)
	_activate()


func _activate():
	# Đổi animation sang "on"
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("on"):
		anim.play("on")

	# Bật ánh sáng – tween mượt từ 0 lên
	if point_light:
		point_light.energy = 0.0
		var tween = create_tween()
		tween.tween_property(point_light, "energy", light_energy_active, 0.4)

	# Hiệu ứng scale nhỏ → to
	var tween2 = create_tween()
	tween2.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15)
	tween2.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
