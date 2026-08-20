class_name UpgradeCard
extends PanelContainer

# ==============================================================================
# PINTO 2D TOP-DOWN SURVIVAL ARENA - UPGRADE CARD UI COMPONENT
# Displays upgrade title, icon, rarity border, rank stars, and description.
# ==============================================================================

signal card_selected(card_id: String)

var card_id: String = ""
var card_data: Dictionary = {}
var slot_index: int = 0

const RARITY_COLORS: Dictionary = {
	0: Color(0.75, 0.80, 0.85, 1.0), # COMMON: Silver / Slate
	1: Color(0.15, 0.80, 0.95, 1.0), # RARE: Cyan
	2: Color(0.75, 0.35, 0.95, 1.0), # EPIC: Purple
	3: Color(1.00, 0.82, 0.15, 1.0)  # LEGENDARY: Gold
}

const RARITY_NAMES: Dictionary = {
	0: "COMMON",
	1: "RARE",
	2: "EPIC",
	3: "LEGENDARY"
}

@onready var bg_rect: TextureRect = $CardBackground
@onready var border_rect: ReferenceRect = $RarityBorder
@onready var icon_rect: TextureRect = $MarginContainer/VBoxContainer/IconContainer/Icon
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var rarity_label: Label = $MarginContainer/VBoxContainer/RarityLabel
@onready var rank_label: Label = $MarginContainer/VBoxContainer/RankLabel
@onready var desc_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var key_badge: Label = $MarginContainer/VBoxContainer/KeyBadge
@onready var select_button: Button = $SelectButton

func _ready() -> void:
	_ensure_nodes()
	if select_button:
		if not select_button.pressed.is_connected(Callable(self, "_on_select_button_pressed")):
			select_button.pressed.connect(_on_select_button_pressed)
		if not select_button.mouse_entered.is_connected(Callable(self, "_on_mouse_entered")):
			select_button.mouse_entered.connect(_on_mouse_entered)
		if not select_button.mouse_exited.is_connected(Callable(self, "_on_mouse_exited")):
			select_button.mouse_exited.connect(_on_mouse_exited)
		if not select_button.focus_entered.is_connected(Callable(self, "_on_focus_entered")):
			select_button.focus_entered.connect(_on_focus_entered)
		if not select_button.focus_exited.is_connected(Callable(self, "_on_focus_exited")):
			select_button.focus_exited.connect(_on_focus_exited)

func _ensure_nodes() -> void:
	if not bg_rect:
		bg_rect = get_node_or_null("CardBackground") as TextureRect
	if not border_rect:
		border_rect = get_node_or_null("RarityBorder") as ReferenceRect
	if not icon_rect:
		icon_rect = get_node_or_null("MarginContainer/VBoxContainer/IconContainer/Icon") as TextureRect
	if not title_label:
		title_label = get_node_or_null("MarginContainer/VBoxContainer/TitleLabel") as Label
	if not rarity_label:
		rarity_label = get_node_or_null("MarginContainer/VBoxContainer/RarityLabel") as Label
	if not rank_label:
		rank_label = get_node_or_null("MarginContainer/VBoxContainer/RankLabel") as Label
	if not desc_label:
		desc_label = get_node_or_null("MarginContainer/VBoxContainer/DescriptionLabel") as Label
	if not key_badge:
		key_badge = get_node_or_null("MarginContainer/VBoxContainer/KeyBadge") as Label
	if not select_button:
		select_button = get_node_or_null("SelectButton") as Button

func setup(data: Dictionary, index: int = 0) -> void:
	card_data = data.duplicate()
	card_id = data.get("id", "")
	slot_index = index
	
	_ensure_nodes()
	_apply_visuals()

func _apply_visuals() -> void:
	var title: String = card_data.get("title", "Upgrade")
	var desc: String = card_data.get("description", "")
	var rarity: int = int(card_data.get("rarity", 0))
	var icon_path: String = card_data.get("icon", "")
	var max_rank: int = int(card_data.get("max_rank", 1))
	var cur_rank: int = int(card_data.get("current_rank", 0))
	var next_rank: int = int(card_data.get("next_rank", cur_rank + 1))
	
	if title_label:
		title_label.text = title
	if desc_label:
		desc_label.text = desc
	
	# Rarity styling
	var rarity_color: Color = RARITY_COLORS.get(rarity, Color.WHITE)
	var rarity_name: String = RARITY_NAMES.get(rarity, "COMMON")
	if rarity_label:
		rarity_label.text = "[ " + rarity_name + " ]"
		rarity_label.modulate = rarity_color
	
	if border_rect:
		border_rect.border_color = rarity_color
		
	# Rank stars formatting (e.g. ★★★☆☆)
	var stars: String = ""
	for i in range(max_rank):
		if i < next_rank:
			stars += "★"
		else:
			stars += "☆"
	if rank_label:
		rank_label.text = "%s (Rank %d/%d)" % [stars, next_rank, max_rank]
		rank_label.modulate = Color(1.0, 0.9, 0.4, 1.0)
	
	# Key shortcut badge
	if key_badge:
		key_badge.text = "[ Press %d ]" % (slot_index + 1)
		
	# Icon texture loading
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		var icon_tex = load(icon_path)
		if icon_tex and icon_rect:
			icon_rect.texture = icon_tex
	elif icon_rect:
		var fallback_path = "res://assets/ui/icons/icon_damage.png"
		if ResourceLoader.exists(fallback_path):
			icon_rect.texture = load(fallback_path)

func grab_card_focus() -> void:
	_ensure_nodes()
	if select_button and is_inside_tree():
		select_button.grab_focus()

func select_card() -> void:
	if not card_id.is_empty():
		card_selected.emit(card_id)

func _on_select_button_pressed() -> void:
	select_card()

func _on_mouse_entered() -> void:
	_highlight_card(true)

func _on_mouse_exited() -> void:
	_highlight_card(false)

func _on_focus_entered() -> void:
	_highlight_card(true)

func _on_focus_exited() -> void:
	_highlight_card(false)

func _highlight_card(active: bool) -> void:
	if active:
		modulate = Color(1.15, 1.15, 1.2, 1.0)
		scale = Vector2(1.04, 1.04)
		z_index = 2
	else:
		modulate = Color.WHITE
		scale = Vector2(1.0, 1.0)
		z_index = 0
