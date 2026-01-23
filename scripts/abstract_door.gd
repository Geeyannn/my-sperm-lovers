extends StaticBody3D

enum UnlockCondition {
	AFTER_DIALOG,      # Remove door after dialog chain finishes
	KILL_ENEMIES,      # Remove door after all enemies are killed
	COMPLETE_PUZZLE,   # Remove door after puzzle is completed
	ENEMIES_OR_PUZZLE  # Remove door after either enemies killed OR puzzle completed
}

@export_group("Dialog Settings")
@export var auto_chain_dialog_id: String # Refer to JSON

@export_group("Door Unlock Condition")
@export var unlock_condition: UnlockCondition = UnlockCondition.AFTER_DIALOG
@export var enemy_group: String
@export var puzzle_signal_node: NodePath

@onready var dialog_system: Control = $DialogSystem/ControlNode
@onready var interact_area: Area3D = $InteractArea
@onready var door_mesh: MeshInstance3D = $DoorMesh
@onready var door_collision: CollisionShape3D = $DoorCollision

var can_interact := false
var dialog_playing := false
var first_interaction_done := false
var just_closed_dialogue := false
var puzzle_node: Node = null
var enemy_check_timer: Timer = null

func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	
	if dialog_system:
		dialog_system.dialogue_finished.connect(_on_dialog_finished)
	else:
		push_warning("DialogSystem / ControlNode not found!")
	
	# Setup puzzle listener
	if (unlock_condition == UnlockCondition.COMPLETE_PUZZLE or 
		unlock_condition == UnlockCondition.ENEMIES_OR_PUZZLE) and puzzle_signal_node:
		puzzle_node = get_node_or_null(puzzle_signal_node)
		if puzzle_node and puzzle_node.has_signal("puzzle_completed"):
			puzzle_node.puzzle_completed.connect(_on_puzzle_completed)
		else:
			push_warning("Puzzle node not found or doesn't have 'puzzle_completed' signal!")
	
	# Setup automatic enemy checking
	if (unlock_condition == UnlockCondition.KILL_ENEMIES or 
		unlock_condition == UnlockCondition.ENEMIES_OR_PUZZLE) and enemy_group:
		enemy_check_timer = Timer.new()
		add_child(enemy_check_timer)
		enemy_check_timer.wait_time = 0.5
		enemy_check_timer.timeout.connect(_on_enemy_check_timer_timeout)
		enemy_check_timer.start()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		can_interact = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		can_interact = false

func _input(event: InputEvent) -> void:
	if unlock_condition == UnlockCondition.KILL_ENEMIES:
		return
	if not can_interact or dialog_playing:
		return
	if just_closed_dialogue:
		just_closed_dialogue = false
		return
	if event.is_action_pressed("shoot"):
		get_viewport().set_input_as_handled()
		interact()

func interact() -> void:
	if not dialog_system:
		push_warning("No dialog system reference!")
		return
	if not first_interaction_done and auto_chain_dialog_id != "":
		first_interaction_done = true
		dialog_playing = true
		dialog_system.start_dialogue(auto_chain_dialog_id, true)
	else:
		match unlock_condition:
			UnlockCondition.COMPLETE_PUZZLE, UnlockCondition.ENEMIES_OR_PUZZLE:
				check_puzzle_status()
			_:
				print("Interaction already used or no auto-chain dialogue assigned")

func _on_dialog_finished() -> void:
	dialog_playing = false
	just_closed_dialogue = true
	if unlock_condition == UnlockCondition.AFTER_DIALOG:
		remove_door()

func _on_enemy_check_timer_timeout() -> void:
	var enemies = get_tree().get_nodes_in_group(enemy_group)
	if enemies.size() == 0:
		print("All enemies defeated! Door unlocked.")
		enemy_check_timer.stop()
		remove_door()

func check_puzzle_status() -> void:
	if puzzle_node and puzzle_node.has_method("is_completed"):
		if puzzle_node.is_completed():
			print("Puzzle completed! Door unlocked.")
			remove_door()
		else:
			print("Puzzle not yet completed.")
	else:
		print("Puzzle status cannot be checked.")

func _on_puzzle_completed() -> void:
	print("Puzzle completed! Door unlocked.")
	remove_door()

func remove_door() -> void:
	print("Door removed!")
	if enemy_check_timer and not enemy_check_timer.is_stopped():
		enemy_check_timer.stop()
	if door_collision:
		door_collision.disabled = true
	var tween = create_tween()
	tween.set_parallel(true)
	if door_mesh:
		var material = door_mesh.get_active_material(0)
		if material:
			material = material.duplicate()
			door_mesh.set_surface_override_material(0, material)
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			tween.tween_property(material, "albedo_color:a", 0.0, 0.5)
	
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	tween.tween_callback(queue_free).set_delay(0.5)
