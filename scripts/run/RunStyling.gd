extends Node
class_name RunStyling

# Styling utilities for UI elements

func style_panels(header_bar: PanelContainer, tooltip_panel: Panel, result_panel: Panel) -> void:
	# Style header bar - lighter to match background
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.949, 0.918, 0.843, 0.8)  # Match background with slight transparency
	header_style.border_color = Color(0.5, 0.5, 0.5, 0.6)
	header_style.border_width_left = 1
	header_style.border_width_top = 1
	header_style.border_width_right = 1
	header_style.border_width_bottom = 2
	header_style.corner_radius_top_left = 3
	header_style.corner_radius_top_right = 3
	header_style.corner_radius_bottom_right = 3
	header_style.corner_radius_bottom_left = 3
	header_bar.add_theme_stylebox_override("panel", header_style)
	
	# Style tooltip
	var tooltip_style = StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	tooltip_style.border_color = Color(0.5, 0.5, 0.5, 1.0)
	tooltip_style.border_width_left = 2
	tooltip_style.border_width_top = 2
	tooltip_style.border_width_right = 2
	tooltip_style.border_width_bottom = 2
	tooltip_style.corner_radius_top_left = 5
	tooltip_style.corner_radius_top_right = 5
	tooltip_style.corner_radius_bottom_right = 5
	tooltip_style.corner_radius_bottom_left = 5
	tooltip_panel.add_theme_stylebox_override("panel", tooltip_style)
	
	# Style result panel
	var result_style = StyleBoxFlat.new()
	result_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	result_style.border_color = Color(0.5, 0.5, 0.5, 1.0)
	result_style.border_width_left = 3
	result_style.border_width_top = 3
	result_style.border_width_right = 3
	result_style.border_width_bottom = 3
	result_style.corner_radius_top_left = 8
	result_style.corner_radius_top_right = 8
	result_style.corner_radius_bottom_right = 8
	result_style.corner_radius_bottom_left = 8
	result_panel.add_theme_stylebox_override("panel", result_style)

func style_progress_bar(bar: ProgressBar, fill_color: Color) -> void:
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.3, 0.3, 0.3, 0.5)
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_right = 3
	bg_style.corner_radius_bottom_left = 3
	bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_right = 3
	fill_style.corner_radius_bottom_left = 3
	bar.add_theme_stylebox_override("fill", fill_style)

func style_action_button(button: Button, color: Color) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = color
	style_normal.corner_radius_top_left = 5
	style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_right = 5
	style_normal.corner_radius_bottom_left = 5
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = color.lightened(0.15)
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
	button.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func style_shop_button(button: Button, is_active: bool) -> void:
	var color = Color(0.2, 0.6, 0.9) if is_active else Color(0.5, 0.5, 0.5)  # Blue when active, gray when inactive
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = color
	style_normal.corner_radius_top_left = 5
	style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_right = 5
	style_normal.corner_radius_bottom_left = 5
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = color.lightened(0.15) if is_active else color  # Only lighten if active
	style_hover.corner_radius_top_left = 5
	style_hover.corner_radius_top_right = 5
	style_hover.corner_radius_bottom_right = 5
	style_hover.corner_radius_bottom_left = 5
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = color.darkened(0.2) if is_active else color  # Only darken if active
	style_pressed.corner_radius_top_left = 5
	style_pressed.corner_radius_top_right = 5
	style_pressed.corner_radius_bottom_right = 5
	style_pressed.corner_radius_bottom_left = 5
	
	var style_disabled = StyleBoxFlat.new()
	style_disabled.bg_color = Color(0.4, 0.4, 0.4, 0.7)  # Darker gray when disabled
	style_disabled.corner_radius_top_left = 5
	style_disabled.corner_radius_top_right = 5
	style_disabled.corner_radius_bottom_right = 5
	style_disabled.corner_radius_bottom_left = 5
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("disabled", style_disabled)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.7, 1))

