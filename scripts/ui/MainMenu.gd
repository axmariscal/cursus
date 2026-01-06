extends Control

# Base resolution for scaling calculations (1080p as reference)
const BASE_WIDTH = 1920.0
const BASE_HEIGHT = 1080.0
const MAX_CLIPBOARD_WIDTH = 1200.0  # Maximum width for clipboard panel

# Scaling factor
var scale_factor: float = 1.0

# Clipboard and panel references
@onready var clipboard_panel: PanelContainer = %ClipboardPanel
@onready var clipboard_container: MarginContainer = get_node("UI/ClipboardContainer")
@onready var divider_line: ColorRect = %DividerLine
@onready var version_label: Label = %VersionLabel
@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle

# Card references
@onready var menu_grid: GridContainer = %MenuGrid
@onready var new_run_card: PanelContainer = %NewRunCard
@onready var continue_card: PanelContainer = %ContinueCard
@onready var collection_card: PanelContainer = %CollectionCard
@onready var options_card: PanelContainer = %OptionsCard

# Button references
@onready var new_run_button: Button = new_run_card.get_node("CardMargin/CardContent/CardButton")
@onready var continue_button: Button = continue_card.get_node("CardMargin/CardContent/CardButton")
@onready var collection_button: Button = collection_card.get_node("CardMargin/CardContent/CardButton")
@onready var options_button: Button = options_card.get_node("CardMargin/CardContent/CardButton")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_calculate_scale_factor()
	_apply_scaling()
	_style_clipboard()
	_style_cards()
	_style_labels()
	_connect_signals()
	_setup_responsive_layout()
	
	# Update layout when window is resized
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _calculate_scale_factor() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	# Use the smaller dimension to maintain aspect ratio, or use width for UI scaling
	scale_factor = min(viewport_size.x / BASE_WIDTH, viewport_size.y / BASE_HEIGHT)
	# Clamp scale factor to reasonable bounds
	scale_factor = clamp(scale_factor, 0.5, 2.0)

func _apply_scaling() -> void:
	# Constrain clipboard container width on large displays
	var viewport_width = get_viewport().get_visible_rect().size.x
	var max_scaled_width = MAX_CLIPBOARD_WIDTH * scale_factor
	
	if viewport_width > max_scaled_width:
		# Center the clipboard panel with max width constraint
		var available_width = viewport_width
		var target_width = min(available_width, MAX_CLIPBOARD_WIDTH * scale_factor)
		var side_margin = (available_width - target_width) / 2.0
		clipboard_container.set("theme_override_constants/margin_left", side_margin)
		clipboard_container.set("theme_override_constants/margin_right", side_margin)
		# Keep vertical margins proportional
		var v_margin = 40.0 * scale_factor
		clipboard_container.set("theme_override_constants/margin_top", v_margin)
		clipboard_container.set("theme_override_constants/margin_bottom", v_margin)
	else:
		# Use proportional margins
		var margin = 40.0 * scale_factor
		clipboard_container.set("theme_override_constants/margin_left", margin)
		clipboard_container.set("theme_override_constants/margin_right", margin)
		clipboard_container.set("theme_override_constants/margin_top", margin)
		clipboard_container.set("theme_override_constants/margin_bottom", margin)
	
	# Scale content spacer
	var content_spacer = get_node_or_null("UI/ClipboardContainer/ClipboardPanel/ClipboardMargin/ClipboardContent/ContentSpacer")
	if content_spacer:
		var spacer_height = max(20, int(30 * scale_factor))
		content_spacer.custom_minimum_size = Vector2(0, spacer_height)
	
	# Scale clipboard margin
	var clipboard_margin = get_node_or_null("UI/ClipboardContainer/ClipboardPanel/ClipboardMargin")
	if clipboard_margin:
		var margin = max(20, int(30 * scale_factor))
		clipboard_margin.set("theme_override_constants/margin_left", margin)
		clipboard_margin.set("theme_override_constants/margin_top", margin)
		clipboard_margin.set("theme_override_constants/margin_right", margin)
		clipboard_margin.set("theme_override_constants/margin_bottom", margin)
	
	# Scale card margins
	var card_margin_size = max(15, int(20 * scale_factor))
	for card in [new_run_card, continue_card, collection_card, options_card]:
		var card_margin = card.get_node_or_null("CardMargin")
		if card_margin:
			card_margin.set("theme_override_constants/margin_left", card_margin_size)
			card_margin.set("theme_override_constants/margin_top", card_margin_size)
			card_margin.set("theme_override_constants/margin_right", card_margin_size)
			card_margin.set("theme_override_constants/margin_bottom", card_margin_size)

