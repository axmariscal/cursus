extends Control

# Clipboard and panel references
@onready var clipboard_panel: PanelContainer = $UI/ClipboardContainer/ClipboardPanel
@onready var divider_line: ColorRect = $UI/ClipboardContainer/ClipboardPanel/ClipboardMargin/ClipboardContent/DividerLine
@onready var version_label: Label = $UI/ClipboardContainer/ClipboardPanel/ClipboardMargin/ClipboardContent/FooterSection/VersionLabel
@onready var title_label: Label = $UI/ClipboardContainer/ClipboardPanel/ClipboardMargin/ClipboardContent/HeaderSection/TitleContainer/Title
@onready var subtitle_label: Label = $UI/ClipboardContainer/ClipboardPanel/ClipboardMargin/ClipboardContent/HeaderSection/TitleContainer/Subtitle

# Card references
@onready var menu_grid: GridContainer = $UI/ClipboardContainer/ClipboardPanel/ClipboardMargin/ClipboardContent/MenuGrid
@onready var new_run_card: PanelContainer = $UI/ClipboardContainer/ClipboardPanel/ClipboardMargin/ClipboardContent/MenuGrid/NewRunCard
@onready var continue_card: PanelContainer = $UI/ClipboardContainer/ClipboardPanel/ClipboardMargin/ClipboardContent/MenuGrid/ContinueCard
@onready var collection_card: PanelContainer = $UI/ClipboardContainer/ClipboardPanel/ClipboardMargin/ClipboardContent/MenuGrid/CollectionCard
@onready var options_card: PanelContainer = $UI/ClipboardContainer/ClipboardPanel/ClipboardMargin/ClipboardContent/MenuGrid/OptionsCard

# Button references
@onready var new_run_button: Button = new_run_card.get_node("CardMargin/CardContent/CardButton")
@onready var continue_button: Button = continue_card.get_node("CardMargin/CardContent/CardButton")
@onready var collection_button: Button = collection_card.get_node("CardMargin/CardContent/CardButton")
@onready var options_button: Button = options_card.get_node("CardMargin/CardContent/CardButton")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_style_clipboard()
	_style_cards()
	_style_labels()
	_connect_signals()
	_setup_responsive_layout()
	
	# Update layout when window is resized
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _style_clipboard() -> void:
	# Style the main clipboard panel - paper-like appearance
	var clipboard_style = StyleBoxFlat.new()
	clipboard_style.bg_color = Color(0.98, 0.97, 0.95, 1.0)  # Slightly whiter than background
	clipboard_style.border_color = Color(0.6, 0.5, 0.4, 0.8)  # Brown border like clipboard edge
	clipboard_style.border_width_left = 3
	clipboard_style.border_width_top = 3
	clipboard_style.border_width_right = 3
	clipboard_style.border_width_bottom = 3
	clipboard_style.corner_radius_top_left = 2
	clipboard_style.corner_radius_top_right = 2
	clipboard_style.corner_radius_bottom_right = 2
	clipboard_style.corner_radius_bottom_left = 2
	clipboard_panel.add_theme_stylebox_override("panel", clipboard_style)
	
	# Style divider line - subtle line like on paper
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
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 4
	card_style.corner_radius_top_right = 4
	card_style.corner_radius_bottom_right = 4
	card_style.corner_radius_bottom_left = 4
	card.add_theme_stylebox_override("panel", card_style)

func _style_card_button(button: Button, color: Color) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = color
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_right = 4
	style_normal.corner_radius_bottom_left = 4
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = color.lightened(0.15)
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_top_right = 4
	style_hover.corner_radius_bottom_right = 4
	style_hover.corner_radius_bottom_left = 4
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = color.darkened(0.2)
	style_pressed.corner_radius_top_left = 4
	style_pressed.corner_radius_top_right = 4
	style_pressed.corner_radius_bottom_right = 4
	style_pressed.corner_radius_bottom_left = 4
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)

func _style_labels() -> void:
	# Style version label (footer)
	version_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.8))
	
	# Style title with bold color
	title_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))  # Gold/Amber
	title_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.1, 0.1, 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Style subtitle
	subtitle_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 0.9))
	
	# Style card titles
	var card_titles = [
		new_run_card.get_node("CardMargin/CardContent/CardTitle"),
		continue_card.get_node("CardMargin/CardContent/CardTitle"),
		collection_card.get_node("CardMargin/CardContent/CardTitle"),
		options_card.get_node("CardMargin/CardContent/CardTitle")
	]
	
	for title in card_titles:
		title.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1.0))
	
	# Style card descriptions
	var card_descriptions = [
		new_run_card.get_node("CardMargin/CardContent/CardDescription"),
		continue_card.get_node("CardMargin/CardContent/CardDescription"),
		collection_card.get_node("CardMargin/CardContent/CardDescription"),
		options_card.get_node("CardMargin/CardContent/CardDescription")
	]
	
	for desc in card_descriptions:
		desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.9))

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
	var viewport_width = get_viewport().get_visible_rect().size.x
	# Switch to single column on smaller screens (< 800px)
	if viewport_width < 800:
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
