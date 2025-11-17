extends Resource
class_name Spawn_info

@export_group("Enemy Configuration")
@export var enemy: Resource
@export var enemies_per_wave: int = 5
@export var wave_delay: int = 10  # Delay between waves in timer ticks

@export_group("Time Window (Optional)")
@export var time_start: int = 0  # Start spawning after X seconds (0 = immediate)
@export var time_end: int = 0    # Stop spawning after X seconds (0 = infinite)

# Internal tracking
var wave_delay_counter: int = 0
var time_elapsed: int = 0

func is_active(current_time: int) -> bool:
	if time_end > 0 and current_time > time_end:
		return false
	if current_time < time_start:
		return false
	return true
