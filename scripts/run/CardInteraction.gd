extends Node
class_name CardInteraction

# Card selection, dragging, and sell button logic

signal card_selected(item_data: Dictionary)
signal card_deselected()
signal sell_requested(item_data: Dictionary)

var selected_team_card: VBoxContainer = null  # Currently selected card container
var selected_team_card_data: Dictionary = {}  # Data for selected card
var team_tray_sell_button: Button = null  # Sell button that appears when card is selected
var dragged_card: VBoxContainer = null  # Card currently being dragged
var drag_start_position: Vector2 = Vector2.ZERO  # Original position when drag started
var drag_offset: Vector2 = Vector2.ZERO  # Offset from mouse to card when dragging started
var was_selected_on_press: bool = false  # Track if card was already selected when mouse was pressed

func on_team_tray_card_clicked(event: InputEvent, item_data: Dictionary, container: VBoxContainer, get_sell_price_func: Callable = Callable()) -> void:
	# Handle mouse motion for dragging
	if event is InputEventMouseMotion:
		if dragged_card == container:
			var motion_event = event as InputEventMouseMotion
			# Update card position based on mouse position (relative to parent)
			var parent = container.get_parent()
			var mouse_in_parent = parent.get_global_mouse_position() - parent.global_position
			var new_position = mouse_in_parent - drag_offset
			container.position = new_position
			# Update sell button position to follow the card
			call_deferred("_position_sell_button_next_to_card")
		return
	
	# Only process left mouse button events
	if not (event is InputEventMouseButton):
		return
	
	var mouse_event = event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	if mouse_event.pressed:
		# Mouse button pressed - check if click was on the sell button first (using local coordinates)
		if team_tray_sell_button != null and team_tray_sell_button.visible:
			# Get click position in the card's local coordinate space
			var local_click_pos = container.get_local_mouse_position()
			var button_local_pos = team_tray_sell_button.position
			var button_size = team_tray_sell_button.size
			var button_rect = Rect2(button_local_pos, button_size)
			if button_rect.has_point(local_click_pos):
				return  # Click was on sell button, let it handle it
		
		# Track if card was already selected when pressed
		was_selected_on_press = (selected_team_card == container)
		
		# Select the card if not already selected
		if not was_selected_on_press:
			select_team_card(container, item_data, get_sell_price_func)
		
		# Prepare for potential drag (only if we actually start moving)
		drag_start_position = container.position
		var parent = container.get_parent()
		var mouse_in_parent = parent.get_global_mouse_position() - parent.global_position
		drag_offset = mouse_in_parent - container.position
		dragged_card = container
	else:
		# Mouse button released - end drag
		if dragged_card == container:
			var drag_distance = (container.position - drag_start_position).length()
			
			if drag_distance < 5.0:  # Threshold for click vs drag
				# It was a click, not a drag
				container.position = drag_start_position
				
				# Toggle selection: if card was already selected when pressed, deselect it
				if was_selected_on_press:
					deselect_team_card()
				# If it wasn't selected on press, it should already be selected from the press handler
			# If it was a drag (distance >= 5.0), keep the new position
			# Card remains selected
			
			dragged_card = null
			was_selected_on_press = false  # Reset for next interaction

func select_team_card(container: VBoxContainer, item_data: Dictionary, get_sell_price_func: Callable = Callable()) -> void:
	# Deselect previous card if any
	if selected_team_card != null:
		deselect_team_card()
	
	# Select new card
	selected_team_card = container
	selected_team_card_data = item_data
	
	# Visual feedback: raise the card (scale up only, no position change)
	animate_card_selection(container, true)
	
	# Show sell button if function provided
	if get_sell_price_func.is_valid():
		show_sell_button_for_selected_card(get_sell_price_func)
	
	card_selected.emit(item_data)

func deselect_team_card() -> void:
	if selected_team_card != null:
		# Animate card back to normal (scale down only, position stays where dragged)
		animate_card_selection(selected_team_card, false)
		selected_team_card = null
		selected_team_card_data = {}
	
	# Reset drag state
	dragged_card = null
	
	# Hide sell button
	hide_sell_button()
	
	card_deselected.emit()

func animate_card_selection(container: VBoxContainer, is_selected: bool) -> void:
	if is_selected:
		# Highlight card: scale up and keep it raised (stays raised until deselected)
		# Store original position for reference
		if not container.has_meta("original_position"):
			container.set_meta("original_position", container.position)
		
		# Set z-index immediately to bring to front
		container.z_index = 10
		
		# Set scale immediately and ensure it persists
		container.scale = Vector2(1.1, 1.1)
		
		# Animate smoothly to raised state if not already there
		var current_scale = container.scale
		if current_scale.length() < 1.05:
			var tween = container.get_tree().create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			container.scale = Vector2(0.95, 0.95)
			tween.tween_property(container, "scale", Vector2(1.1, 1.1), 0.15)
			# Ensure it stays at 1.1 after animation completes
			tween.tween_callback(func(): 
				if container != null and is_instance_valid(container):
					container.scale = Vector2(1.1, 1.1)
			)
	else:
		# Lower card: scale down only when deselected
		var tween = container.get_tree().create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.15)
		container.z_index = 0  # Back to normal

