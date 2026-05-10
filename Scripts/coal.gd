extends Area2D


@export var energy_amount: float = 0.20   # hồi 20% energy khi nhặt
@export var bob_speed: float = 2.0        # tốc độ lơ lửng
@export var bob_height: float = 4.0       # biên độ lơ lửng (pixel)
 
var _start_y: float
var _time: float = 0.0
var _collected: bool = false
 
@onready var sprite = $Sprite2D   # hoặc $Sprite2D nếu dùng Sprite2D
 
 
func _ready():
	_start_y = position.y
	# Kết nối signal – player chạm vào thì nhặt
	body_entered.connect(_on_body_entered)
 
 
func _process(delta):
	if _collected:
		return
	# Hiệu ứng lơ lửng lên xuống
	_time += delta
	position.y = _start_y + sin(_time * bob_speed) * bob_height
 
 
func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	# Kiểm tra body có phải Player không (có hàm add_energy)
	if body.has_method("add_energy"):
		_collected = true
		body.add_energy(energy_amount)
		_play_collect_effect()
 
 
func _play_collect_effect():
	# Tắt collision ngay để không nhặt 2 lần
	$CollisionShape2D.set_deferred("disabled", true)
 
	# Scale to rồi biến mất
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
