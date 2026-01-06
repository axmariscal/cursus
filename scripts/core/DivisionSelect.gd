extends Control

# Division selection scene - Balatro-style deck selection

@onready var division_grid: GridContainer = %DivisionGrid
@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle
@onready var back_button: Button = %BackButton

var division_cards: Array[Control] = []

func _ready() -> void:
	_style_ui()
	_create_division_cards()
	_connect_signals()

func _style_ui() -> void:
	# Style title
	title_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))  # Gold
	subtitle_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 0.9))
	
	# Style back button
	var back_style = StyleBoxFlat.new()
	back_style.bg_color = Color(0.8, 0.3, 0.3)
	back_style.corner_radius_top_left = 5
	back_style.corner_radius_top_right = 5
	back_style.corner_radius_bottom_right = 5
	back_style.corner_radius_bottom_left = 5
	back_button.add_theme_stylebox_override("normal", back_style)
	
	var back_hover = StyleBoxFlat.new()
	back_hover.bg_color = Color(0.9, 0.4, 0.4)
	back_hover.corner_radius_top_left = 5
	back_hover.corner_radius_top_right = 5
	back_hover.corner_radius_bottom_right = 5
	back_hover.corner_radius_bottom_left = 5
	back_button.add_theme_stylebox_override("hover", back_hover)

func _connect_signals() -> void:
	back_button.pressed.connect(_on_back_pressed)

func _create_division_cards() -> void:
	# Clear existing cards
	for card in division_cards:
		card.queue_free()
	division_cards.clear()
	
	# Create cards for each division
	var division_order = [
		GameManager.Division.MIDDLE_SCHOOL,
		GameManager.Division.HIGH_SCHOOL,
		GameManager.Division.JUNIOR_COLLEGE,
		GameManager.Division.D3,
		GameManager.Division.D2,
		GameManager.Division.D1,
		GameManager.Division.POST_COLLEGIATE,
		GameManager.Division.PROFESSIONAL,
		GameManager.Division.WORLD_CONTENDER
	]
	
	for division in division_order:
		var card = _create_division_card(division)
		if card:
			division_grid.add_child(card)
			division_cards.append(card)

func _create_division_card(division: GameManager.Division) -> Control:
	var config = GameManager.get_division_config(division)
	if config.is_empty():
		return null
	
	var is_unlocked = GameManager.is_division_unlocked(division)
	
	# Create card container
	var card_container = PanelContainer.new()
	card_container.custom_minimum_size = Vector2(200, 280)
	
	# Card margin
	var card_margin = MarginContainer.new()
	card_margin.set("theme_override_constants/margin_left", 15)
	card_margin.set("theme_override_constants/margin_top", 15)
	card_margin.set("theme_override_constants/margin_right", 15)
	card_margin.set("theme_override_constants/margin_bottom", 15)
	card_container.add_child(card_margin)
	
	# Card content
	var card_content = VBoxContainer.new()
	card_content.add_theme_constant_override("separation", 8)
	card_margin.add_child(card_content)
	
	# Division name
	var name_label = Label.new()
	name_label.text = config.get("name", "Unknown")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	card_content.add_child(name_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = config.get("description", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	card_content.add_child(desc_label)
	
	# Stats section
	var stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 4)
	card_content.add_child(stats_container)
	
	# Starting gold
	var gold_label = Label.new()
	gold_label.text = "💰 %d Gold" % config.get("starting_gold", 100)
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 11)
	stats_container.add_child(gold_label)
	
	# Antes (races)
	var antes_label = Label.new()
	antes_label.text = "🏃 %d Races" % config.get("antes", 5)
	antes_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	antes_label.add_theme_font_size_override("font_size", 11)
	stats_container.add_child(antes_label)
	
	# Reward multiplier
	var reward_label = Label.new()
	var multiplier = config.get("reward_multiplier", 1.0)
	reward_label.text = "🏆 %.1fx Rewards" % multiplier
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 11)
	stats_container.add_child(reward_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	card_content.add_child(spacer)
	
	# Select button
	var select_button = Button.new()
	select_button.text = "Select" if is_unlocked else "Locked"
	select_button.disabled = not is_unlocked
	select_button.custom_minimum_size = Vector2(0, 35)
	select_button.pressed.connect(_on_division_selected.bind(division))
	card_content.add_child(select_button)
	
	# Style the card
	_style_division_card(card_container, is_unlocked, config)
	
	# Style the button
	_style_division_button(select_button, is_unlocked)
	
	return card_container

func _style_division_card(card: PanelContainer, is_unlocked: bool, config: Dictionary) -> void:
	var card_style = StyleBoxFlat.new()
	
	if is_unlocked:
		# Unlocked: bright colors
		card_style.bg_color = Color(0.99, 0.98, 0.96, 1.0)
		card_style.border_color = Color(0.3, 0.5, 0.8, 0.8)
	else:
		# Locked: dimmed
		card_style.bg_color = Color(0.7, 0.7, 0.7, 0.5)
		card_style.border_color = Color(0.4, 0.4, 0.4, 0.6)
		card.modulate = Color(0.6, 0.6, 0.6, 1.0)  # Dim the whole card
	
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_right = 8
	card_style.corner_radius_bottom_left = 8
	
	card.add_theme_stylebox_override("panel", card_style)

func _style_division_button(button: Button, is_unlocked: bool) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.corner_radius_top_left = 5
	style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_right = 5
	style_normal.corner_radius_bottom_left = 5
	
	if is_unlocked:
		style_normal.bg_color = Color(0.2, 0.6, 0.9)
		button.add_theme_color_override("font_color", Color.WHITE)
	else:
		style_normal.bg_color = Color(0.4, 0.4, 0.4)
		button.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	button.add_theme_stylebox_override("normal", style_normal)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.corner_radius_top_left = 5
	style_hover.corner_radius_top_right = 5
	style_hover.corner_radius_bottom_right = 5
	style_hover.corner_radius_bottom_left = 5
	style_hover.bg_color = style_normal.bg_color.lightened(0.15)
	button.add_theme_stylebox_override("hover", style_hover)

func _on_division_selected(division: GameManager.Division) -> void:
	# Start new run with selected division
	GameManager.start_new_run(division)
	get_tree().change_scene_to_file("res://scenes/run/Run.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/core/Main.tscn")

