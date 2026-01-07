extends Control

# Division selection scene - Single card view with arrow navigation

@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle
@onready var back_button: Button = %BackButton
@onready var division_card_container: Control = %DivisionCardContainer
@onready var prev_button: Button = %PrevButton
@onready var next_button: Button = %NextButton
@onready var select_button: Button = %SelectButton

var division_order: Array[GameManager.Division] = []
var current_index: int = 0
var current_card: Control = null

func _ready() -> void:
	# Initialize division order
	division_order = [
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
	
	# Find first unlocked division
	current_index = 0
	for i in range(division_order.size()):
		if GameManager.is_division_unlocked(division_order[i]):
			current_index = i
			break
	
	_style_ui()
	_connect_signals()
	_display_current_division()

func _style_ui() -> void:
	# Style title - dark grey
	title_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	subtitle_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	
	# Style back button
	var back_style = StyleBoxFlat.new()
	back_style.bg_color = Color(0.6, 0.6, 0.6)
	back_style.corner_radius_top_left = 5
	back_style.corner_radius_top_right = 5
	back_style.corner_radius_bottom_right = 5
	back_style.corner_radius_bottom_left = 5
	back_button.add_theme_stylebox_override("normal", back_style)
	back_button.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	
	var back_hover = StyleBoxFlat.new()
	back_hover.bg_color = Color(0.7, 0.7, 0.7)
	back_hover.corner_radius_top_left = 5
	back_hover.corner_radius_top_right = 5
	back_hover.corner_radius_bottom_right = 5
	back_hover.corner_radius_bottom_left = 5
	back_button.add_theme_stylebox_override("hover", back_hover)

func _connect_signals() -> void:
	back_button.pressed.connect(_on_back_pressed)
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	select_button.pressed.connect(_on_select_pressed)

func _display_current_division() -> void:
	# Clear existing card
	if current_card:
		current_card.queue_free()
		current_card = null
	
	# Get current division
	var division = division_order[current_index]
	var card = _create_division_card(division)
	if card:
		division_card_container.add_child(card)
		current_card = card
	
	# Update navigation buttons
	prev_button.disabled = current_index == 0
	next_button.disabled = current_index >= division_order.size() - 1
	
	# Update select button
	var is_unlocked = GameManager.is_division_unlocked(division)
	select_button.disabled = not is_unlocked
	if is_unlocked:
		select_button.text = "Select Division"
	else:
		select_button.text = "Locked"
	
	_style_division_button(select_button, is_unlocked)
	
	# Update division counter
	var counter_text = "%d / %d" % [current_index + 1, division_order.size()]
	# You can add a label for this if needed

func _create_division_card(division: GameManager.Division) -> Control:
	var config = GameManager.get_division_config(division)
	if config.is_empty():
		return null
	
	var is_unlocked = GameManager.is_division_unlocked(division)
	var is_new = GameManager.is_division_newly_unlocked(division) if is_unlocked else false
	
	# Create card container with relative positioning for overlays - responsive size
	var card_container = PanelContainer.new()
	# Use smaller, more flexible size that fits on most screens
	card_container.custom_minimum_size = Vector2(400, 500)
	# Allow it to shrink if needed
	card_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Card margin - reasonable margins
	var card_margin = MarginContainer.new()
	card_margin.set("theme_override_constants/margin_left", 20)
	card_margin.set("theme_override_constants/margin_top", 20)
	card_margin.set("theme_override_constants/margin_right", 20)
	card_margin.set("theme_override_constants/margin_bottom", 20)
	card_container.add_child(card_margin)
	
	# Card content
	var card_content = VBoxContainer.new()
	card_content.add_theme_constant_override("separation", 8)
	card_margin.add_child(card_content)
	
	# NEW badge (if newly unlocked) - positioned at top
	if is_new:
		var new_badge = _create_new_badge()
		card_content.add_child(new_badge)
	
	# Division name - dark grey, slightly smaller
	var name_label = Label.new()
	name_label.text = config.get("name", "Unknown")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	card_content.add_child(name_label)
	
	# Description - dark grey, compact
	var desc_label = Label.new()
	desc_label.text = config.get("description", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	desc_label.custom_minimum_size = Vector2(350, 0)  # Constrain width
	card_content.add_child(desc_label)
	
	# Difficulty indicator
	var difficulty_container = _create_difficulty_indicator(config.get("difficulty_curve", 0.15))
	card_content.add_child(difficulty_container)
	
	# Separator before stats
	var separator = HSeparator.new()
	card_content.add_child(separator)
	
	# Stats section
	var stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 8)
	card_content.add_child(stats_container)
	
	# Starting gold with icon
	var gold_row = _create_stat_row("💰", "%d Gold" % config.get("starting_gold", 100))
	stats_container.add_child(gold_row)
	
	# Antes (races) with icon
	var antes_row = _create_stat_row("🏃", "%d Races" % config.get("antes", 5))
	stats_container.add_child(antes_row)
	
	# Reward multiplier with icon
	var multiplier = config.get("reward_multiplier", 1.0)
	var reward_row = _create_stat_row("🏆", "%.1fx Rewards" % multiplier)
	stats_container.add_child(reward_row)
	
	# Special rules section (if any)
	var special_rules = config.get("special_rules", [])
	if special_rules.size() > 0:
		var rules_container = _create_special_rules_section(special_rules)
		card_content.add_child(rules_container)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	card_content.add_child(spacer)
	
	# Don't add select button here - it's in the main UI
	# Style the card
	_style_division_card(card_container, is_unlocked, config)
	
	return card_container

func _create_new_badge() -> Control:
	var badge_container = MarginContainer.new()
	badge_container.set("theme_override_constants/margin_left", -10)
	badge_container.set("theme_override_constants/margin_right", -10)
	
	var badge = Label.new()
	badge.text = "✨ NEW ✨"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 16)
	badge.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))  # Dark grey
	
	# Style badge background
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = Color(0.9, 0.7, 0.2, 0.2)  # Light gold background
	badge_style.border_color = Color(0.9, 0.7, 0.2, 0.8)
	badge_style.border_width_left = 1
	badge_style.border_width_top = 1
	badge_style.border_width_right = 1
	badge_style.border_width_bottom = 1
	badge_style.corner_radius_top_left = 4
	badge_style.corner_radius_top_right = 4
	badge_style.corner_radius_bottom_right = 4
	badge_style.corner_radius_bottom_left = 4
	
	var badge_panel = PanelContainer.new()
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	badge_panel.add_child(badge)
	badge_container.add_child(badge_panel)
	
	return badge_container

