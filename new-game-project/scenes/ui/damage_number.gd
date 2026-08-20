class_name DamageNumber
extends Node2D

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - FLOATING DAMAGE POPUP (Milestone R2)
# Floating damage number with upward float, scale pop, and alpha fadeout.
# ==============================================================================

@export var float_distance: float = 20.0
@export var duration: float = 0.5

var damage_amount: int = 0
var is_crit: bool = false
var _has_started: bool = false

@onready var label: Label = $Label

func _ensure_nodes() -> void:
	if label == null:
		label = get_node_or_null("Label") as Label

func setup(amount: float, arg2 = false, arg3 = Vector2.ZERO) -> void:
	_ensure_nodes()
	damage_amount = int(round(amount))
	
	if arg2 is bool:
		is_crit = arg2
		if arg3 is Vector2 and arg3 != Vector2.ZERO:
			global_position = arg3
	elif arg2 is Vector2:
		if arg2 != Vector2.ZERO:
			global_position = arg2
		if arg3 is bool:
			is_crit = arg3
			
	if label:
		label.text = str(damage_amount)
		if is_crit:
			label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0)) # Gold Crit
			label.add_theme_constant_override("outline_size", 3)
		else:
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0)) # White Normal
			label.add_theme_constant_override("outline_size", 2)
			
	scale = Vector2(1.4, 1.4) if is_crit else Vector2(1.2, 1.2)
	if is_inside_tree() and not _has_started:
		_start_animation()

func init(amount: float, arg2 = false, arg3 = Vector2.ZERO) -> void:
	setup(amount, arg2, arg3)

func _ready() -> void:
	z_index = 50
	_ensure_nodes()
	if not _has_started and (damage_amount > 0 or (label and label.text != "0")):
		_start_animation()

func _start_animation() -> void:
	_has_started = true
	_ensure_nodes()
	if label:
		label.text = str(damage_amount)
		if is_crit:
			label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0)) # Gold Crit
			label.add_theme_constant_override("outline_size", 3)
		else:
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0)) # White Normal
			label.add_theme_constant_override("outline_size", 2)
			
	var start_scale := Vector2(1.4, 1.4) if is_crit else Vector2(1.2, 1.2)
	var end_scale := Vector2(1.0, 1.0)
	var target_pos := position + Vector2(0.0, -float_distance)
	
	scale = start_scale
	
	var tween := create_tween()
	if tween == null:
		return
		
	tween.set_parallel(true)
	# Float upwards by ~20px over 0.5s
	tween.tween_property(self, "position:y", target_pos.y, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Scale pop: 1.2 (or 1.4) -> 1.0 over 0.15s
	tween.tween_property(self, "scale", end_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Fade out modulate alpha: 1.0 -> 0.0 over 0.5s
	tween.tween_property(self, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# On tween finished: queue_free()
	tween.chain().tween_callback(queue_free)