func style_text_labels(labels: Dictionary) -> void:
	# Dark grey color for text on light backgrounds
	var dark_text_color = Color(0.3, 0.3, 0.3, 1.0)  # Dark grey
	var medium_dark_color = Color(0.4, 0.4, 0.4, 1.0)  # Medium dark grey
	
	# Apply colors to provided labels
	if labels.has("header"):
		for label in labels.header:
			label.add_theme_color_override("font_color", dark_text_color)
	
	if labels.has("stats"):
		for label in labels.stats:
			label.add_theme_color_override("font_color", dark_text_color)
	
	if labels.has("team_info"):
		for label in labels.team_info:
			label.add_theme_color_override("font_color", dark_text_color)
	
	if labels.has("action_hub"):
		for label in labels.action_hub:
			label.add_theme_color_override("font_color", dark_text_color)
	
	if labels.has("breadcrumb"):
		for label in labels.breadcrumb:
			label.add_theme_color_override("font_color", medium_dark_color)
	
	if labels.has("delta"):
		for label in labels.delta:
			label.add_theme_color_override("font_color", Color(0.2, 0.7, 0.2))
	
	if labels.has("tooltip"):
		for label in labels.tooltip:
			label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	if labels.has("result"):
		for label in labels.result:
			label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func style_race_type_label(label: Label) -> void:
	# Use dark grey for all race types to match the design
	var dark_text_color = Color(0.3, 0.3, 0.3, 1.0)
	label.add_theme_color_override("font_color", dark_text_color)

func style_item_button(button: Button, category: String) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.corner_radius_top_left = 5
	style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_right = 5
	style_normal.corner_radius_bottom_left = 5
	
	var style_hover = StyleBoxFlat.new()
	style_hover.corner_radius_top_left = 5
	style_hover.corner_radius_top_right = 5
	style_hover.corner_radius_bottom_right = 5
	style_hover.corner_radius_bottom_left = 5
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.corner_radius_top_left = 5
	style_pressed.corner_radius_top_right = 5
	style_pressed.corner_radius_bottom_right = 5
	style_pressed.corner_radius_bottom_left = 5
	
	match category:
		"team":
			style_normal.bg_color = Color(0.3, 0.5, 0.8, 0.7)
			style_hover.bg_color = Color(0.3, 0.5, 0.8, 0.95)
			style_pressed.bg_color = Color(0.2, 0.4, 0.7, 0.9)
			button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		"deck":
			style_normal.bg_color = Color(0.4, 0.7, 0.4, 0.7)
			style_hover.bg_color = Color(0.4, 0.7, 0.4, 0.95)
			style_pressed.bg_color = Color(0.3, 0.6, 0.3, 0.9)
			button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		"boosts":
			style_normal.bg_color = Color(0.7, 0.4, 0.8, 0.7)
			style_hover.bg_color = Color(0.7, 0.4, 0.8, 0.95)
			style_pressed.bg_color = Color(0.6, 0.3, 0.7, 0.9)
			button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		"equipment":
			style_normal.bg_color = Color(0.9, 0.6, 0.3, 0.7)
			style_hover.bg_color = Color(0.9, 0.6, 0.3, 0.95)
			style_pressed.bg_color = Color(0.8, 0.5, 0.2, 0.9)
			button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	
	# Add hover animation
	var hover_tween: Tween = null
	button.mouse_entered.connect(func():
		if hover_tween:
			hover_tween.kill()
		hover_tween = button.get_tree().create_tween()
		hover_tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	)
	button.mouse_exited.connect(func():
		if hover_tween:
			hover_tween.kill()
		hover_tween = button.get_tree().create_tween()
		hover_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
	)

func style_team_tray_container(container: VBoxContainer, is_varsity: bool, is_empty: bool = false) -> void:
	# Ensure container can receive mouse events for hover and clicks
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	# Ensure container can receive input events
	container.set_process_input(true)
	
	# Add a subtle background color to the container using a ColorRect
	var bg = ColorRect.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let clicks pass through
	bg.z_index = -1  # Behind other elements
	
	if is_empty:
		bg.color = Color(0.5, 0.5, 0.5, 0.2)
	else:
		if is_varsity:
			bg.color = Color(0.2, 0.5, 0.8, 0.2)  # Light blue for varsity
		else:
			bg.color = Color(0.6, 0.4, 0.8, 0.2)  # Light purple for JV
	
	# Make bg fill the container
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	container.add_child(bg)
	container.move_child(bg, 0)  # Move to back

func get_color_for_prob(val: float) -> Color:
	if val < 40:
		return Color.html("#e64d4d")  # Red
	elif val < 70:
		return Color.html("#e6bc4d")  # Yellow/Orange
	else:
		return Color.html("#69b378")  # Green

func get_label_color_for_prob(prob: float) -> Color:
	if prob < 30:
		return Color.html("#e64d4d")  # Red
	elif prob < 50:
		return Color.html("#e6bc4d")  # Yellow
	else:
		return Color(0.3, 0.3, 0.3, 1.0)  # Dark grey

