extends Area2D
class_name SpawnArea

@export_group("Area Info")
@export var area_name: String = "Area 1"
@export var difficulty_level: int = 1
@export var enabled: bool = true

@export_group("Spawn Limits")
@export var max_total_spawns: int = 100  # Total enemies this area can spawn (lifetime)
@export var max_alive_enemies: int = 20   # Max enemies alive at once

@export_group("Spawn Configuration")
@export var spawns: Array[Spawn_info] = []

signal player_entered_area(area: SpawnArea)
signal player_exited_area(area: SpawnArea)

var total_spawned: int = 0
var time_in_area: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("spawn_areas")

func _on_body_entered(body):
	if enabled and body.is_in_group("Player"):
		player_entered_area.emit(self)

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_exited_area.emit(self)

func can_spawn() -> bool:
	return total_spawned < max_total_spawns

func increment_spawn_count():
	total_spawned += 1
