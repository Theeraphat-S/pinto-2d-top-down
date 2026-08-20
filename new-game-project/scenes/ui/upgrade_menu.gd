class_name UpgradeMenu
extends CanvasLayer

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - UPGRADE DRAFT MODAL
# Pauses gameplay and presents 3 distinct roguelite upgrade cards on level up.
# ==============================================================================

signal menu_opened()
signal menu_closed()
signal upgrade_applied(card_id: String)

@export var card_scene: PackedScene = preload("res://scenes/ui/upgrade_card.tscn")

@onready var cards_container: HBoxContainer = $DimOverlay/CenterContainer/VBoxContainer/CardsContainer
@onready var level_label: Label = $DimOverlay/CenterContainer/VBoxContainer/Header/LevelLabel
@onready var sfx_player: AudioStreamPlayer = $LevelUpSFX

var _current_cards: Array[Dictionary] = []
var _card_nodes: Array[Node] = []
var _is_open: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_ensure_nodes()
	hide_menu()
	_connect_signals()

func _ensure_nodes() -> void:
	if not cards_container:
		cards_container = get_node_or_null("DimOverlay/CenterContainer/VBoxContainer/CardsContainer") as HBoxContainer
	if not level_label:
		level_label = get_node_or_null("DimOverlay/CenterContainer/VBoxContainer/Header/LevelLabel") as Label
	if not sfx_player:
		sfx_player = get_node_or_null("LevelUpSFX") as AudioStreamPlayer

func _get_upgrade_catalog() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root.has_node("UpgradeCatalog"):
		return get_tree().root.get_node("UpgradeCatalog")
	return null

func _get_event_bus() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root.has_node("EventBus"):
		return get_tree().root.get_node("EventBus")
	return null

func _connect_signals() -> void:
	var bus = _get_event_bus()
	if bus and not bus.is_connected("level_up_triggered", Callable(self, "_on_level_up_triggered")):
		bus.level_up_triggered.connect(_on_level_up_triggered)

func _on_level_up_triggered(new_level: int, offered_cards: Array) -> void:
	open_menu(new_level, offered_cards)

func open_menu(new_level: int, offered_cards: Array) -> void:
	_ensure_nodes()
	_is_open = true
	_current_cards.clear()
	for c in offered_cards:
		_current_cards.append(c as Dictionary)
		
	if level_label:
		level_label.text = "★ LEVEL %d REACHED! ★" % new_level
		
	_populate_cards()
	
	visible = true
	if is_inside_tree() and get_tree():
		get_tree().paused = true
	menu_opened.emit()
	
	# Focus first card for keyboard / controller accessibility
	if not _card_nodes.is_empty() and _card_nodes[0].has_method("grab_card_focus"):
		_card_nodes[0].grab_card_focus()

func _populate_cards() -> void:
	if not cards_container:
		return
		
	# Clear existing children
	for child in cards_container.get_children():
		child.queue_free()
	_card_nodes.clear()
	
	for i in range(_current_cards.size()):
		var card_data: Dictionary = _current_cards[i]
		var card_instance: Node = null
		if card_scene:
			card_instance = card_scene.instantiate()
		else:
			var card_script = load("res://scenes/ui/upgrade_card.gd")
			if card_script:
				card_instance = card_script.new()
			else:
				card_instance = Control.new()
			
		cards_container.add_child(card_instance)
		if card_instance.has_method("setup"):
			card_instance.setup(card_data, i)
		if card_instance.has_signal("card_selected"):
			card_instance.card_selected.connect(_on_card_selected)
		_card_nodes.append(card_instance)

func _unhandled_input(event: InputEvent) -> void:
	if not _is_open or not visible:
		return
		
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_1 or event.keycode == KEY_KP_1:
			_select_by_index(0)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
			_select_by_index(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
			_select_by_index(2)
			get_viewport().set_input_as_handled()

func _select_by_index(idx: int) -> void:
	if idx >= 0 and idx < _card_nodes.size():
		if _card_nodes[idx].has_method("select_card"):
			_card_nodes[idx].select_card()

func _on_card_selected(card_id: String) -> void:
	if not _is_open:
		return
		
	# Play Level Up SFX
	if sfx_player and is_inside_tree():
		sfx_player.play()
		
	# Apply card stats
	var catalog = _get_upgrade_catalog()
	if catalog:
		catalog.apply_card(card_id)
		
	upgrade_applied.emit(card_id)
	hide_menu()

func hide_menu() -> void:
	_is_open = false
	visible = false
	if is_inside_tree() and get_tree():
		get_tree().paused = false
	menu_closed.emit()
