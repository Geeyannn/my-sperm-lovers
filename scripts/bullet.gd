extends Area3D

@export var speed: float = 30.0
@export var lifetime: float = 0.1
@export var damage: int = 2
@export var alert_radius: float = 12.0

var direction := Vector3.FORWARD

@onready var impact_sound: AudioStreamPlayer3D = $ImpactSound
@onready var death_sound: AudioStreamPlayer3D = $DeathSound

func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)
	print("Bullet ready, monitoring: ", monitoring)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	print("Bullet hit: ", body.name, " Groups: ", body.get_groups())

	var was_fatal := false
	if body.is_in_group("enemies"):
		was_fatal = body.take_damage(damage)
		alert_nearby_enemies(body.global_position)

	if body.is_in_group("enemies") or body.is_in_group("walls"):
		play_impact_and_free(was_fatal)


func alert_nearby_enemies(hit_position: Vector3) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if not enemy.has_method("become_aggro"):
			continue
		var dist = enemy.global_position.distance_to(hit_position)
		if dist <= alert_radius:
			enemy.become_aggro()


func play_impact_and_free(was_fatal: bool = false) -> void:
	# Choose which sound to play
	var sound_to_play: AudioStreamPlayer3D = null
	if was_fatal and death_sound and death_sound.stream:
		sound_to_play = death_sound
	elif impact_sound and impact_sound.stream:
		sound_to_play = impact_sound

	# Play sound if available
	if sound_to_play:
		# Reparent sound to scene root so it keeps playing after bullet is freed
		var sound_pos = sound_to_play.global_position
		sound_to_play.reparent(get_tree().root)
		sound_to_play.global_position = sound_pos
		sound_to_play.play()
		# Auto-free the sound when it finishes
		sound_to_play.finished.connect(sound_to_play.queue_free)

	queue_free()
