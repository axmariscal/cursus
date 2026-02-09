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
@onready var ui_canvas_layer: CanvasLayer = $UI

# Save slot dialog references (will be created dynamically)
var save_slot_dialog: Panel = null
var save_slot_overlay: ColorRect = null
var save_slot_buttons: Array[Button] = []
var save_slot_labels: Array[Label] = []

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
	# Show save slot selection dialog
	_show_save_slot_dialog()

func _update_continue_button() -> void:
	# Enable continue button if there's an active run OR if any save slots exist
	var has_saves = false
	for slot in range(1, GameManager.MAX_SAVE_SLOTS + 1):
		if GameManager.save_slot_exists(slot):
			has_saves = true
			break
	
	if not GameManager.run_active and not has_saves:
		continue_button.disabled = true
		continue_button.modulate = Color(0.7, 0.7, 0.7, 1.0)  # Dim the button
		continue_button.text = "CONTINUE"
	else:
		continue_button.disabled = false
		continue_button.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Full opacity
		if GameManager.run_active:
			continue_button.text = "CONTINUE"
		else:
			continue_button.text = "LOAD RUN"

func _on_options_pressed() -> void:
	# TODO: Implement options menu
	print("Options button pressed - not yet implemented")

func _on_collection_pressed() -> void:
	# TODO: Implement collection view
	print("Collection button pressed - not yet implemented")

func _show_save_slot_dialog() -> void:
	# Create dialog if it doesn't exist
	if save_slot_dialog == null:
		_create_save_slot_dialog()
	
	# Update dialog position (in case viewport size changed)
	_update_dialog_position()
	
	# Update slot information
	_update_save_slot_display()
	
	# Show overlay and dialog
	if save_slot_overlay:
		save_slot_overlay.visible = true
	save_slot_dialog.visible = true

func _update_dialog_position() -> void:
	if save_slot_dialog == null:
		return
	
	# Get the size of the MainMenu control (which should fill the viewport)
	var menu_size = size
	var dialog_width = min(600, menu_size.x * 0.8)
	var dialog_height = min(500, menu_size.y * 0.7)
	
	# Use full rect anchors and position manually
	save_slot_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	save_slot_dialog.offset_left = (menu_size.x - dialog_width) / 2
	save_slot_dialog.offset_top = (menu_size.y - dialog_height) / 2
	save_slot_dialog.offset_right = -(menu_size.x - dialog_width) / 2
	save_slot_dialog.offset_bottom = -(menu_size.y - dialog_height) / 2
	save_slot_dialog.custom_minimum_size = Vector2(dialog_width, dialog_height)