func ensure_selected_card_raised() -> void:
	# Periodically ensure the selected card stays raised
	# This prevents the scale from being reset by other systems
	if selected_team_card != null and is_instance_valid(selected_team_card):
		# Check if scale is correct
		if selected_team_card.scale.length() < 1.05:
			# Scale was reset somehow - restore it
			selected_team_card.scale = Vector2(1.1, 1.1)
			selected_team_card.z_index = 10
		
		# Schedule next check
		await get_tree().create_timer(0.1).timeout
		ensure_selected_card_raised()

func show_sell_button_for_selected_card(get_sell_price_func: Callable) -> void:
	hide_sell_button()
	
	if selected_team_card == null or selected_team_card_data.is_empty():
		return
	
	var item_name = selected_team_card_data.name
	var category = selected_team_card_data.category
	var is_varsity = selected_team_card_data.get("is_varsity", false)
	var sell_price = get_sell_price_func.call(item_name, category)
	
	var can_sell = true
	if category == "team" and is_varsity and GameManager.varsity_team.size() <= 5:
		can_sell = false
	
	# Create smaller sell button (Balatro-style) - square button
	team_tray_sell_button = Button.new()
	team_tray_sell_button.text = "SELL\n%d" % sell_price  # Smaller text
	team_tray_sell_button.custom_minimum_size = Vector2(40, 40)  # Square button
	team_tray_sell_button.disabled = not can_sell
	team_tray_sell_button.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure button receives mouse events
	team_tray_sell_button.add_theme_font_size_override("font_size", 10)  # Smaller font for compact button
	team_tray_sell_button.z_index = 100  # Ensure button is on top and clickable
	
	# Style as red button
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.8, 0.2, 0.2, 0.9) if can_sell else Color(0.5, 0.5, 0.5, 0.5)
	style_normal.corner_radius_top_left = 5
	style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_right = 5
	style_normal.corner_radius_bottom_left = 5
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.9, 0.3, 0.3, 0.9) if can_sell else Color(0.5, 0.5, 0.5, 0.5)
	style_hover.corner_radius_top_left = 5
	style_hover.corner_radius_top_right = 5
	style_hover.corner_radius_bottom_right = 5
	style_hover.corner_radius_bottom_left = 5
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.7, 0.1, 0.1, 0.9) if can_sell else Color(0.5, 0.5, 0.5, 0.5)
	style_pressed.corner_radius_top_left = 5
	style_pressed.corner_radius_top_right = 5
	style_pressed.corner_radius_bottom_right = 5
	style_pressed.corner_radius_bottom_left = 5
	
	team_tray_sell_button.add_theme_stylebox_override("normal", style_normal)
	team_tray_sell_button.add_theme_stylebox_override("hover", style_hover)
	team_tray_sell_button.add_theme_stylebox_override("pressed", style_pressed)
	team_tray_sell_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	# Position button as a child of the selected card so it moves with it
	selected_team_card.add_child(team_tray_sell_button)
	
	# Use call_deferred to position after layout
	call_deferred("_position_sell_button_next_to_card")
	
	# Connect sell action
	team_tray_sell_button.pressed.connect(_on_sell_selected_team_card)

func _position_sell_button_next_to_card() -> void:
	if team_tray_sell_button == null or selected_team_card == null:
		return
	
	# Position button at the bottom right of the card (relative to card container)
	var card_size = selected_team_card.size
	var button_size = team_tray_sell_button.custom_minimum_size
	var button_offset_x = card_size.x - button_size.x - 5  # 5px from right edge
	var button_offset_y = card_size.y - button_size.y - 5  # 5px from bottom edge
	
	# Position relative to the card container
	team_tray_sell_button.position = Vector2(button_offset_x, button_offset_y)
	
	# Ensure button is on top
	selected_team_card.move_child(team_tray_sell_button, selected_team_card.get_child_count() - 1)

func hide_sell_button() -> void:
	if team_tray_sell_button != null:
		team_tray_sell_button.queue_free()
		team_tray_sell_button = null

func _on_sell_selected_team_card() -> void:
	if selected_team_card != null and not selected_team_card_data.is_empty():
		sell_requested.emit(selected_team_card_data)

func restore_team_card_selection(team_tray: HFlowContainer, get_item_data_func: Callable) -> void:
	if selected_team_card_data.has("index") and selected_team_card_data.has("is_varsity"):
		# Find the container that matches the selected data
		var index = selected_team_card_data.index
		var is_varsity = selected_team_card_data.is_varsity
		var containers = team_tray.get_children()
		
		# Calculate which container index it should be
		# Varsity first (0-4), then JV (5-6)
		var target_index = index if is_varsity else 5 + index
		
		if target_index < containers.size():
			var container = containers[target_index]
			# Check if container has content (not empty slot)
			if container.get_child_count() > 1:  # More than just the background ColorRect
				# Recreate item_data with name as string (display name) for tooltips/sell
				var runner: Runner = null
				if is_varsity and index < GameManager.varsity_team.size():
					runner = GameManager.varsity_team[index]
				elif not is_varsity and index < GameManager.jv_team.size():
					runner = GameManager.jv_team[index]
				
				if runner != null:
					var item_data = get_item_data_func.call(runner.display_name, index, is_varsity)
					# Restore selection without triggering sell button (just visual)
					selected_team_card = container
					selected_team_card_data = item_data
					animate_card_selection(container, true)

