extends Resource
class_name Spawn_info

@export var enemy: Resource
@export var enemies_per_wave: int = 5
@export var wave_delay: int = 10

var wave_delay_counter = 0
