extends Node3D
signal destroyed

@export var max_health: int = 10
@export var hit_expand_mult: Vector3 = Vector3(1.4, 1.4, 1.4)
@export var expand_duration: float = 0.08
@export var hold_duration: float = 0.09
@export var shrink_duration: float = 0.15
@onready var mesh: MeshInstance3D = $Mesh
@onready var collision: CollisionShape3D = $StaticBody3D/CollisionShape3D
@onready var audio_player: AudioStreamPlayer3D = $AudioPlayer

var health: int = 0

func _ready() -> void:
	health = max_health
	add_to_group("pillars")

func take_damage(amount: int) -> bool:
	var reduced_dmg = int(amount * 1)
	print("Pillar ", name, " taking ", reduced_dmg, " damage! Current HP: ", health, " -> ", health - amount)
	if health <= 0: 
		return false
	
	health -= reduced_dmg
	audio_player.play()
	_do_hit_effect()
	
	if health <= 0:
		emit_signal("destroyed")
		if GameManager:
			GameManager.add_karma_xp(30.0)  # Good action: +30 XP
		queue_free()
		return true  # Fatal
	return false

func _do_hit_effect() -> void:
	var original_scale = scale
	var expanded_scale = original_scale * hit_expand_mult
	var tween = create_tween()
	
	tween.tween_property(self, "scale", expanded_scale, expand_duration)
	tween.tween_interval(hold_duration)
	tween.tween_property(self, "scale", original_scale, shrink_duration)
