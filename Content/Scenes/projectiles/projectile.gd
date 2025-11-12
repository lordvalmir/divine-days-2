extends Area2D
class_name Projectile

var direction: Vector2 = Vector2.ZERO
var speed: float = 400.0
var lifetime: float = 3.0
var damage: float = 20.0
var pierce: int = 0  # How many enemies it can hit before disappearing

var hit_enemies: Array = []  # Track which enemies we've already hit

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Rotate to face the direction
	if direction != Vector2.ZERO:
		rotation = direction.angle()
	
	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func setup(dir: Vector2, spd: float, life: float, dmg: float, prc: int = 0):
	direction = dir.normalized()
	speed = spd
	lifetime = life
	damage = dmg
	pierce = prc
	
	if direction != Vector2.ZERO:
		rotation = direction.angle()

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemy") and not body in hit_enemies:
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		hit_enemies.append(body)
		
		# Check if we should destroy after hitting
		if hit_enemies.size() > pierce:
			queue_free()
