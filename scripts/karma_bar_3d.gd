extends Node3D

@export var positive_color: Color = Color(0.5, 0.5, 0.5, 1)  # Grey for positive karma
@export var negative_color: Color = Color(0.5, 0.13, 0.13, 1)  # Maroon for negative karma
@export var background_color: Color = Color(0.25, 0.25, 0.25, 1)  # Dark grey
@export var border_color: Color = Color.BLACK
@export var border_width: int = 2

@onready var progress_bar: ProgressBar = $SubViewport/ProgressBar
@onready var sprite: Sprite3D = $Sprite3D

var current_level: int = 0
var is_positive: bool = true


func _ready() -> void:
	setup_colors()
	# Connect to GameManager signal
	if GameManager:
		GameManager.karma_updated.connect(_on_karma_updated)


func setup_colors() -> void:
	# Fill style - solid color, no border
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = positive_color
	fill_style.corner_radius_top_left = 0
	fill_style.corner_radius_top_right = 0
	fill_style.corner_radius_bottom_left = 0
	fill_style.corner_radius_bottom_right = 0
	progress_bar.add_theme_stylebox_override("fill", fill_style)

	# Background style - with border
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = background_color
	bg_style.border_color = border_color
	bg_style.border_width_left = border_width
	bg_style.border_width_right = border_width
	bg_style.border_width_top = border_width
	bg_style.border_width_bottom = border_width
	bg_style.corner_radius_top_left = 0
	bg_style.corner_radius_top_right = 0
	bg_style.corner_radius_bottom_left = 0
	bg_style.corner_radius_bottom_right = 0
	progress_bar.add_theme_stylebox_override("background", bg_style)


func _on_karma_updated(level: int, progress: float, karma_is_positive: bool) -> void:
	current_level = level
	is_positive = karma_is_positive

	# Update progress bar value (0-100%)
	progress_bar.max_value = 1.0
	progress_bar.value = progress

	# Update fill color based on karma polarity
	var fill_style = progress_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style:
		if is_positive:
			fill_style.bg_color = positive_color
		else:
			fill_style.bg_color = negative_color