func _style_clipboard() -> void:
	# Style the main clipboard panel - paper-like appearance
	var clipboard_style = StyleBoxFlat.new()
	clipboard_style.bg_color = Color(0.98, 0.97, 0.95, 1.0)  # Slightly whiter than background
	clipboard_style.border_color = Color(0.6, 0.5, 0.4, 0.8)  # Brown border like clipboard edge
	
	# Scale border widths
	var border_width = max(2, int(3 * scale_factor))
	clipboard_style.border_width_left = border_width
	clipboard_style.border_width_top = border_width
	clipboard_style.border_width_right = border_width
	clipboard_style.border_width_bottom = border_width
	
	# Scale corner radius
	var corner_radius = max(1, int(2 * scale_factor))
	clipboard_style.corner_radius_top_left = corner_radius
	clipboard_style.corner_radius_top_right = corner_radius
	clipboard_style.corner_radius_bottom_right = corner_radius
	clipboard_style.corner_radius_bottom_left = corner_radius
	clipboard_panel.add_theme_stylebox_override("panel", clipboard_style)
	
	# Style divider line - scale height
	var divider_height = max(1, int(2 * scale_factor))
	divider_line.custom_minimum_size = Vector2(0, divider_height)
	divider_line.color = Color(0.7, 0.6, 0.5, 0.4)  # Subtle brown line

func _style_cards() -> void:
	# Style each card with clipboard theme
	_style_card(new_run_card, Color(0.2, 0.6, 0.9))  # Blue
	_style_card(continue_card, Color(0.3, 0.8, 0.4))  # Green
	_style_card(collection_card, Color(0.9, 0.5, 0.2))  # Orange
	_style_card(options_card, Color(0.7, 0.4, 0.9))  # Purple
	
	# Style buttons within cards
	_style_card_button(new_run_button, Color(0.2, 0.6, 0.9))
	_style_card_button(continue_button, Color(0.3, 0.8, 0.4))
	_style_card_button(collection_button, Color(0.9, 0.5, 0.2))
	_style_card_button(options_button, Color(0.7, 0.4, 0.9))

func _style_card(card: PanelContainer, accent_color: Color) -> void:
	# Card background - subtle paper texture effect
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.99, 0.98, 0.96, 1.0)  # Very light paper color
	card_style.border_color = accent_color.darkened(0.3)
	
	# Scale border widths
	var border_width = max(1, int(2 * scale_factor))
	card_style.border_width_left = border_width
	card_style.border_width_top = border_width
	card_style.border_width_right = border_width
	card_style.border_width_bottom = border_width
	
	# Scale corner radius
	var corner_radius = max(2, int(4 * scale_factor))
	card_style.corner_radius_top_left = corner_radius
	card_style.corner_radius_top_right = corner_radius
	card_style.corner_radius_bottom_right = corner_radius
	card_style.corner_radius_bottom_left = corner_radius
	card.add_theme_stylebox_override("panel", card_style)

func _style_card_button(button: Button, color: Color) -> void:
	var corner_radius = max(2, int(4 * scale_factor))
	
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
	
	# Scale button height
	var button_height = max(30, int(40 * scale_factor))
	button.custom_minimum_size = Vector2(0, button_height)

