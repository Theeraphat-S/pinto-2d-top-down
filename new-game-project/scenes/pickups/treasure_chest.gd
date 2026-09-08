class_name TreasureChest
extends Area2D

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - TREASURE CHEST PICKUP
# Dropped exclusively by Elite Enemies. Awards free card upgrade, +20 HP, +500 pts.
# ==============================================================================

const DAMAGE_NUMBER_SCENE = preload("res://scenes/ui/damage_number.tscn")

var _is_collected: bool = false

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

var upgrade_catalog: Node:
	get:
		if is_inside_tree() and get_tree() and get_tree().root.has_node("UpgradeCatalog"):
			return get_tree().root.get_node("UpgradeCatalog")
		return null

var audio_manager: Node:
	get:
		if is_inside_tree() and get_tree() and get_tree().root.has_node("AudioManager"):
			return get_tree().root.get_node("AudioManager")
		return null

func _ready() -> void:
	z_index = 15
	# Layer 6 (Pickups = 32), Mask Layer 2 (Player = 2)
	collision_layer = 32
	collision_mask = 2
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		
	_start_pulse_animation()

func _start_pulse_animation() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.45).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if _is_collected:
		return
	if body.is_in_group("player") or body.name == "Player":
		collect_treasure()

func collect_treasure() -> void:
	if _is_collected:
		return
	_is_collected = true
	
	# Disable collision immediately
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	# 1. Audio & Feedback
	if audio_manager and audio_manager.has_method("play_chest"):
		audio_manager.play_chest()
	if event_bus:
		event_bus.screen_shake_requested.emit(0.35, 0.25)
		
	# 2. Heal & Score
	if game_state:
		game_state.heal(20.0)
		game_state.add_score(500)
		
	# 3. Draft and Apply 1 Free Upgrade
	var granted_card_id := ""
	if upgrade_catalog and upgrade_catalog.has_method("get_random_upgrade_cards"):
		var cards: Array = upgrade_catalog.get_random_upgrade_cards(1)
		if not cards.is_empty():
			var chosen_card = cards[0]
			granted_card_id = chosen_card.get("id", "")
			if upgrade_catalog.has_method("apply_card") and granted_card_id != "":
				upgrade_catalog.apply_card(granted_card_id)
				
	# 4. Notify EventBus
	if event_bus:
		event_bus.treasure_chest_opened.emit({
			"score": 500,
			"heal": 20.0,
			"card": granted_card_id
		})
		
	# 5. Spawn Popup Number / Text
	_spawn_popup()
	
	queue_free()

func _spawn_popup() -> void:
	var container: Node = get_parent()
	if container == null and is_inside_tree() and get_tree():
		container = get_tree().root
	if container and DAMAGE_NUMBER_SCENE:
		var popup: Node = DAMAGE_NUMBER_SCENE.instantiate()
		if popup:
			if popup is Node2D:
				popup.global_position = global_position + Vector2(0, -16)
			if popup.has_method("setup"):
				popup.setup(500, true, global_position + Vector2(0, -16))
				var lbl = popup.get_node_or_null("Label")
				if lbl and lbl is Label:
					lbl.text = "+500"
			if container.is_inside_tree():
				container.call_deferred("add_child", popup)
			else:
				container.add_child(popup)
