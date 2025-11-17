extends Node2D

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var timer: Timer = $Timer2

var current_area: SpawnArea = null
var is_spawning = false
var active_spawns: Array[Spawn_info] = []
var area_enemy_count: Dictionary = {}
var area_time: Dictionary = {}  # Track time spent in each area

func _ready():
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	call_deferred("connect_spawn_areas")

func connect_spawn_areas():
	for area in get_tree().get_nodes_in_group("spawn_areas"):
		if area is SpawnArea:
			area.player_entered_area.connect(_on_player_entered_area)
			area.player_exited_area.connect(_on_player_exited_area)
			area_enemy_count[area] = 0
			area_time[area] = 0

func _on_player_entered_area(area: SpawnArea):
	current_area = area
	is_spawning = true
	
	# Create independent copies of spawn configs
	active_spawns.clear()
	for spawn in area.spawns:
		var spawn_copy = spawn.duplicate()
		active_spawns.append(spawn_copy)
	
	print("Entered ", area.area_name, " (Difficulty: ", area.difficulty_level, ")")
	print("  Spawned: ", area.total_spawned, "/", area.max_total_spawns, 
		  " | Alive: ", area_enemy_count[area], "/", area.max_alive_enemies)

func _on_player_exited_area(area: SpawnArea):
	if current_area == area:
		current_area = null
		is_spawning = false
		active_spawns.clear()
		print("Exited ", area.area_name)

func _on_timer_timeout():
	if not is_spawning or current_area == null:
		return
	
	# Increment area time
	area_time[current_area] += 1
	
	# Update enemy count
	update_enemy_count()
	
	# Check each spawn configuration
	for spawn_info in active_spawns:
		# Check if this spawn is active based on time window
		if not spawn_info.is_active(area_time[current_area]):
			continue
		
		if spawn_info.wave_delay_counter < spawn_info.wave_delay:
			spawn_info.wave_delay_counter += 1
		else:
			spawn_info.wave_delay_counter = 0
			spawn_wave(spawn_info)

func spawn_wave(spawn_info: Spawn_info):
	if spawn_info.enemy == null or current_area == null:
		return
	
	# Check area-specific limits
	if not current_area.can_spawn():
		return
	
	var current_alive = area_enemy_count.get(current_area, 0)
	if current_alive >= current_area.max_alive_enemies:
		return
	
	# Calculate spawn amount
	var remaining_spawns = current_area.max_total_spawns - current_area.total_spawned
	var remaining_alive_slots = current_area.max_alive_enemies - current_alive
	var spawn_amount = min(
		spawn_info.enemies_per_wave,
		remaining_spawns,
		remaining_alive_slots
	)
	
	if spawn_amount <= 0:
		return
	
	var enemy_scene = load(str(spawn_info.enemy.resource_path))
	if enemy_scene == null:
		return
	
	for i in spawn_amount:
		var enemy = enemy_scene.instantiate()
		enemy.global_position = get_random_position()
		enemy.set_meta("spawn_area", current_area)
		enemy.tree_exited.connect(_on_enemy_died.bind(enemy))
		add_child(enemy)
		
		current_area.increment_spawn_count()
		area_enemy_count[current_area] += 1

func _on_enemy_died(enemy: Node):
	if enemy.has_meta("spawn_area"):
		var spawn_area = enemy.get_meta("spawn_area")
		if spawn_area in area_enemy_count:
			area_enemy_count[spawn_area] = max(0, area_enemy_count[spawn_area] - 1)

func update_enemy_count():
	for area in area_enemy_count.keys():
		area_enemy_count[area] = 0
	
	for child in get_children():
		if child != timer and child.is_in_group("enemies"):
			if child.has_meta("spawn_area"):
				var spawn_area = child.get_meta("spawn_area")
				if spawn_area in area_enemy_count:
					area_enemy_count[spawn_area] += 1

func get_random_position():
	if player == null or current_area == null:
		return global_position
	
	var max_attempts = 20
	var attempt = 0
	
	while attempt < max_attempts:
		var vpr = get_viewport_rect().size * randf_range(1.1, 1.4)
		var offset_x = vpr.x / 2
		var offset_y = vpr.y / 2
		
		var top_left = player.global_position + Vector2(-offset_x, -offset_y)
		var top_right = player.global_position + Vector2(offset_x, -offset_y)
		var bottom_left = player.global_position + Vector2(-offset_x, offset_y)
		var bottom_right = player.global_position + Vector2(offset_x, offset_y)
		
		var pos_side = ["up", "down", "right", "left"].pick_random()
		var spawn_pos1: Vector2
		var spawn_pos2: Vector2
		
		match pos_side:
			"up":
				spawn_pos1 = top_left
				spawn_pos2 = top_right
			"down":
				spawn_pos1 = bottom_left
				spawn_pos2 = bottom_right
			"right":
				spawn_pos1 = top_right
				spawn_pos2 = bottom_right
			"left":
				spawn_pos1 = top_left
				spawn_pos2 = bottom_left
		
		var candidate_pos = Vector2(
			randf_range(spawn_pos1.x, spawn_pos2.x),
			randf_range(spawn_pos1.y, spawn_pos2.y)
		)
		
		# Check if position is within the spawn area
		if is_position_in_area(candidate_pos, current_area):
			return candidate_pos
		
		attempt += 1
	
	# Fallback: return player position if no valid position found
	return player.global_position

func is_position_in_area(pos: Vector2, area: SpawnArea) -> bool:
	# Get the CollisionShape2D from the Area2D
	for child in area.get_children():
		if child is CollisionShape2D:
			var shape = child.shape
			var local_pos = pos - area.global_position - child.position
			
			if shape is RectangleShape2D:
				var extents = shape.size / 2
				return abs(local_pos.x) <= extents.x and abs(local_pos.y) <= extents.y
			
			elif shape is CircleShape2D:
				return local_pos.length() <= shape.radius
			
			elif shape is CapsuleShape2D:
				# Simplified capsule check
				return local_pos.length() <= shape.radius + shape.height / 2
			
			elif shape is ConvexPolygonShape2D or shape is ConcavePolygonShape2D:
				# For polygon shapes, use a more complex check
				var points = shape.points if shape is ConvexPolygonShape2D else shape.segments
				return Geometry2D.is_point_in_polygon(local_pos, points)
	
	return false
