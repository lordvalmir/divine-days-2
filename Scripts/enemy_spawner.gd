extends Node2D

@export var max_enemies: int = 50  # Maximum enemies allowed at once

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var timer: Timer = $Timer2

var current_area: SpawnArea = null
var is_spawning = false
var active_spawns: Array[Spawn_info] = []
var enemy_count: int = 0

func _ready():
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	call_deferred("connect_spawn_areas")

func connect_spawn_areas():
	for area in get_tree().get_nodes_in_group("spawn_areas"):
		if area is SpawnArea:
			area.player_entered_area.connect(_on_player_entered_area)
			area.player_exited_area.connect(_on_player_exited_area)

func _on_player_entered_area(area: SpawnArea):
	current_area = area
	is_spawning = true
	
	# Create independent copies of spawn configs
	active_spawns.clear()
	for spawn in area.spawns:
		var spawn_copy = spawn.duplicate()
		spawn_copy.wave_delay_counter = 0
		active_spawns.append(spawn_copy)

func _on_player_exited_area(area: SpawnArea):
	if current_area == area:
		current_area = null
		is_spawning = false
		active_spawns.clear()
		clear_enemies()

func _on_timer_timeout():
	if not is_spawning or current_area == null:
		return
	
	# Update enemy count
	update_enemy_count()
	
	# Check each spawn configuration
	for spawn_info in active_spawns:
		if spawn_info.wave_delay_counter < spawn_info.wave_delay:
			spawn_info.wave_delay_counter += 1
		else:
			# Reset counter and spawn wave
			spawn_info.wave_delay_counter = 0
			spawn_wave(spawn_info)

func spawn_wave(spawn_info: Spawn_info):
	if spawn_info.enemy == null:
		return
	
	# Don't spawn if at max capacity
	if enemy_count >= max_enemies:
		print("Max enemies reached (", max_enemies, "), waiting...")
		return
	
	# Calculate how many we can actually spawn
	var spawn_amount = min(spawn_info.enemies_per_wave, max_enemies - enemy_count)
	
	var enemy_scene = load(str(spawn_info.enemy.resource_path))
	if enemy_scene == null:
		return
	
	for i in spawn_amount:
		var enemy = enemy_scene.instantiate()
		enemy.global_position = get_random_position()
		enemy.tree_exited.connect(_on_enemy_died)  # Track when enemies die
		add_child(enemy)
	
	enemy_count += spawn_amount
	print("Spawned wave: ", spawn_amount, " enemies (Total: ", enemy_count, "/", max_enemies, ")")

func _on_enemy_died():
	enemy_count = max(0, enemy_count - 1)

func update_enemy_count():
	# Recount actual enemies in case some were removed
	enemy_count = 0
	for child in get_children():
		if child != timer and child.is_in_group("enemies"):
			enemy_count += 1

func clear_enemies():
	for child in get_children():
		if child != timer and child.is_in_group("enemies"):
			child.queue_free()
	enemy_count = 0

func get_random_position():
	if player == null:
		return global_position
	
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
	
	return Vector2(
		randf_range(spawn_pos1.x, spawn_pos2.x),
		randf_range(spawn_pos1.y, spawn_pos2.y)
	)
