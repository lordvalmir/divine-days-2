extends CharacterBody2D

@export var SPEED = 300.0
@export var max_health = 100
var current_health = max_health

func _ready():
	current_health = max_health
	$Area2D.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		take_damage(10)

func take_damage(amount):
	current_health -= amount
	print("Player health: ", current_health)
	
	if current_health <= 0:
		die()

func die():
	print("Player died!")
	queue_free()

func _physics_process(_delta):
	var horizontal = Input.get_axis("ui_left", "ui_right")
	var vertical = Input.get_axis("ui_up", "ui_down")
	if horizontal:
		velocity.x = horizontal * player_move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, player_move_speed)
	if vertical:
		velocity.y = vertical * player_move_speed
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
	move_and_slide()
	health_system()
#Health System
func take_damage(damage):
	player_health = player_health - damage
	print(player_health)
func health_system():
	
	if (player_health <= 0):
		get_tree().reload_current_scene()
