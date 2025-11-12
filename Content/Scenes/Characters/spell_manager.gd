extends Node
class_name SpellManager

signal spell_upgraded(spell: SpellBase)
signal spell_unlocked(spell: SpellBase)

@export var owner_node: CharacterBody2D
@export var starting_spells: Array[SpellBase] = []

var equipped_spells: Dictionary = {}  # spell_id: {spell: SpellBase, timer: float}
var spell_id_counter: int = 0

func _ready():
	# Equip starting spells
	for spell in starting_spells:
		if spell:
			equip_spell(spell.duplicate(true))

func _physics_process(delta):
	if not owner_node:
		return
	
	# Update all spell timers and fire when ready
	for spell_id in equipped_spells.keys():
		var spell_data = equipped_spells[spell_id]
		spell_data.timer -= delta
		
		if spell_data.timer <= 0:
			fire_spell(spell_data.spell)
			spell_data.timer = spell_data.spell.get_fire_rate()

func equip_spell(spell: SpellBase) -> int:
	var spell_id = spell_id_counter
	spell_id_counter += 1
	
	equipped_spells[spell_id] = {
		"spell": spell,
		"timer": 0.0  # Fire immediately on equip
	}
	
	print("Equipped spell: ", spell.spell_name, " (Level ", spell.current_level, ")")
	spell_unlocked.emit(spell)
	return spell_id

func unequip_spell(spell_id: int):
	if equipped_spells.has(spell_id):
		var spell_name = equipped_spells[spell_id].spell.spell_name
		equipped_spells.erase(spell_id)
		print("Unequipped spell: ", spell_name)

func get_spell_by_name(spell_name: String) -> SpellBase:
	for spell_data in equipped_spells.values():
		if spell_data.spell.spell_name == spell_name:
			return spell_data.spell
	return null

func has_spell(spell_name: String) -> bool:
	return get_spell_by_name(spell_name) != null

func fire_spell(spell: SpellBase):
	if not spell.projectile_scene or not owner_node:
		return
	
	var count = spell.get_projectile_count()
	var pattern = spell.spread_pattern
	
	for i in range(count):
		var projectile = spell.projectile_scene.instantiate()
		
		# Calculate direction based on pattern
		var direction = calculate_direction(pattern, i, count)
		
		# Setup projectile
		if projectile.has_method("setup"):
			projectile.setup(
				direction,
				spell.get_speed(),
				spell.get_lifetime(),
				spell.get_damage(),
				spell.get_pierce()
			)
		else:
			# Fallback for basic projectiles
			projectile.direction = direction
			if projectile.has("speed"):
				projectile.speed = spell.get_speed()
			if projectile.has("damage"):
				projectile.damage = spell.get_damage()
			if projectile.has("lifetime"):
				projectile.lifetime = spell.get_lifetime()
		
		projectile.position = owner_node.global_position
		owner_node.get_parent().add_child(projectile)

func calculate_direction(pattern: SpellBase.SpreadPattern, index: int, total: int) -> Vector2:
	match pattern:
		SpellBase.SpreadPattern.RANDOM:
			var random_angle = randf() * TAU
			return Vector2(cos(random_angle), sin(random_angle))
		
		SpellBase.SpreadPattern.CIRCLE:
			var angle = (TAU / total) * index
			return Vector2(cos(angle), sin(angle))
		
		SpellBase.SpreadPattern.AIMED:
			var nearest_enemy = find_nearest_enemy()
			if nearest_enemy:
				return (nearest_enemy.global_position - owner_node.global_position).normalized()
			return Vector2.RIGHT
		
		SpellBase.SpreadPattern.CONE:
			var last_dir = owner_node.last_direction if owner_node.has("last_direction") else Vector2.RIGHT
			var base_angle = last_dir.angle()
			var cone_spread = PI / 4  # 45 degree cone
			var offset = (cone_spread / max(total - 1, 1)) * index - (cone_spread / 2)
			var final_angle = base_angle + offset
			return Vector2(cos(final_angle), sin(final_angle))
		
		SpellBase.SpreadPattern.SPIRAL:
			var time_offset = Time.get_ticks_msec() / 1000.0
			var angle = (TAU / total) * index + time_offset
			return Vector2(cos(angle), sin(angle))
	
	return Vector2.RIGHT

func find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest: Node2D = null
	var nearest_distance = INF
	
	for enemy in enemies:
		if enemy is Node2D:
			var distance = owner_node.global_position.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = enemy
	
	return nearest

func level_up_spell(spell: SpellBase, target_level: int):
	"""Level up a spell with predefined upgrades per level"""
	if spell.current_level >= target_level:
		return  # Already at or above target level
	
	var level = target_level
	
	match level:
		2:
			# Level 2: +20% Damage
			spell.upgrade_damage(1.2)
		3:
			# Level 3: +1 Projectile
			spell.upgrade_count(1)
		4:
			# Level 4: +20% Fire Rate (shoots faster)
			spell.upgrade_fire_rate(0.8)
		5:
			# Level 5: +1 Pierce and +20% Damage
			spell.upgrade_pierce(1)
			spell.upgrade_damage(1.2)
	
	spell.current_level = level
	spell_upgraded.emit(spell)
	
	print("Leveled up ", spell.spell_name, " to level ", spell.current_level)
	print_spell_stats(spell)

func print_spell_stats(spell: SpellBase):
	"""Debug function to show current spell stats"""
	print("  - Damage: ", spell.get_damage())
	print("  - Fire Rate: ", spell.get_fire_rate())
	print("  - Projectiles: ", spell.get_projectile_count())
	print("  - Pierce: ", spell.get_pierce())

func get_all_spells() -> Array[SpellBase]:
	var spells: Array[SpellBase] = []
	for spell_data in equipped_spells.values():
		spells.append(spell_data.spell)
	return spells
