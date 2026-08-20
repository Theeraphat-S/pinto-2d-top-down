class_name EnemyProjectile
extends Area2D

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - ENEMY PROJECTILE (Milestone M4)
# Used by CRT Drones and Boss GIGA-NULL.
# Layer 5 (Enemy Projectiles, bitmask 16), Mask Layer 1 (World) + Layer 2 (Player) = 3
# ==============================================================================

@export var speed: float = 200.0
@export var damage: float = 8.0
@export var lifetime: float = 4.0

var direction: Vector2 = Vector2.RIGHT
var _lifetime_timer: float = 0.0
var _is_destroyed: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Autoload accessors with safe fallback
var event_bus: Node:
	get:
		if is_inside_tree() and get_tree() and get_tree().root.has_node("EventBus"):
			return get_tree().root.get_node("EventBus")
		return null

func _ready() -> void:
	# Layer 5 (Enemy Projectiles = 16), Mask Layer 1 (World = 1) + Layer 2 (Player = 2) = 3
	collision_layer = 16
	collision_mask = 3
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
		
	rotation = direction.angle()

func init(pos: Vector2, dir: Vector2, p_damage: float = -1.0, p_speed: float = -1.0) -> void:
	global_position = pos
	direction = dir.normalized() if dir.length_squared() > 0.0 else Vector2.RIGHT
	rotation = direction.angle()
	
	if p_damage > 0.0:
		damage = p_damage
	if p_speed > 0.0:
		speed = p_speed

func _physics_process(delta: float) -> void:
	if _is_destroyed:
		return
		
	global_position += direction * speed * delta
	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		_destroy()

func _on_body_entered(body: Node2D) -> void:
	_handle_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_handle_hit(area)

func _handle_hit(target: Node) -> void:
	if _is_destroyed or target == null or not is_instance_valid(target) or target.is_queued_for_deletion():
		return
		
	# Ignore other enemies
	if target.is_in_group("enemies") or (target.get_parent() and target.get_parent().is_in_group("enemies")):
		return
		
	# Player hit
	var player_node: Node = target
	if not player_node.has_method("take_damage") and target.get_parent() and target.get_parent().has_method("take_damage"):
		player_node = target.get_parent()
		
	if player_node.is_in_group("player") or player_node.name == "Player" or player_node is CharacterBody2D:
		if player_node.has_method("take_damage"):
			player_node.take_damage(damage)
			_play_hit_sfx()
			_destroy()
			return
			
	# Obstacle / Wall hit
	if target is TileMapLayer or target is StaticBody2D:
		_destroy()

func _play_hit_sfx() -> void:
	var stream: AudioStream = preload("res://assets/sfx/hit.wav")
	if stream and is_inside_tree() and get_parent():
		var sfx := AudioStreamPlayer2D.new()
		sfx.stream = stream
		sfx.global_position = global_position
		get_parent().add_child(sfx)
		sfx.play()
		sfx.finished.connect(sfx.queue_free)

func _destroy() -> void:
	if _is_destroyed:
		return
	_is_destroyed = true
	queue_free()
