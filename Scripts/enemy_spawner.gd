extends Node2D

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var timer: Timer = $Timer

var time = 0
var current_area: SpawnArea = null
var is_spawning = false
var active_spawns: Array[Spawn_info] = []  # Store duplicated spawns

func _ready():
	print("Enemy Spawner ready")
	
	if timer == null:
		print("ERROR: Timer node not found!")
		return
	
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)
	
	timer.start()
	call_deferred("connect_spawn_areas")

func connect_spawn_areas():
	var areas = get_tree().get_nodes_in_group("spawn_areas")
	print("Found ", areas.size(), " spawn areas")
	
	for area in areas:
		if area is SpawnArea:
			area.player_entered_area.connect(_on_player_entered_area)
			area.player_exited_area.connect(_on_player_exited_area)
			print("Connected to area: ", area.area_name)

func _on_player_entered_area(area: SpawnArea):
	print("Activating spawner for area: ", area.area_name)
	current_area = area
	is_spawning = true
	time = 0
	
	# Create DUPLICATES of spawn_info so each area has independent counters
	active_spawns.clear()
	for spawn in area.spawns:
		var spawn_copy = spawn.duplicate()
		spawn_copy.spawn_delay_counter = 0
		active_spawns.append(spawn_copy)
	
	print("Loaded ", active_spawns.size(), " spawn configurations")

func _on_player_exited_area(area: SpawnArea):
	if current_area == area:
		print("Deactivating spawner for area: ", area.area_name)
		current_area = null
		is_spawning = false
		time = 0
		active_spawns.clear()
		clear_enemies()

func _on_timer_timeout():
	if not is_spawning or current_area == null:
		return
	
	time += 1
	
	for spawn_info in active_spawns:
		if spawn_info.spawn_delay_counter < spawn_info.enemy_spawn_delay:
			spawn_info.spawn_delay_counter += 1
		else:
			spawn_info.spawn_delay_counter = 0
			spawn_enemies(spawn_info)

func spawn_enemies(spawn_info: Spawn_info):
	if spawn_info.enemy == null:
		print("ERROR: No enemy resource set in spawn_info")
		return
	
	var new_enemy = load(str(spawn_info.enemy.resource_path))
	if new_enemy == null:
		print("ERROR: Could not load enemy from path: ", spawn_info.enemy.resource_path)
		return
	
	for i in spawn_info.enemy_num:
		var enemy_spawn = new_enemy.instantiate()
		enemy_spawn.global_position = get_random_position()
		add_child(enemy_spawn)
	
	print("Spawned ", spawn_info.enemy_num, " enemies at ", current_area.area_name)

func clear_enemies():
	for child in get_children():
		if child != timer and (child.is_in_group("enemies") or child.has_method("take_damage")):
			child.queue_free()

func get_random_position():
	if player == null:
		return global_position
	
	var vpr = get_viewport_rect().size * randf_range(1.1, 1.4)
	var top_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y - vpr.y/2)
	var top_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y - vpr.y/2)
	var bottom_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y + vpr.y/2)
	var bottom_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y + vpr.y/2)
	
	var pos_side = ["up", "down", "right", "left"].pick_random()
	var spawn_pos1 = Vector2.ZERO
	var spawn_pos2 = Vector2.ZERO
	
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
	
	var x_spawn = randf_range(spawn_pos1.x, spawn_pos2.x)
	var y_spawn = randf_range(spawn_pos1.y, spawn_pos2.y)
	return Vector2(x_spawn, y_spawn)
