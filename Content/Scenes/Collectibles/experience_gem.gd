extends Area2D

@export var experience = 1

var spr_green = preload("res://Content/Assets/pngtree-glossy-pixel-gem-with-high-contrast-shine-on-transparent-background-vector-png-image_16207030.png")
var spr_blue = preload("res://Content/Assets/pngtree-glossy-pixel-gem-with-high-contrast-shine-on-transparent-background-vector-png-image_16207030.png")
var spr_red = preload("res://Content/Assets/pngtree-glossy-pixel-gem-with-high-contrast-shine-on-transparent-background-vector-png-image_16207030.png")

var target = null
var speed = -1

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

func _ready():
	if experience <  5:
		return
	elif experience < 25:
		sprite.texture = spr_blue
	else:
		sprite.texture = spr_red
		
func _physics_process(delta):
	if target != null:
		global_position = global_position.move_toward(target.global_position, speed)
		speed += 4*delta
		
func collect():
	collision.call_deferred("set", "disabled", true)
	sprite.visible = false
	return experience
	
func _on_snd_collected_finished():
	queue_free()
