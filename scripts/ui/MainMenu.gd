extends Control

@onready var version_label: Label = $UI/VersionLabel
@onready var title_label: Label = $UI/CenterContainer/VBoxContainer/Title
@onready var new_run_button: Button = get_node("UI/CenterContainer/VBoxContainer/New Run")
@onready var continue_button: Button = $UI/CenterContainer/VBoxContainer/Continue
@onready var collection_button: Button = $UI/CenterContainer/VBoxContainer/Collection
@onready var options_button: Button = $UI/CenterContainer/VBoxContainer/Options

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Style version label (top left corner)
	version_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.8))  # Gray, slightly transparent
	
	# Style title with a bold color
	title_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))  # Gold/Amber
	title_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.1, 0.1, 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	
	# Style buttons with colors
	_style_button(new_run_button, Color(0.2, 0.6, 0.9))  # Blue
	_style_button(continue_button, Color(0.3, 0.8, 0.4))  # Green
	_style_button(collection_button, Color(0.9, 0.5, 0.2))  # Orange
	_style_button(options_button, Color(0.7, 0.4, 0.9))  # Purple
	
	# Connect button signals
	new_run_button.pressed.connect(_on_new_run_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	collection_button.pressed.connect(_on_collection_pressed)
	options_button.pressed.connect(_on_options_pressed)

func _style_button(button: Button, color: Color) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = color
	style_normal.corner_radius_top_left = 5
	style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_right = 5
	style_normal.corner_radius_bottom_left = 5
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = color.lightened(0.2)
	style_hover.corner_radius_top_left = 5
	style_hover.corner_radius_top_right = 5
	style_hover.corner_radius_bottom_right = 5
	style_hover.corner_radius_bottom_left = 5
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = color.darkened(0.2)
	style_pressed.corner_radius_top_left = 5
	style_pressed.corner_radius_top_right = 5
	style_pressed.corner_radius_bottom_right = 5
	style_pressed.corner_radius_bottom_left = 5
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)

func _on_new_run_pressed() -> void:
	# Start a new run and transition to Run scene
	GameManager.start_new_run()
	get_tree().change_scene_to_file("res://scenes/run/Run.tscn")

func _on_continue_pressed() -> void:
	# Continue existing run if one is active
	if GameManager.run_active:
		get_tree().change_scene_to_file("res://scenes/run/Run.tscn")
	else:
		print("No active run to continue")

func _on_collection_pressed() -> void:
	# TODO: Implement collection view
	print("Collection button pressed - not yet implemented")

func _on_options_pressed() -> void:
	# TODO: Implement options menu
	print("Options button pressed - not yet implemented")
