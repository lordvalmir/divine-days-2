# UpgradeMenu.gd
extends CanvasLayer

signal upgrade_selected(upgrade_type)

@onready var upgrades_container = $ColorRect/PanelContainer/VBoxContainer/HBoxContainer

# Define possible upgrades
var available_upgrades = [
	{
		"name": "Increase Fireball Count",
		"description": "+1 Fireball",
		"type": "fireball_count"
	},
	{
		"name": "Increase Fire Rate",
		"description": "Shoot 20% faster",
		"type": "fire_rate"
	},
	{
		"name": "Increase Speed",
		"description": "+20% Movement Speed",
		"type": "movement_speed"
	},
	{
		"name": "Increase Max Health",
		"description": "+20 Max HP and heal",
		"type": "max_health"
	}
]

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func show_upgrades():
	# Clear existing buttons
	for child in upgrades_container.get_children():
		child.queue_free()
	
	# Select 3 random upgrades
	var shuffled_upgrades = available_upgrades.duplicate()
	shuffled_upgrades.shuffle()
	var selected_upgrades = shuffled_upgrades.slice(0, 3)
	
	# Create buttons for each upgrade
	for upgrade in selected_upgrades:
		var button = create_upgrade_button(upgrade)
		upgrades_container.add_child(button)
	
	show()
	get_tree().paused = true

func create_upgrade_button(upgrade: Dictionary) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(200, 100)
	button.text = upgrade.name + "\n" + upgrade.description
	button.pressed.connect(_on_upgrade_button_pressed.bind(upgrade.type))
	return button

func _on_upgrade_button_pressed(upgrade_type: String):
	upgrade_selected.emit(upgrade_type)
	hide()
	get_tree().paused = false
