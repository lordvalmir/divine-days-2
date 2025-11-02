extends Area2D

@export var damage = 5

func _on_body_entered(body):
	print("collision")
	body.take_damage(damage)
