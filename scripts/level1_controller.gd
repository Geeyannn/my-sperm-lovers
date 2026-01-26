extends Node3D

@onready var dialog_system = $DialogSystem/ControlNode

func _ready() -> void:
	# Wait a brief moment for the scene to fully initialize
	await get_tree().create_timer(1.0).timeout

	# Automatically show the developer welcome message
	if dialog_system:
		dialog_system.start_dialogue("DevWelcomeL1")
	else:
		push_error("DialogSystem/ControlNode not found in level1!")
