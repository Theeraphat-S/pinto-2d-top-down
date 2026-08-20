class_name Projectile
extends Area2D

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - PLAYER PROJECTILE
# Linear ballistics, enemy collision handling, pierce tracking, crit calculation.
# ==============================================================================

@export var speed: float = 380.0
@export var damage: float = 20.0
@export var pierce: int = 1
@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 1.5
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var hit_enemies: Array[Node] = []
var _lifetime_timer: float = 0.0
var _is_destroyed: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_sfx: AudioStreamPlayer2D = $HitSFX

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
	# Layer 4 (Player Projectiles = 8), Mask Layer 1 (World = 1) + Layer 3 (Enemies = 4) = 5
	collision_layer = 8
	collision_mask = 5
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
		
	rotation = direction.angle()

func init(pos: Vector2, dir: Vector2, p_dmg: float = -1.0, p_spd: float = -1.0, p_pierce: int = -1, p_crit_chance: float = -1.0, p_crit_mult: float = -1.0) -> void:
	global_position = pos
	direction = dir.normalized() if dir.length_squared() > 0.0 else Vector2.RIGHT
	rotation = direction.angle()
	
	if p_dmg >= 0.0:
		damage = p_dmg
	elif game_state:
		damage = game_state.attack_damage
		
	if p_spd >= 0.0:
		speed = p_spd
	elif game_state:
		speed = game_state.projectile_speed
		
	if p_pierce >= 0:
		pierce = p_pierce
	elif game_state:
		pierce = game_state.projectile_pierce
		
	if p_crit_chance >= 0.0:
		crit_chance = p_crit_chance
	elif game_state:
		crit_chance = game_state.crit_chance
		
	if p_crit_mult >= 0.0:
		crit_multiplier = p_crit_mult
	elif game_state:
		crit_multiplier = game_state.crit_multiplier

func _physics_process(delta: float) -> void:
	if _is_destroyed:
		return
		
	global_position += direction * speed * delta
	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		_destroy()

func _on_body_entered(body: Node2D) -> void:
	_handle_target_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_handle_target_hit(area)

func _handle_target_hit(target: Node) -> void:
	if _is_destroyed or target == null or not is_instance_valid(target) or target.is_queued_for_deletion():
		return
		
	# Ignore player or player hurtbox
	if target.is_in_group("player") or (target.get_parent() and target.get_parent().is_in_group("player")):
		return
		
	# Resolve target or target's parent if it's a hurtbox
	var enemy_node: Node = target
	if not enemy_node.has_method("take_damage"):
		if target.get_parent() and target.get_parent().has_method("take_damage"):
			enemy_node = target.get_parent()
			
	if enemy_node.has_method("take_damage"):
		if enemy_node in hit_enemies or target in hit_enemies:
			return
			
		hit_enemies.append(target)
		if enemy_node != target:
			hit_enemies.append(enemy_node)
			
		var is_crit: bool = (randf() < crit_chance)
		var final_dmg: float = damage * (crit_multiplier if is_crit else 1.0)
		
		# Apply damage to enemy
		enemy_node.take_damage(final_dmg, is_crit)
		
		# Global event
		if event_bus:
			if enemy_node is Node2D:
				event_bus.enemy_hit.emit(enemy_node, final_dmg)
				
		_play_hit_sfx()
		
		pierce -= 1
		if pierce <= 0:
			_destroy()
	elif target is TileMapLayer or target is StaticBody2D:
		# Projectile collided with obstacle / wall
		_destroy()

func _play_hit_sfx() -> void:
	if hit_sfx and hit_sfx.stream and is_inside_tree():
		hit_sfx.play()

func _destroy() -> void:
	if _is_destroyed:
		return
	_is_destroyed = true
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	queue_free()