func _create_difficulty_indicator(difficulty_curve: float) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	
	var label = Label.new()
	label.text = "Difficulty"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))  # Dark grey
	container.add_child(label)
	
	# Create visual difficulty bar using ProgressBar for better control
	var bar_container = MarginContainer.new()
	bar_container.set("theme_override_constants/margin_left", 10)
	bar_container.set("theme_override_constants/margin_right", 10)
	bar_container.custom_minimum_size = Vector2(0, 12)
	
	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 8)
	progress_bar.max_value = 100.0
	progress_bar.show_percentage = false
	
	# Calculate difficulty percentage (0.10 to 0.35 range -> 0 to 100%)
	var difficulty_percent = ((difficulty_curve - 0.10) / 0.25) * 100.0
	difficulty_percent = clamp(difficulty_percent, 0.0, 100.0)
	progress_bar.value = difficulty_percent
	
	# Style the progress bar
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.3, 0.3, 0.3, 0.3)
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_right = 2
	bg_style.corner_radius_bottom_left = 2
	progress_bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = _get_difficulty_color(difficulty_curve)
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_right = 2
	fill_style.corner_radius_bottom_left = 2
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	bar_container.add_child(progress_bar)
	container.add_child(bar_container)
	
	return container

func _get_difficulty_color(difficulty: float) -> Color:
	# Color gradient from green (easy) to red (hard)
	if difficulty < 0.15:
		return Color(0.3, 0.8, 0.3)  # Green
	elif difficulty < 0.22:
		return Color(0.8, 0.8, 0.3)  # Yellow
	elif difficulty < 0.28:
		return Color(0.8, 0.6, 0.2)  # Orange
	else:
		return Color(0.8, 0.3, 0.3)  # Red

func _create_stat_row(icon: String, text: String) -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 16)
	row.add_child(icon_label)
	
	var text_label = Label.new()
	text_label.text = text
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))  # Dark grey
	row.add_child(text_label)
	
	return row

func _create_special_rules_section(rules: Array) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	
	var header = Label.new()
	header.text = "Special Rules:"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))  # Dark grey
	container.add_child(header)
	
	for rule in rules:
		var rule_label = Label.new()
		rule_label.text = "• " + _format_rule_name(rule)
		rule_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rule_label.add_theme_font_size_override("font_size", 12)
		rule_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))  # Dark grey
		rule_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(rule_label)
	
	return container

func _format_rule_name(rule: String) -> String:
	match rule:
		"limited_funding":
			return "Limited Funding"
		"contracts":
			return "Contracts"
		"sponsorships":
			return "Sponsorships"
		"no_consolation":
			return "No Consolation Gold"
		"elite_opponents":
			return "Elite Opponents"
		_:
			return rule.capitalize()

func _style_division_card(card: PanelContainer, is_unlocked: bool, config: Dictionary) -> void:
	var card_style = StyleBoxFlat.new()
	
	if is_unlocked:
		# Unlocked: light background for dark text
		var difficulty = config.get("difficulty_curve", 0.15)
		var accent_color = _get_difficulty_color(difficulty).darkened(0.2)
		
		card_style.bg_color = Color(0.95, 0.95, 0.95, 1.0)  # Light grey/white background
		card_style.border_color = accent_color
	else:
		# Locked: dimmed but still readable
		card_style.bg_color = Color(0.85, 0.85, 0.85, 0.8)
		card_style.border_color = Color(0.5, 0.5, 0.5, 0.8)
		card.modulate = Color(0.7, 0.7, 0.7, 1.0)  # Slightly dimmed
	
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
		style_normal.bg_color = Color(0.4, 0.6, 0.8)
		button.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))  # Dark grey text
	else:
		style_normal.bg_color = Color(0.5, 0.5, 0.5)
		button.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))  # Dark grey text
	
	button.add_theme_stylebox_override("normal", style_normal)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.corner_radius_top_left = 5
	style_hover.corner_radius_top_right = 5
	style_hover.corner_radius_bottom_right = 5
	style_hover.corner_radius_bottom_left = 5
	style_hover.bg_color = style_normal.bg_color.lightened(0.15)
	button.add_theme_stylebox_override("hover", style_hover)

func _on_prev_pressed() -> void:
	if current_index > 0:
		current_index -= 1
		_display_current_division()

func _on_next_pressed() -> void:
	if current_index < division_order.size() - 1:
		current_index += 1
		_display_current_division()

func _on_select_pressed() -> void:
	var division = division_order[current_index]
	_on_division_selected(division)

func _on_division_selected(division: GameManager.Division) -> void:
	# Mark as viewed (remove "NEW" badge)
	GameManager.mark_division_viewed(division)
	
	# Start new run with selected division
	GameManager.start_new_run(division)
	
	# Show draft before first race for all divisions (at ante 1)
	# The draft will only show if draft_completed is false (which it is for new runs)
	get_tree().change_scene_to_file("res://scenes/core/DraftScene.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/core/Main.tscn")
