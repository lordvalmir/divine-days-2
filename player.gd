extends CharacterBody2D

@export var player_move_speed = 300.0
@export var max_health = 100
@export var damage_cooldown = 1.0
@export var fireball_scene: PackedScene
@export var fire_rate = 0.5
@export var fireball_count = 1

var current_health = max_health
var damage_timer = 0.0
var fire_timer = 0.0
var last_direction = Vector2.RIGHT  # Default direction when not moving

func _ready():
	#add_to_group("player")
	current_health = max_health
	$Area2D.body_entered.connect(_on_body_entered)

func _physics_process(_delta):
	var horizontal = Input.get_axis("ui_left", "ui_right")
	var vertical = Input.get_axis("ui_up", "ui_down")
	
	# Create movement vector
	var movement = Vector2(horizontal, vertical)
	
	# Update last direction if moving
	if movement.length() > 0:
		last_direction = movement.normalized()
		velocity = movement.normalized() * player_move_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, player_move_speed)
	
	move_and_slide()
	
	# Damage cooldown
	damage_timer -= _delta
	if damage_timer <= 0:
		var overlapping = $Area2D.get_overlapping_bodies()
		for body in overlapping:
			if body.is_in_group("enemy"):
				take_damage(10)
				damage_timer = damage_cooldown
				break
	
	# Fireball timer
	fire_timer -= _delta
	if fire_timer <= 0:
		shoot_fireballs()
		fire_timer = fire_rate

func shoot_fireballs():
	if not fireball_scene:
		return
	
	for i in range(fireball_count):
		var fireball = fireball_scene.instantiate()
		
		# Shoot in the direction of movement (or last direction if standing still)
		fireball.direction = last_direction
		
		# Spawn at player position
		fireball.position = global_position
		
		# Add to scene
		get_parent().add_child(fireball)

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
