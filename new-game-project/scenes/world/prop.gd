@tool
class_name ArenaProp
extends StaticBody2D

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - OBSTACLE PROP (Milestone M3)
# Decorative obstacle props with foot-level StaticBody2D collisions and Y-sorting.
# ==============================================================================

enum PropType {
	SERVER_RACK = 0,
	HOLOGRAM_PYLON = 1,
	POWER_CRYSTAL = 2,
	TERMINAL_CONSOLE = 3
}

const PROPS_TEXTURE_PATH: String = "res://assets/tilesets/props.png"
const RADIAL_LIGHT_PATH: String = "res://assets/sprites/radial_light.tres"
const LAYER_WORLD: int = 1 # Collision Layer 1 (World/Obstacles)

@export var prop_type: PropType = PropType.SERVER_RACK:
	set(val):
		prop_type = val
		_ensure_components()
		_update_prop_configuration()

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shadow: Node2D = $Shadow
var prop_light: PointLight2D = null

var _shadow_size := Vector2(28.0, 10.0)
var _anim_time: float = 0.0
var _pulse_offset: float = 0.0

func _ready() -> void:
	# Layer 1 (World/Obstacles)
	collision_layer = LAYER_WORLD
	collision_mask = 0
	y_sort_enabled = true
	_pulse_offset = randf_range(0.0, TAU)
	
	_ensure_components()
	_update_prop_configuration()

func _ensure_components() -> void:
	if has_node("Shadow"):
		shadow = get_node("Shadow")
	else:
		var sh := Node2D.new()
		sh.name = "Shadow"
		sh.z_index = -1
		add_child(sh)
		shadow = sh
		
	if shadow and not shadow.draw.is_connected(_on_shadow_draw):
		shadow.draw.connect(_on_shadow_draw)
		
	if has_node("Sprite2D"):
		sprite = get_node("Sprite2D")
	else:
		var sp := Sprite2D.new()
		sp.name = "Sprite2D"
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sp)
		sprite = sp
		
	if has_node("CollisionShape2D"):
		collision_shape = get_node("CollisionShape2D")
	else:
		var cs := CollisionShape2D.new()
		cs.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		cs.shape = rect
		add_child(cs)
		collision_shape = cs

	if has_node("PropLight"):
		prop_light = get_node("PropLight")
	else:
		var pl := PointLight2D.new()
		pl.name = "PropLight"
		var l_tex = load(RADIAL_LIGHT_PATH)
		if l_tex:
			pl.texture = l_tex
		add_child(pl)
		prop_light = pl

func set_prop_type(type: PropType) -> void:
	prop_type = type
	_ensure_components()
	_update_prop_configuration()

func _update_prop_configuration() -> void:
	if sprite == null or collision_shape == null:
		return
		
	var tex: Texture2D = load(PROPS_TEXTURE_PATH)
	if tex == null:
		push_warning("[Prop] Could not load texture at: " + PROPS_TEXTURE_PATH)
		return
		
	sprite.texture = tex
	sprite.region_enabled = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	var shape: RectangleShape2D
	if collision_shape.shape is RectangleShape2D:
		shape = collision_shape.shape as RectangleShape2D
	else:
		shape = RectangleShape2D.new()
		collision_shape.shape = shape

	match prop_type:
		PropType.SERVER_RACK:
			# Server Rack: 32w x 48h, region (0, 16, 32, 48)
			sprite.region_rect = Rect2(0, 16, 32, 48)
			sprite.position = Vector2(0, -24)
			shape.size = Vector2(28, 14)
			collision_shape.position = Vector2(0, -7)
			_shadow_size = Vector2(30, 10)
			if prop_light:
				prop_light.color = Color(0.2, 0.9, 0.4, 1.0)
				prop_light.energy = 0.5
				prop_light.texture_scale = 0.7
				prop_light.position = Vector2(0, -24)
			
		PropType.HOLOGRAM_PYLON:
			# Hologram Pylon: 16w x 48h, region (36, 16, 16, 48)
			sprite.region_rect = Rect2(36, 16, 16, 48)
			sprite.position = Vector2(0, -24)
			shape.size = Vector2(14, 12)
			collision_shape.position = Vector2(0, -6)
			_shadow_size = Vector2(18, 8)
			if prop_light:
				prop_light.color = Color(0.3, 0.8, 1.5, 1.0)
				prop_light.energy = 0.8
				prop_light.texture_scale = 1.0
				prop_light.position = Vector2(0, -32)
			
		PropType.POWER_CRYSTAL:
			# Power Crystal: 32w x 32h, region (56, 32, 32, 32)
			sprite.region_rect = Rect2(56, 32, 32, 32)
			sprite.position = Vector2(0, -16)
			shape.size = Vector2(24, 12)
			collision_shape.position = Vector2(0, -6)
			_shadow_size = Vector2(28, 10)
			if prop_light:
				prop_light.color = Color(0.8, 0.3, 1.6, 1.0)
				prop_light.energy = 1.0
				prop_light.texture_scale = 1.2
				prop_light.position = Vector2(0, -16)
			
		PropType.TERMINAL_CONSOLE:
			# Terminal Console: 32w x 32h, region (92, 32, 32, 32)
			sprite.region_rect = Rect2(92, 32, 32, 32)
			sprite.position = Vector2(0, -16)
			shape.size = Vector2(26, 12)
			collision_shape.position = Vector2(0, -6)
			_shadow_size = Vector2(28, 10)
			if prop_light:
				prop_light.color = Color(0.2, 1.2, 0.8, 1.0)
				prop_light.energy = 0.7
				prop_light.texture_scale = 0.9
				prop_light.position = Vector2(0, -16)

	if shadow != null:
		shadow.queue_redraw()

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or prop_light == null:
		return
	_anim_time += delta
	var t: float = _anim_time + _pulse_offset
	match prop_type:
		PropType.POWER_CRYSTAL:
			prop_light.energy = 0.8 + 0.35 * sin(t * 3.5)
		PropType.HOLOGRAM_PYLON:
			prop_light.energy = 0.7 + 0.25 * sin(t * 4.2)
		PropType.TERMINAL_CONSOLE:
			prop_light.energy = 0.65 + 0.15 * sin(t * 8.0)
		PropType.SERVER_RACK:
			if fmod(t * 4.0, 1.0) < 0.12:
				prop_light.energy = 0.3 + randf() * 0.3
			else:
				prop_light.energy = 0.5

func _on_shadow_draw() -> void:
	if shadow == null:
		return
	var shadow_color := Color(0.0, 0.0, 0.0, 0.35)
	var pts := PackedVector2Array()
	var num_pts := 16
	for i in range(num_pts):
		var angle := i * TAU / float(num_pts)
		var px := cos(angle) * (_shadow_size.x * 0.5)
		var py := sin(angle) * (_shadow_size.y * 0.5) - 2.0
		pts.append(Vector2(px, py))
	shadow.draw_colored_polygon(pts, shadow_color)
