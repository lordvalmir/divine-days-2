extends CanvasLayer

signal upgrade_selected(upgrade_data: Dictionary)

@onready var upgrades_container = $ColorRect/PanelContainer/VBoxContainer/HBoxContainer

# Preload spell resources (you'll create these in the editor)
@export var available_spell_resources: Array[SpellBase] = []

var spell_manager: SpellManager = null

# Define player stat upgrades
var player_upgrades = [
	{
		"name": "Increase Speed",
		"description": "+20% Movement Speed",
		"icon": null,
		"type": "movement_speed"
	},
	{
		"name": "Increase Max Health",
		"description": "+20 Max HP and heal",
		"icon": null,
		"type": "max_health"
	}
]

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func show_upgrades(current_spell_manager: SpellManager = null):
	spell_manager = current_spell_manager
	
	# Clear existing buttons
	for child in upgrades_container.get_children():
		child.queue_free()
	
	# Build available upgrades list
	var possible_upgrades = []
	
	# Add player stat upgrades
	possible_upgrades.append_array(player_upgrades)
	
	# Add spell upgrades for equipped spells
	if spell_manager:
		for spell in spell_manager.get_all_spells():
			possible_upgrades.append_array(get_spell_upgrades(spell))
		
		# Add new spell options if player doesn't have them yet
		for spell_resource in available_spell_resources:
			if not spell_manager.has_spell(spell_resource.spell_name):
				possible_upgrades.append({
					"name": "Unlock: " + spell_resource.spell_name,
					"description": "Acquire new spell",
					"icon": spell_resource.spell_icon,
					"type": "new_spell",
					"new_spell": spell_resource
				})
	
	# Select random upgrades
	possible_upgrades.shuffle()
	var selected_upgrades = possible_upgrades.slice(0, min(3, possible_upgrades.size()))
	
	# Create buttons for each upgrade
	for upgrade in selected_upgrades:
		var button = create_upgrade_button(upgrade)
		upgrades_container.add_child(button)
	
	show()
	get_tree().paused = true

func get_spell_upgrades(spell: SpellBase) -> Array:
	var upgrades = []
	
	upgrades.append({
		"name": spell.spell_name + ": Damage",
		"description": "+20% Damage",
		"icon": spell.spell_icon,
		"type": "spell_upgrade",
		"spell_name": spell.spell_name,
		"upgrade_type": "damage"
	})
	
	upgrades.append({
		"name": spell.spell_name + ": Fire Rate",
		"description": "+15% Attack Speed",
		"icon": spell.spell_icon,
		"type": "spell_upgrade",
		"spell_name": spell.spell_name,
		"upgrade_type": "fire_rate"
	})
	
	upgrades.append({
		"name": spell.spell_name + ": Count",
		"description": "+1 Projectile",
		"icon": spell.spell_icon,
		"type": "spell_upgrade",
		"spell_name": spell.spell_name,
		"upgrade_type": "count"
	})
	
	# Only offer pierce if spell doesn't have too much already
	if spell.get_pierce() < 5:
		upgrades.append({
			"name": spell.spell_name + ": Pierce",
			"description": "+1 Pierce",
			"icon": spell.spell_icon,
			"type": "spell_upgrade",
			"spell_name": spell.spell_name,
			"upgrade_type": "pierce"
		})
	
	return upgrades

func create_upgrade_button(upgrade: Dictionary) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(200, 100)
	
	# Create button text
	var button_text = upgrade.name + "\n" + upgrade.description
	button.text = button_text
	
	# TODO: Add icon support if you want
	# if upgrade.has("icon") and upgrade.icon:
	#     var texture_rect = TextureRect.new()
	#     texture_rect.texture = upgrade.icon
	#     button.add_child(texture_rect)
	
	button.pressed.connect(_on_upgrade_button_pressed.bind(upgrade))
	return button

func _on_upgrade_button_pressed(upgrade: Dictionary):
	upgrade_selected.emit(upgrade)
	hide()
	get_tree().paused = false
