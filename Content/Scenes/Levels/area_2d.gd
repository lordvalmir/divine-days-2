extends Area2D
class_name SpawnArea

@export var area_name: String = "Area 1"
@export var difficulty_level: int = 1
@export var spawns: Array[Spawn_info] = []
@export var enabled: bool = true

signal player_entered_area(area: SpawnArea)
signal player_exited_area(area: SpawnArea)

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("spawn_areas")

func _on_body_entered(body):
	if enabled and body.is_in_group("Player"):
		player_entered_area.emit(self)

func _on_body_exited(body):
	if body.is_in_group("Player"):		player_exited_area.emit(self)
