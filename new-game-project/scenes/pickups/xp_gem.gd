class_name XPGem
extends Area2D

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - XP GEM PICKUP (Milestone M4)
# Tiered XP gems (Small 1 XP, Medium 5 XP, Large 20 XP, Boss 100 XP),
# smooth magnetic acceleration towards player, pickup SFX & GameState XP dispatch.
# ==============================================================================

enum Tier {
	SMALL = 0,
	MEDIUM = 1,
	LARGE = 2,
	BOSS = 3
}

const TEXTURES := {
	Tier.SMALL: preload("res://assets/sprites/pickups/xp_small.png"),
	Tier.MEDIUM: preload("res://assets/sprites/pickups/xp_med.png"),
	Tier.LARGE: preload("res://assets/sprites/pickups/xp_large.png"),
	Tier.BOSS: preload("res://assets/sprites/pickups/xp_large.png")
}

const XP_VALUES := {
	Tier.SMALL: 1,
	Tier.MEDIUM: 5,
	Tier.LARGE: 20,
	Tier.BOSS: 100
}

@export var tier: Tier = Tier.SMALL:
	set(val):
		tier = val
		_apply_tier_properties()

@export var xp_value: int = 1
@export var acceleration: float = 600.0
@export var max_speed: float = 320.0
@export var collection_radius: float = 12.0

var velocity: Vector2 = Vector2.ZERO
var is_attracted: bool = false
var target_player: Node2D = null
var _is_collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var pickup_sfx: AudioStreamPlayer2D = $PickupSFX

# Autoload accessors with safe fallback
var game_state: Node:
	get:
		if is_inside_tree() and get_tree() and get_tree().root.has_node("GameState"):
			return get_tree().root.get_node("GameState")
		return null

var event_bus: Node:
	get:
		if is_inside_tree() and get_tree() and get_tree().root.has_node("EventBus"):
			return get_tree().root.get_node("EventBus")
		return null

func _ready() -> void:
	# Layer 6 (Pickups = 32), Mask Layer 7 (Magnet Area = 64) + Layer 2 (Player = 2) = 66
	collision_layer = 32
	collision_mask = 66
	
	_apply_tier_properties()
	
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func setup(p_tier: Variant, p_pos: Vector2 = Vector2.ZERO) -> void:
	if p_pos != Vector2.ZERO:
		global_position = p_pos
		
	if p_tier is int:
		tier = p_tier as Tier
		xp_value = XP_VALUES.get(tier, 1)
	elif p_tier is String:
		match p_tier.to_lower():
			"small", "green":
				tier = Tier.SMALL
				xp_value = 1
			"medium", "blue", "med":
				tier = Tier.MEDIUM
				xp_value = 5
			"large", "red":
				tier = Tier.LARGE
				xp_value = 20
			"boss":
				tier = Tier.BOSS
				xp_value = 100
			_:
				tier = Tier.SMALL
				xp_value = 1
	_apply_tier_properties()

func _apply_tier_properties() -> void:
	xp_value = XP_VALUES.get(tier, xp_value)
	if sprite:
		if TEXTURES.has(tier) and TEXTURES[tier] != null:
			sprite.texture = TEXTURES[tier]
		if tier == Tier.BOSS:
			sprite.scale = Vector2(1.5, 1.5)
			sprite.modulate = Color(1.0, 0.85, 0.2, 1.0) # Golden glow
		else:
			sprite.scale = Vector2(1.0, 1.0)
			sprite.modulate = Color.WHITE

func _physics_process(delta: float) -> void:
	if _is_collected:
		return
		
	if is_attracted and target_player != null and is_instance_valid(target_player):
		var target_pos := target_player.global_position
		var dist := global_position.distance_to(target_pos)
		
		if dist <= collection_radius:
			collect(target_player)
			return
			
		var dir := (target_pos - global_position).normalized()
		velocity = velocity.move_toward(dir * max_speed, acceleration * delta)
		global_position += velocity * delta
		
		if global_position.distance_to(target_pos) <= collection_radius:
			collect(target_player)

func _on_area_entered(area: Area2D) -> void:
	if _is_collected:
		return
	if area.name == "MagnetArea" or area.is_in_group("player_magnet") or (area.get_parent() and area.get_parent().is_in_group("player")):
		start_attraction(area.get_parent() if area.get_parent() is Node2D else area)

func _on_body_entered(body: Node2D) -> void:
	if _is_collected:
		return
	if body.is_in_group("player"):
		collect(body)

func start_attraction(player_node: Node2D) -> void:
	if player_node != null and is_instance_valid(player_node):
		target_player = player_node
		is_attracted = true

func collect(_collector: Node2D = null) -> void:
	if _is_collected:
		return
	_is_collected = true
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	# Award XP to GameState
	if game_state:
		game_state.add_xp(xp_value)
	elif event_bus:
		event_bus.xp_collected.emit(xp_value, xp_value, 10, 1)
		
	# Play SFX
	_play_pickup_sfx()
	
	queue_free()

func _play_pickup_sfx() -> void:
	# If parent exists, create a detached audio stream so queue_free doesn't clip the audio
	var stream: AudioStream = preload("res://assets/sfx/gem_pickup.wav")
	if stream and is_inside_tree() and get_parent():
		var sfx := AudioStreamPlayer2D.new()
		sfx.stream = stream
		sfx.global_position = global_position
		get_parent().call_deferred("add_child", sfx)
		sfx.tree_entered.connect(func():
			sfx.play()
			sfx.finished.connect(sfx.queue_free)
		)
