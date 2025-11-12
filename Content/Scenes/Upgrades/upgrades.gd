extends CanvasLayer

signal upgrade_selected(upgrade_data: Dictionary)

@onready var upgrades_container = $ColorRect/PanelContainer/VBoxContainer/HBoxContainer

# Available spell resources that can be unlocked
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
	
	# Add player stat upgrades (always available)
	possible_upgrades.append_array(player_upgrades)
	
	if spell_manager:
		# Get all equipped spells and add upgrade options
		for spell in spell_manager.get_all_spells():
			# Only offer upgrade if spell is not max level
			if spell.current_level < 5:
				possible_upgrades.append(create_spell_level_upgrade(spell))
		
		# Add new spell unlock options (for spells player doesn't have)
		for spell_resource in available_spell_resources:
			if not spell_manager.has_spell(spell_resource.spell_name):
				possible_upgrades.append({
					"name": "Unlock: " + spell_resource.spell_name,
					"description": get_spell_description(spell_resource),
					"icon": spell_resource.spell_icon,
					"type": "new_spell",
					"new_spell": spell_resource
				})
	
	# Select 3 random upgrades (or less if not enough available)
	possible_upgrades.shuffle()
	var num_upgrades = min(3, possible_upgrades.size())
	var selected_upgrades = possible_upgrades.slice(0, num_upgrades)
	
	# Create buttons for each upgrade
	for upgrade in selected_upgrades:
		var button = create_upgrade_button(upgrade)
		upgrades_container.add_child(button)
	
	show()
	get_tree().paused = true

func create_spell_level_upgrade(spell: SpellBase) -> Dictionary:
	var next_level = spell.current_level + 1
	var description = get_level_upgrade_description(spell, next_level)
	
	return {
		"name": spell.spell_name + " Level " + str(next_level),
		"description": description,
		"icon": spell.spell_icon,
		"type": "spell_level_up",
		"spell_name": spell.spell_name,
		"target_level": next_level
	}

func get_level_upgrade_description(spell: SpellBase, next_level: int) -> String:
	# Define what each level does for each spell
	match next_level:
		2:
			return "+20% Damage"
		3:
			return "+1 Projectile"
		4:
			return "+20% Fire Rate"
		5:
			return "+1 Pierce & +20% Damage"
	return "Upgrade"

func get_spell_description(spell: SpellBase) -> String:
	# Create a description based on spell properties
	var desc = ""
	
	match spell.spread_pattern:
		SpellBase.SpreadPattern.RANDOM:
			desc = "Shoots in random directions"
		SpellBase.SpreadPattern.AIMED:
			desc = "Targets nearest enemy"
		SpellBase.SpreadPattern.CIRCLE:
			desc = "Ring of projectiles"
		SpellBase.SpreadPattern.CONE:
			desc = "Cone in movement direction"
		SpellBase.SpreadPattern.SPIRAL:
			desc = "Rotating spiral pattern"
	
	desc += " | DMG: " + str(spell.base_damage)
	
	return desc

func create_upgrade_button(upgrade: Dictionary) -> Control:
	# Create a more detailed button with better layout
	var button_container = PanelContainer.new()
	button_container.custom_minimum_size = Vector2(220, 120)
	
	# Add a button inside the panel
	var button = Button.new()
	button_container.add_child(button)
	
	# Create VBox for layout
	var vbox = VBoxContainer.new()
	button.add_child(vbox)
	
	# Title label
	var title = Label.new()
	title.text = upgrade.name
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Description label
	var desc = Label.new()
	desc.text = upgrade.description
	desc.add_theme_font_size_override("font_size", 12)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 200
	vbox.add_child(desc)
	
	# Add level indicator if it's a spell upgrade
	if upgrade.get("type") == "spell_level_up":
		var level_label = Label.new()
		level_label.text = "⭐".repeat(upgrade.get("target_level", 1))
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(level_label)
	
	button.pressed.connect(_on_upgrade_button_pressed.bind(upgrade))
	
	return button_container

func _on_upgrade_button_pressed(upgrade: Dictionary):
	upgrade_selected.emit(upgrade)
	hide()
	get_tree().paused = false