func _create_save_slot_dialog() -> void:
	# Create a new CanvasLayer specifically for the dialog with a higher layer value
	# This ensures it renders on top of the existing UI CanvasLayer
	var dialog_layer = CanvasLayer.new()
	dialog_layer.name = "DialogLayer"
	dialog_layer.layer = 10  # Higher than default UI layer (which is 0)
	add_child(dialog_layer)
	
	# Create a container Control inside the CanvasLayer to hold overlay and dialog
	var dialog_container = Control.new()
	dialog_container.name = "DialogContainer"
	dialog_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_layer.add_child(dialog_container)
	
	# Create overlay background (semi-transparent black)
	save_slot_overlay = ColorRect.new()
	save_slot_overlay.name = "SaveSlotOverlay"
	save_slot_overlay.color = Color(0, 0, 0, 0.75)  # Semi-transparent black
	save_slot_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	save_slot_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Block clicks behind
	dialog_container.add_child(save_slot_overlay)
	
	# Create main dialog panel
	save_slot_dialog = Panel.new()
	save_slot_dialog.name = "SaveSlotDialog"
	save_slot_dialog.mouse_filter = Control.MOUSE_FILTER_STOP  # Block clicks behind
	dialog_container.add_child(save_slot_dialog)
	
	# Style dialog - make it more opaque and visible
	var dialog_style = StyleBoxFlat.new()
	dialog_style.bg_color = Color(0.15, 0.15, 0.2, 1.0)  # More opaque, slightly blue-tinted
	dialog_style.corner_radius_top_left = 10
	dialog_style.corner_radius_top_right = 10
	dialog_style.corner_radius_bottom_right = 10
	dialog_style.corner_radius_bottom_left = 10
	dialog_style.border_color = Color(0.4, 0.5, 0.7, 1.0)  # Light blue border
	dialog_style.border_width_left = 2
	dialog_style.border_width_top = 2
	dialog_style.border_width_right = 2
	dialog_style.border_width_bottom = 2
	save_slot_dialog.add_theme_stylebox_override("panel", dialog_style)
	
	# Ensure dialog appears above overlay (add after overlay)
	save_slot_dialog.z_index = 1
	
	# Initial dialog size (will be updated when shown)
	save_slot_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	save_slot_dialog.custom_minimum_size = Vector2(600, 500)
	
	# Create container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	save_slot_dialog.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "LOAD RUN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	vbox.add_child(title)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "Select a save slot to load:"
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 18)
	instructions.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	vbox.add_child(instructions)
	
	# Create slot buttons
	for slot in range(1, GameManager.MAX_SAVE_SLOTS + 1):
		var slot_container = VBoxContainer.new()
		slot_container.add_theme_constant_override("separation", 5)
		
		var slot_button = Button.new()
		slot_button.custom_minimum_size = Vector2(0, 80)
		slot_button.name = "SlotButton" + str(slot)
		
		# Style button
		var button_style = StyleBoxFlat.new()
		button_style.bg_color = Color(0.3, 0.5, 0.7, 1.0)
		button_style.corner_radius_top_left = 5
		button_style.corner_radius_top_right = 5
		button_style.corner_radius_bottom_right = 5
		button_style.corner_radius_bottom_left = 5
		slot_button.add_theme_stylebox_override("normal", button_style)
		
		var hover_style = button_style.duplicate()
		hover_style.bg_color = Color(0.4, 0.6, 0.8, 1.0)
		slot_button.add_theme_stylebox_override("hover", hover_style)
		
		slot_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		slot_button.add_theme_font_size_override("font_size", 16)
		
		# Connect signal
		slot_button.pressed.connect(_on_save_slot_selected.bind(slot))
		
		# Create label for slot info
		var slot_label = Label.new()
		slot_label.name = "SlotLabel" + str(slot)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.add_theme_font_size_override("font_size", 14)
		slot_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		slot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		slot_container.add_child(slot_button)
		slot_container.add_child(slot_label)
		vbox.add_child(slot_container)
		
		save_slot_buttons.append(slot_button)
		save_slot_labels.append(slot_label)
	
	# Cancel button
	var cancel_button = Button.new()
	cancel_button.text = "CANCEL"
	cancel_button.custom_minimum_size = Vector2(0, 50)
	cancel_button.pressed.connect(_on_cancel_save_slot_dialog)
	
	var cancel_style = StyleBoxFlat.new()
	cancel_style.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	cancel_style.corner_radius_top_left = 5
	cancel_style.corner_radius_top_right = 5
	cancel_style.corner_radius_bottom_right = 5
	cancel_style.corner_radius_bottom_left = 5
	cancel_button.add_theme_stylebox_override("normal", cancel_style)
	cancel_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	vbox.add_child(cancel_button)
	
	# Initially hide overlay and dialog
	save_slot_overlay.visible = false
	save_slot_dialog.visible = false

func _update_save_slot_display() -> void:
	for i in range(GameManager.MAX_SAVE_SLOTS):
		var slot = i + 1
		var metadata = GameManager.get_save_slot_metadata(slot)
		var button = save_slot_buttons[i]
		var label = save_slot_labels[i]
		
		if metadata.is_empty() or not metadata.get("exists", false):
			# Empty slot
			button.text = "Slot %d - Empty" % slot
			label.text = "No save file"
			button.disabled = true
			button.modulate = Color(0.5, 0.5, 0.5, 1.0)
		else:
			# Populated slot
			var division = metadata.get("division", "Unknown")
			var ante = metadata.get("ante", 1)
			var gold = metadata.get("gold", 0)
			var date = metadata.get("date_string", "")
			
			button.text = "Slot %d - %s" % [slot, division]
			label.text = "Ante %d | %d Gold | %s" % [ante, gold, date]
			button.disabled = false
			button.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_save_slot_selected(slot: int) -> void:
	# Load the selected save slot
	if GameManager.load_run(slot):
		# Successfully loaded - navigate to Run scene
		if save_slot_overlay:
			save_slot_overlay.visible = false
		save_slot_dialog.visible = false
		get_tree().change_scene_to_file("res://scenes/run/Run.tscn")
	else:
		# Failed to load - show error (could add error label to dialog)
		print("Failed to load save slot ", slot)

func _on_cancel_save_slot_dialog() -> void:
	if save_slot_overlay:
		save_slot_overlay.visible = false
	save_slot_dialog.visible = false
