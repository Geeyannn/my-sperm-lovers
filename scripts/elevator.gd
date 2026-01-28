extends CSGCombiner3D

# --- Configuration ---
@export var target_height: float = 20.0
@export var speed: float = 3.0
@export var gate_speed: float = 10.0
const MAX_CAPACITY: int = 20 #

# --- State ---
var siblings_inside: int = 0
var timer_started: bool = false
var can_rise: bool = false
var gate_closing: bool = false
# --- Node References ---
# Ensure your Elevator scene has a Timer child and a Gate (CSGBox3D) child
@onready var timer: Timer = $Timer
@onready var gate: CSGBox3D = $Gate

func _ready() -> void:
	add_to_group("elevator") # Allows siblings to find the elevator
	
	if timer:
		timer.timeout.connect(_on_timer_timeout)
	
	# Physics only runs during the ascent
	set_physics_process(false)

# --- Trigger Zone Logic ---
# Connect your TriggerZone's body_entered signal here
func _on_trigger_zone_body_entered(body: Node3D) -> void:
	# 1. Start the 10s countdown when the player enters
	if body.is_in_group("player") and not timer_started:
		start_elevator_countdown()
	
	# 2. Track siblings for the capacity limit
	if body.is_in_group("enemies"):
		siblings_inside += 1
		print("Occupancy: ", siblings_inside, "/", MAX_CAPACITY)
		
		# 3. Depart immediately if full
		if siblings_inside >= MAX_CAPACITY and not gate_closing:
			print("Elevator at capacity! Closing doors.")
			_on_timer_timeout()

func _on_trigger_zone_body_exited(body: Node3D) -> void:
	if body.is_in_group("enemies"):
		siblings_inside = max(0, siblings_inside - 1)

# --- Sibling Survival/Death Logic ---
# Called by the sibling script when one is killed inside the elevator
func reduce_occupancy() -> void:
	siblings_inside = max(0, siblings_inside - 1)
	print("Space opened up! Current occupants: ", siblings_inside)

# --- Departure Sequence ---
func start_elevator_countdown() -> void:
	timer_started = true
	if timer:
		timer.start(10.0)
	print("Timer started: 10 seconds until departure.")

func _on_timer_timeout() -> void:
	if timer:
		timer.stop()
	gate_closing = true
	can_rise = true
	set_physics_process(true)
	print("Departure sequence initiated.")

# --- Physics (Ascent) ---
func _physics_process(delta: float) -> void:
	# 1. Move the Gate down to 'close' the elevator
	if gate_closing and gate.position.y > 0.0:
		gate.position.y -= gate_speed * delta
		if gate.position.y <= 0.0:
			gate.position.y = 0.0
	
	# 2. Rise the elevator to the target height
	if can_rise and global_position.y < target_height:
		global_position.y += speed * delta
	elif global_position.y >= target_height:
		# Ascent complete
		set_physics_process(false)