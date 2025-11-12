extends CharacterBody2D

@export var player_move_speed = 300.0
@export var max_health = 100
@export var damage_cooldown = 1.0

var current_health = max_health
var damage_timer = 0.0
var last_direction = Vector2.RIGHT
var experience = 0
var experience_level = 1
var collected_experience = 0

@onready var expBar = get_node("%ExperienceBar")
@onready var ExperienceBarText = get_node("%ExperienceBarText")
@onready var upgrade_menu = get_node("/root/Game/UpgradeMenu")
@onready var spell_manager: SpellManager = $SpellManager if has_node("SpellManager") else null

func _ready():
	add_to_group("Player")
	current_health = max_health
	$HurtBox.body_entered.connect(_on_body_entered)
	set_expbar(experience, calculate_experiencecap())
	
	# Connect to upgrade menu if it exists
	if upgrade_menu:
		upgrade_menu.upgrade_selected.connect(_on_upgrade_selected)
	
	# Setup spell manager
	if spell_manager:
		spell_manager.owner_node = self
		# Connect to spell signals for feedback
		spell_manager.spell_unlocked.connect(_on_spell_unlocked)
		spell_manager.spell_upgraded.connect(_on_spell_upgraded)

func _physics_process(delta):
	var horizontal = Input.get_axis("ui_left", "ui_right")
	var vertical = Input.get_axis("ui_up", "ui_down")
	var movement = Vector2(horizontal, vertical)
	
	if movement.length() > 0:
		last_direction = movement.normalized()
		velocity = movement.normalized() * player_move_speed
	else:
		# Smooth deceleration
		var friction = 1000.0
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
	
	damage_timer -= delta
	if damage_timer <= 0:
		var overlapping = $HurtBox.get_overlapping_bodies()
		for body in overlapping:
			if body.is_in_group("enemy"):
				take_damage(10)
				damage_timer = damage_cooldown
				break

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		take_damage(10)

func take_damage(amount):
	current_health -= amount
	print("Player health: ", current_health)
	
	if current_health <= 0:
		die()

func die():
	print("Player died!")
	queue_free()
	get_tree().reload_current_scene()

func _on_grab_area_area_entered(area):
	if area.is_in_group("loot"):
		area.target = self

func _on_collect_area_area_entered(area):
	if area.is_in_group("loot"):
		var gem_exp = area.collect()
		calculate_experience(gem_exp)

func calculate_experience(gem_exp):
	var exp_required = calculate_experiencecap()
	collected_experience += gem_exp
	
	if experience + collected_experience >= exp_required:  # Level up
		collected_experience -= exp_required - experience
		experience_level += 1
		ExperienceBarText.text = str("Level: ", experience_level)
		experience = 0
		exp_required = calculate_experiencecap()
		
		# Show upgrade menu and stop processing experience
		if upgrade_menu:
			upgrade_menu.show_upgrades(spell_manager)
			# Store remaining experience to process after upgrade
			return
		
		calculate_experience(0)
	else:
		experience += collected_experience
		collected_experience = 0
	
	set_expbar(experience, exp_required)

func calculate_experiencecap():
	var exp_cap = experience_level
	if experience_level < 20:
		exp_cap = experience_level * 5
	elif experience_level < 40:
		exp_cap = 95 * (experience_level - 19) * 8
	else:
		exp_cap = 255 + (experience_level - 39) * 12
	
	return exp_cap

func set_expbar(set_value = 1, set_max_value = 100):
	expBar.value = set_value
	expBar.max_value = set_max_value

func _on_upgrade_selected(upgrade_data: Dictionary):
	var upgrade_type = upgrade_data.get("type", "")
	
	# Handle player stat upgrades
	match upgrade_type:
		"movement_speed":
			player_move_speed *= 1.2
			print("Movement speed increased to: ", player_move_speed)
		"max_health":
			max_health += 20
			current_health += 20
			print("Max health increased to: ", max_health)
		"spell_level_up":
			# Handle spell level up
			if spell_manager and upgrade_data.has("spell_name"):
				var spell = spell_manager.get_spell_by_name(upgrade_data.spell_name)
				if spell:
					var target_level = upgrade_data.get("target_level", spell.current_level + 1)
					spell_manager.level_up_spell(spell, target_level)
		"new_spell":
			# Handle new spell acquisition
			if spell_manager and upgrade_data.has("new_spell"):
				var new_spell: SpellBase = upgrade_data.new_spell
				if new_spell:
					spell_manager.equip_spell(new_spell.duplicate(true))
	
	await get_tree().create_timer(0.1).timeout
	if collected_experience > 0:
		var temp_exp = collected_experience
		collected_experience = 0
		calculate_experience(temp_exp)

func _on_spell_unlocked(spell: SpellBase):
	print("🎉 Unlocked new spell: ", spell.spell_name, "!")

func _on_spell_upgraded(spell: SpellBase):
	print("⭐ ", spell.spell_name, " upgraded to level ", spell.current_level, "!")
