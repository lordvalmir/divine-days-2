extends CharacterBody2D

@export var enemy_move_speed: float = 130
@export var max_health = 100
var current_health = max_health
 
@onready var player = get_tree().get_first_node_in_group("Player")
@warning_ignore("unused_parameter")

func _ready():
	add_to_group("enemy")

func _physics_process(_delta: float) -> void:
		var direction = position.direction_to(player.global_position).normalized()
		velocity = direction * enemy_move_speed
		move_and_slide()
		
func take_damage(amount):
	current_health -= amount
	
	if current_health <= 0:
		die()

func die():
	queue_free()
