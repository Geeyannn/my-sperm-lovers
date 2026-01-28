extends Node3D

# --- Configuration ---
@export var sibling_scene: PackedScene # Drag sibling_sperm_lvl2.tscn here in the Inspector
@export var spawn_on_start: bool = true

# --- Node References ---
# This assumes your markers are children of the MapManager or in the MainMap
@onready var markers_parent: Node3D = get_node_or_null("Markers")

func _ready() -> void:
	if spawn_on_start:
		spawn_all_siblings()

## Finds all Marker3D nodes and spawns a sibling at each location
func spawn_all_siblings() -> void:
	if not sibling_scene:
		print("MapManager Error: No sibling scene assigned!")
		return

	# Collect all markers in the scene
	var markers = []
	
	# Option A: Get markers from a specific folder node
	if markers_parent:
		markers = markers_parent.get_children()
	# Option B: Find markers anywhere in the current scene (Fallback)
	else:
		for child in get_tree().current_scene.find_children("*", "Marker3D"):
			markers.append(child)

	if markers.size() == 0:
		print("MapManager Warning: No markers found to spawn siblings.")
		return

	# Loop through markers and instance siblings
	for marker in markers:
		if marker is Marker3D:
			var new_sibling = sibling_scene.instantiate()
			# Add to the scene tree
			get_tree().current_scene.add_child.call_deferred(new_sibling)
			# Match the marker's position
			new_sibling.global_position = marker.global_position
			print("Spawned sibling at: ", marker.name)

## Clears all siblings from the map if needed
func clear_map() -> void:
	var siblings = get_tree().get_nodes_in_group("enemies")
	for s in siblings:
		s.queue_free()