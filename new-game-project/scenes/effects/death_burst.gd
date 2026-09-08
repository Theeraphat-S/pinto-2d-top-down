extends CPUParticles2D

func _ready() -> void:
	emitting = true
	one_shot = true
	explosiveness = 1.0
	lifetime = 0.35
	amount = 16
	spread = 180.0
	gravity = Vector2(0, 60)
	initial_velocity_min = 60.0
	initial_velocity_max = 130.0
	scale_amount_min = 2.5
	scale_amount_max = 4.5
	color = Color(1.0, 0.85, 0.3, 1.0)
	
	# Auto-free after burst finishes
	var timer := get_tree().create_timer(lifetime + 0.1, false)
	timer.timeout.connect(queue_free)

func init(spawn_pos: Vector2, burst_color: Color = Color(1.0, 0.85, 0.3, 1.0)) -> void:
	global_position = spawn_pos
	color = burst_color