func _style_labels() -> void:
	# Scale font sizes
	var title_size = max(32, int(64 * scale_factor))
	var subtitle_size = max(12, int(18 * scale_factor))
	var card_title_size = max(14, int(20 * scale_factor))
	var card_desc_size = max(10, int(12 * scale_factor))
	var card_icon_size = max(20, int(32 * scale_factor))
	
	# Apply scaled font sizes
	title_label.add_theme_font_size_override("font_size", title_size)
	subtitle_label.add_theme_font_size_override("font_size", subtitle_size)
	
	# Style title with bold color
	title_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))  # Gold/Amber
	title_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.1, 0.1, 0.8))
	var shadow_offset = max(1, int(2 * scale_factor))
	title_label.add_theme_constant_override("shadow_offset_x", shadow_offset)
	title_label.add_theme_constant_override("shadow_offset_y", shadow_offset)
	
	# Style subtitle
	subtitle_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 0.9))
	
	# Style version label (footer)
	version_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.8))
	
	# Style card titles and descriptions
	var card_titles = [
		new_run_card.get_node("CardMargin/CardContent/CardTitle"),
		continue_card.get_node("CardMargin/CardContent/CardTitle"),
		collection_card.get_node("CardMargin/CardContent/CardTitle"),
		options_card.get_node("CardMargin/CardContent/CardTitle")
	]
	
	for title in card_titles:
		title.add_theme_font_size_override("font_size", card_title_size)
		title.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1.0))
	
	var card_descriptions = [
		new_run_card.get_node("CardMargin/CardContent/CardDescription"),
		continue_card.get_node("CardMargin/CardContent/CardDescription"),
		collection_card.get_node("CardMargin/CardContent/CardDescription"),
		options_card.get_node("CardMargin/CardContent/CardDescription")
	]
	
	for desc in card_descriptions:
		desc.add_theme_font_size_override("font_size", card_desc_size)
		desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.9))
	
	# Scale card icons
	var card_icons = [
		new_run_card.get_node("CardMargin/CardContent/CardIcon"),
		continue_card.get_node("CardMargin/CardContent/CardIcon"),
		collection_card.get_node("CardMargin/CardContent/CardIcon"),
		options_card.get_node("CardMargin/CardContent/CardIcon")
	]
	
	for icon in card_icons:
		icon.add_theme_font_size_override("font_size", card_icon_size)

func _connect_signals() -> void:
	# Connect button signals
	new_run_button.pressed.connect(_on_new_run_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	collection_button.pressed.connect(_on_collection_pressed)
	options_button.pressed.connect(_on_options_pressed)
	
	# Update continue button state based on active run
	_update_continue_button()

func _setup_responsive_layout() -> void:
	# Adjust grid columns based on viewport width
	_on_viewport_size_changed()

func _on_viewport_size_changed() -> void:
	# Recalculate scale factor
	_calculate_scale_factor()
	
	# Reapply scaling
	_apply_scaling()
	_style_clipboard()
	_style_cards()
	_style_labels()
	
	# Update grid columns based on viewport width
	var viewport_width = get_viewport().get_visible_rect().size.x
	var grid_breakpoint = 1000.0 * scale_factor
	
	# Use a more reasonable breakpoint (scaled)
	if viewport_width < grid_breakpoint:
		menu_grid.columns = 1
	else:
		menu_grid.columns = 2

func _update_continue_button() -> void:
	if not GameManager.run_active:
		continue_button.disabled = true
		continue_card.modulate = Color(0.7, 0.7, 0.7, 1.0)  # Dim the card
	else:
		continue_button.disabled = false
		continue_card.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Full opacity

func _on_new_run_pressed() -> void:
	# Navigate to division selection scene
	get_tree().change_scene_to_file("res://scenes/core/DivisionSelectScene.tscn")

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
