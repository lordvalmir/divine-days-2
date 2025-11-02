extends CharacterBody2D

@export var enemy_move_speed: float = 280.0

@onready var player = get_tree().get_first_node_in_group("Player")
@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
		var direction = position.direction_to(player.global_position).normalized()
		velocity = direction * enemy_move_speed
		move_and_slide()
