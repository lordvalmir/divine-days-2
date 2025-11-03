extends Area2D

@export var speed = 400.0
@export var lifetime = 3.0
@export var damage = 20

var direction = Vector2.ZERO

func _ready():
	body_entered.connect(_on_body_entered)
	# Rotate to face the direction
	rotation = direction.angle()
	
	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
