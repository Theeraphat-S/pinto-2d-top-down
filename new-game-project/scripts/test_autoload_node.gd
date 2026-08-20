extends Node

func _ready() -> void:
	print("--- Testing Autoloads in Node ---")
	print("EventBus node: ", get_node_or_null("/root/EventBus"))
	print("GameState node: ", get_node_or_null("/root/GameState"))
	print("SaveManager node: ", get_node_or_null("/root/SaveManager"))
	print("UpgradeCatalog node: ", get_node_or_null("/root/UpgradeCatalog"))
	get_tree().quit(0)
