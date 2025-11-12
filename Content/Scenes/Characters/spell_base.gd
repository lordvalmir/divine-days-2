extends Resource
class_name SpellBase

@export var spell_name: String = "Base Spell"
@export var spell_icon: Texture2D
@export var projectile_scene: PackedScene
@export var base_damage: float = 10.0
@export var base_fire_rate: float = 1.0  # Seconds between shots
@export var base_projectile_count: int = 1
@export var base_speed: float = 400.0
@export var base_lifetime: float = 3.0
@export var base_pierce: int = 0  # How many enemies it can pierce
@export var spread_pattern: SpreadPattern = SpreadPattern.RANDOM

enum SpreadPattern {
	RANDOM,      # Random directions
	AIMED,       # Towards nearest enemy
	CIRCLE,      # Evenly distributed circle
	CONE,        # Cone towards last movement direction
	SPIRAL       # Rotating spiral pattern
}

# Upgrade tracking
var current_level: int = 1
var damage_multiplier: float = 1.0
var fire_rate_multiplier: float = 1.0
var count_bonus: int = 0
var speed_multiplier: float = 1.0
var lifetime_multiplier: float = 1.0
var pierce_bonus: int = 0

func get_damage() -> float:
	return base_damage * damage_multiplier

func get_fire_rate() -> float:
	return base_fire_rate * fire_rate_multiplier

func get_projectile_count() -> int:
	return base_projectile_count + count_bonus

func get_speed() -> float:
	return base_speed * speed_multiplier

func get_lifetime() -> float:
	return base_lifetime * lifetime_multiplier

func get_pierce() -> int:
	return base_pierce + pierce_bonus

func upgrade_damage(multiplier: float):
	damage_multiplier *= multiplier
	current_level += 1

func upgrade_fire_rate(multiplier: float):
	fire_rate_multiplier *= multiplier
	current_level += 1

func upgrade_count(amount: int):
	count_bonus += amount
	current_level += 1

func upgrade_speed(multiplier: float):
	speed_multiplier *= multiplier
	current_level += 1

func upgrade_pierce(amount: int):
	pierce_bonus += amount
	current_level += 1
