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
	print("SpawnArea ready: ", area_name, " with ", spawns.size(), " spawn configs")
	
	# Debug: print what's monitoring
	print("  - Monitoring: ", monitoring)
	print("  - Monitorable: ", monitorable)

func _on_body_entered(body):
	print("Something entered area: ", area_name, " - Body name: ", body.name)
	print("  - Is in Player group? ", body.is_in_group("Player"))
	
	if enabled and body.is_in_group("Player"):
		print("✓ Player detected entering: ", area_name)
		player_entered_area.emit(self)

func _on_body_exited(body):
	print("Something exited area: ", area_name, " - Body name: ", body.name)
	
	if body.is_in_group("Player"):
		print("✓ Player detected exiting: ", area_name)
		player_exited_area.emit(self)
