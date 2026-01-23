# AbstractInteractable.gd
extends Node3D

@export var auto_chain_dialog_id: String
@onready var area: Area3D = $InteractableArea
var player_inside: bool = false

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false

func _unhandled_input(event: InputEvent) -> void:
	if not player_inside: 
		return
	if event.is_action_pressed("shoot"):
		get_viewport().set_input_as_handled()
		_try_start_dialogue()

func _try_start_dialogue() -> void:
	if auto_chain_dialog_id.is_empty():
		print("Warning: No dialog ID set on ", name)
		return
	var dialog_ui = get_tree().get_first_node_in_group("dialogue_ui")
	if dialog_ui:
		dialog_ui.start_dialogue(auto_chain_dialog_id, true)
	else:
		push_warning("No node found in group 'dialogue_ui' — is dialog_system.tscn in the scene and grouped?")
