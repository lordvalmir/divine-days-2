extends CharacterBody2D

@export var enemy_move_speed: float = 130
@export var max_health = 100
@export var experience = 1

var current_health = max_health
var exp_gem = preload("res://Content/Scenes/Collectibles/ExperienceGem.tscn")
 
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")
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
	var new_gem = exp_gem.instantiate()
	new_gem.global_position = global_position
	new_gem.experience = experience
	loot_base.call_deferred("add_child", new_gem)
	queue_free()
