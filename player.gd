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
var experience = 0
var experience_level = 1
var collected_experience = 0

@onready var expBar = get_node("%ExperienceBar")
@onready var ExperienceBarText = get_node("%ExperienceBarText")

func _ready():
	add_to_group("Player")
	current_health = max_health
	$HurtBox.body_entered.connect(_on_body_entered)
	set_expbar(experience, calculate_experiencecap())

func _physics_process(_delta):
	var horizontal = Input.get_axis("ui_left", "ui_right")
	var vertical = Input.get_axis("ui_up", "ui_down")
	var movement = Vector2(horizontal, vertical)

	if movement.length() > 0:
		last_direction = movement.normalized()
		velocity = movement.normalized() * player_move_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, player_move_speed)

	move_and_slide()

	damage_timer -= _delta
	if damage_timer <= 0:
		var overlapping = $HurtBox.get_overlapping_bodies()
		for body in overlapping:
			if body.is_in_group("enemy"):
				take_damage(10)
				damage_timer = damage_cooldown
				break

	fire_timer -= _delta
	if fire_timer <= 0:
		shoot_fireballs()
		fire_timer = fire_rate

func shoot_fireballs():
	if not fireball_scene:
		return
	
	for i in range(fireball_count):
		var fireball = fireball_scene.instantiate()
		fireball.direction = last_direction
		fireball.position = global_position
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
	
func _on_grab_area_area_entered(area):
	if area.is_in_group("loot"):
		area.target = self


func _on_collect_area_area_entered(area):
	if area.is_in_group("loot"):
		var gem_exp = area.collect()
		calculate_experience(gem_exp)
		
func calculate_experience(gem_exp):
	var exp_required = calculate_experiencecap()
	collected_experience += gem_exp
	if experience + collected_experience >= exp_required: #level up
		collected_experience -= exp_required - experience
		experience_level += 1
		ExperienceBarText.text = str("Level: ",experience_level)
		experience = 0
		exp_required = calculate_experiencecap()
		calculate_experience(0)
	else:
		experience += collected_experience
		collected_experience = 0
		
	set_expbar(experience, exp_required)
	
func calculate_experiencecap():
	var exp_cap = experience_level
	if experience_level < 20:
		exp_cap = experience_level*5
	elif experience_level < 40:
		exp_cap = 95 * (experience_level -19)*8
	else:
		exp_cap = 255 + (experience_level -39)*12
	
	return exp_cap

func set_expbar(set_value = 1, set_max_value = 100):
	expBar.value = set_value
	expBar.max_value = set_max_value
