extends Control

# Base resolution for scaling calculations (1080p as reference)
const BASE_WIDTH = 1920.0
const BASE_HEIGHT = 1080.0

# Scaling factor
var scale_factor: float = 1.0

# UI references
@onready var title_label: Label = %Title
@onready var button_container: PanelContainer = %ButtonContainer
@onready var button_row: HBoxContainer = %ButtonRow
@onready var play_button: Button = %PlayButton
@onready var continue_button: Button = %ContinueButton
@onready var options_button: Button = %OptionsButton
@onready var collection_button: Button = %CollectionButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_calculate_scale_factor()
	_apply_scaling()
	_style_title()
	_style_button_container()
	_style_buttons()
	_connect_signals()
	
	# Update layout when window is resized
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _calculate_scale_factor() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	# Use the smaller dimension to maintain aspect ratio for better visibility
	var width_scale = viewport_size.x / BASE_WIDTH
	var height_scale = viewport_size.y / BASE_HEIGHT
	scale_factor = min(width_scale, height_scale)
	# More generous scaling bounds for better visibility on all screen sizes
	scale_factor = clamp(scale_factor, 0.4, 2.5)

func _apply_scaling() -> void:
	# Scale title font size
	var title_size = max(107, int(96 * scale_factor))
	title_label.add_theme_font_size_override("font_size", title_size)
	
	# Scale button sizes
	var button_width = max(120, int(150 * scale_factor))
	var button_height = max(100, int(200 * scale_factor))
	play_button.custom_minimum_size = Vector2(button_width, button_height)
	continue_button.custom_minimum_size = Vector2(button_width, button_height)
	options_button.custom_minimum_size = Vector2(button_width, button_height)
	collection_button.custom_minimum_size = Vector2(button_width, button_height)
	
	# Scale button font sizes
	var button_font_size = max(24, int(20 * scale_factor))
	play_button.add_theme_font_size_override("font_size", button_font_size)
	continue_button.add_theme_font_size_override("font_size", button_font_size)
	options_button.add_theme_font_size_override("font_size", button_font_size)
	collection_button.add_theme_font_size_override("font_size", button_font_size)

func _style_title() -> void:
	# Style title with white/light blue appearance and outline
	title_label.add_theme_color_override("font_color", Color(0.132, 0.143, 0.068, 1.0))  # Light blue
	title_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 1))  # White outline
	title_label.add_theme_constant_override("outline_size", max(2, int(4 * scale_factor)))

func _style_button_container() -> void:
	# Style the button container with dark grey background
	var container_style = StyleBoxFlat.new()
	container_style.bg_color = Color(0.2, 0.2, 0.2, 0.9)  # Dark grey with slight transparency
	container_style.corner_radius_top_left = max(4, int(8 * scale_factor))
	container_style.corner_radius_top_right = max(4, int(8 * scale_factor))
	container_style.corner_radius_bottom_right = max(4, int(8 * scale_factor))
	container_style.corner_radius_bottom_left = max(4, int(8 * scale_factor))
	button_container.add_theme_stylebox_override("panel", container_style)

func _style_buttons() -> void:
	# BALATRO-style button colors
	# PLAY: light blue background
	_style_button(play_button, Color(0.128, 0.456, 0.696, 1.0))  # Light blue
	
	# CONTINUE: green background (similar to collection)
	_style_button(continue_button, Color(0.785, 0.595, 0.894, 1.0))  # Green
	
	# OPTIONS: orange-yellow background
	_style_button(options_button, Color(1.0, 0.7, 0.3, 1.0))  # Orange-yellow
	
	# COLLECTION: green background
	_style_button(collection_button, Color(0.3, 0.8, 0.4, 1.0))  # Green
	
	# Update continue button state based on active run
	_update_continue_button()

func _style_button(button: Button, color: Color) -> void:
	var corner_radius = max(4, int(8 * scale_factor))
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = color
	style_normal.corner_radius_top_left = corner_radius
	style_normal.corner_radius_top_right = corner_radius
	style_normal.corner_radius_bottom_right = corner_radius
	style_normal.corner_radius_bottom_left = corner_radius
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = color.lightened(0.15)
	style_hover.corner_radius_top_left = corner_radius
	style_hover.corner_radius_top_right = corner_radius
	style_hover.corner_radius_bottom_right = corner_radius
	style_hover.corner_radius_bottom_left = corner_radius
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = color.darkened(0.2)
	style_pressed.corner_radius_top_left = corner_radius
	style_pressed.corner_radius_top_right = corner_radius
	style_pressed.corner_radius_bottom_right = corner_radius
	style_pressed.corner_radius_bottom_left = corner_radius
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	
	# White text
	button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9, 1))

func _connect_signals() -> void:
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	options_button.pressed.connect(_on_options_pressed)
	collection_button.pressed.connect(_on_collection_pressed)

func _on_viewport_size_changed() -> void:
	# Recalculate scale factor
	_calculate_scale_factor()
	
	# Reapply scaling
	_apply_scaling()
	_style_title()
	_style_button_container()
	_style_buttons()

func _on_play_pressed() -> void:
	# Navigate to division selection scene
	get_tree().change_scene_to_file("res://scenes/core/DivisionSelectScene.tscn")

func _on_continue_pressed() -> void:
	# Continue existing run if one is active
	if GameManager.run_active:
		get_tree().change_scene_to_file("res://scenes/run/Run.tscn")
	else:
		print("No active run to continue")

func _update_continue_button() -> void:
	if not GameManager.run_active:
		continue_button.disabled = true
		continue_button.modulate = Color(0.7, 0.7, 0.7, 1.0)  # Dim the button
	else:
		continue_button.disabled = false
		continue_button.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Full opacity

func _on_options_pressed() -> void:
	# TODO: Implement options menu
	print("Options button pressed - not yet implemented")

func _on_collection_pressed() -> void:
	# TODO: Implement collection view
	print("Collection button pressed - not yet implemented")
