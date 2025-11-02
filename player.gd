extends CharacterBody2D

@export var player_move_speed = 300.0
@export var player_health : int = 100

@warning_ignore("unused_parameter")
func _physics_process(delta):

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var horizontal = Input.get_axis("ui_left", "ui_right")
	var vertical = Input.get_axis("ui_up", "ui_down")
	if horizontal:
		velocity.x = horizontal * player_move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, player_move_speed)
	if vertical:
		velocity.y = vertical * player_move_speed
	else:
		velocity.y = move_toward(velocity.x, 0, player_move_speed)

	move_and_slide()
	health_system()
#Health System
func take_damage(damage):
	player_health = player_health - damage
	print(player_health)
func health_system():
	
	if (player_health <= 0):
		get_tree().reload_current_scene()
