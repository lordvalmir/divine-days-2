extends CharacterBody2D

@export var player_move_speed = 300.0
@export var max_health = 100
@export var damage_cooldown = 1.0

var current_health = max_health
var damage_timer = 0.0

func _ready():
	#add_to_group("player")
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
	get_tree().reload_current_scene()

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
		velocity.y = move_toward(velocity.y, 0, player_move_speed)
	move_and_slide()
	
	damage_timer -= _delta
	if damage_timer <= 0:
		var overlapping = $Area2D.get_overlapping_bodies()
		for body in overlapping:
			if body.is_in_group("enemy"):
				take_damage(10)
				damage_timer = damage_cooldown
				break  # Only take damage from one enemy per cooldown
