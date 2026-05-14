extends TextureProgressBar

# Biến này sẽ tạo ra một ô trống trong Inspector để bạn kéo thả Player vào
@export var player: CharacterBody2D

func _ready() -> void:
	# Tùy chọn: Đảm bảo thanh UI này chạy từ 0 đến 100
	max_value = 100
	min_value = 0

# Hàm _process chạy liên tục mỗi khung hình (frame)
func _process(delta: float) -> void:
	# Kiểm tra xem đã kết nối Player chưa để tránh văng game
	if player != null:
		# light_energy của bạn đang là số thập phân từ 0.0 -> 1.0
		# Nên ta nhân với 100 để biến nó thành phần trăm (0 -> 100) cho thanh UI
		value = player.light_energy * 100
