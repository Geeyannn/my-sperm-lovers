extends Node3D

# --- Configuration ---
@export var sibling_scene: PackedScene
@export var spawn_on_start: bool = true
@export var spawn_check_radius: float = 0.5  # Reduced radius for closer spawning

# --- Tracking ---
var active_siblings: Array[Node] = []

# --- Node References ---
@onready var markers_parent: Node3D = get_node_or_null("Markers")

func _ready() -> void:
	if spawn_on_start:
		spawn_all_siblings()

func spawn_all_siblings() -> void:
	if not sibling_scene:
		print("MapManager Error: No sibling scene assigned!")
		return

	# Collect all markers in the scene
	var markers = []
	
	if markers_parent:
		markers = markers_parent.get_children()
	else:
		for child in get_tree().current_scene.find_children("*", "Marker3D"):
			markers.append(child)

	if markers.size() == 0:
		print("MapManager Warning: No markers found to spawn siblings.")
		return

	# Shuffle markers to prevent bias
	markers.shuffle()
	
	# Track spawned positions to avoid stacking
	var spawned_positions: Array[Vector3] = []
	
	# Loop through markers and instance siblings
	for marker in markers:
		if marker is Marker3D:
			# Use marker position directly - markers should be placed at correct height in editor
			var spawn_pos = marker.global_position

			# Only check if position is too close to existing ones
			var too_close = false
			for existing_pos in spawned_positions:
				var distance = spawn_pos.distance_to(existing_pos)
				if distance < spawn_check_radius:
					too_close = true
					break
			
			if not too_close:
				spawn_sibling_at_position(spawn_pos)
				spawned_positions.append(spawn_pos)
				print("Spawned sibling at: ", marker.name)
			else:
				print("Skipped marker ", marker.name, " - too close to existing spawn")

func spawn_sibling_at_position(spawn_pos: Vector3) -> void:
	if not sibling_scene:
		return

	var new_sibling = sibling_scene.instantiate()

	# Add to scene
	get_tree().current_scene.add_child(new_sibling)
	new_sibling.global_position = spawn_pos

	# Track this sibling
	active_siblings.append(new_sibling)

	# Ensure the enemy is part of the "enemies" group
	new_sibling.add_to_group("enemies")

	# Connect signals if needed (check if the sibling has these signals first)
	if new_sibling.has_signal("died"):
		new_sibling.died.connect(_handle_sibling_died.bind(new_sibling))

	# Always connect tree_exited for cleanup
	new_sibling.tree_exited.connect(_handle_sibling_removed.bind(new_sibling))

func clear_map() -> void:
	for sibling in active_siblings:
		if is_instance_valid(sibling):
			sibling.queue_free()
	active_siblings.clear()

func get_active_count() -> int:
	# Clean up invalid references and return count
	active_siblings = active_siblings.filter(func(s): return is_instance_valid(s))
	return active_siblings.size()

# Signal handler for sibling death
func _handle_sibling_died(sibling: Node) -> void:
	print("Sibling died: ", sibling.name if sibling else "Unknown")
	active_siblings.erase(sibling)

# Signal handler for sibling removal
func _handle_sibling_removed(sibling: Node) -> void:
	print("Sibling removed from tree: ", sibling.name if sibling else "Unknown")
	active_siblings.erase(sibling)
