extends Node
class_name RunUI

# UI display and update functions

var current_display_prob: float = 0.0
var previous_probability: float = 0.0
var danger_pulse_tween: Tween = null
var danger_pulse_timer: Timer = null
var is_in_danger_mode: bool = false

# UI element references (will be set by Run.gd)
var header_labels: Dictionary = {}
var stat_labels: Dictionary = {}
var stat_deltas: Dictionary = {}
var stat_bars: Dictionary = {}
var team_labels: Dictionary = {}
var action_labels: Dictionary = {}
var inventory_containers: Dictionary = {}
var team_tray: HFlowContainer = null
var win_probability_gauge: TextureProgressBar = null
var win_probability_label: Label = null
var gauge_container: Control = null
var success_glow: GPUParticles2D = null
var result_panel: Panel = null
var result_label: Label = null
var loading_panel: Panel = null
var loading_label: Label = null
var purchase_feedback_label: Label = null
var breadcrumb_label: Label = null

func update_display(run_state: RunState, styling: RunStyling, tooltip_manager: TooltipManager, card_interaction: CardInteraction, get_sell_price_func: Callable, get_card_texture_func: Callable, create_tooltip_func: Callable, sell_callback: Callable = Callable()) -> void:
	# Update header
	header_labels.ante.text = "🏆 Ante: %d/%d" % [GameManager.current_ante, GameManager.max_ante]
	header_labels.race_type.text = "Race: %s" % GameManager.get_race_type_name()
	styling.style_race_type_label(header_labels.race_type)
	header_labels.seed.text = "Seed: %d" % GameManager.seed
	header_labels.gold.text = "💰 Gold: %d" % GameManager.get_gold()
	header_labels.gold.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	
	# Update stats with progress bars and deltas
	var speed = GameManager.get_total_speed()
	var endurance = GameManager.get_total_endurance()
	var stamina = GameManager.get_total_stamina()
	var power = GameManager.get_total_power()
	
	# Calculate JV bonuses (25% of JV stats)
	var jv_speed_bonus = 0
	var jv_endurance_bonus = 0
	var jv_stamina_bonus = 0
	var jv_power_bonus = 0
	
	for runner in GameManager.jv_team:
		var effect = GameManager.get_item_effect(runner, "team")
		jv_speed_bonus += int(effect.speed * 0.25)
		jv_endurance_bonus += int(effect.endurance * 0.25)
		jv_stamina_bonus += int(effect.stamina * 0.25)
		jv_power_bonus += int(effect.power * 0.25)
	
	stat_labels.speed.text = "Speed: %d" % speed
	stat_deltas.speed.text = "+%d" % jv_speed_bonus if jv_speed_bonus > 0 else ""
	stat_bars.speed.value = speed
	
	stat_labels.endurance.text = "Endurance: %d" % endurance
	stat_deltas.endurance.text = "+%d" % jv_endurance_bonus if jv_endurance_bonus > 0 else ""
	stat_bars.endurance.value = endurance
	
	stat_labels.stamina.text = "Stamina: %d" % stamina
	stat_deltas.stamina.text = "+%d" % jv_stamina_bonus if jv_stamina_bonus > 0 else ""
	stat_bars.stamina.value = stamina
	
	stat_labels.power.text = "Power: %d" % power
	stat_deltas.power.text = "+%d" % jv_power_bonus if jv_power_bonus > 0 else ""
	stat_bars.power.value = power
	
	# Update team info
	var team_size = GameManager.get_team_size()
	team_labels.info.text = "Team: %d Varsity, %d JV" % [team_size.varsity, team_size.jv]
	
	# Update team composition breakdown
	update_team_composition()
	
	# Update win probability with smooth animation
	var new_probability = run_state.calculate_win_probability()
	update_probability_display(new_probability, styling)
	
	# Update breadcrumb
	breadcrumb_label.text = "Main > Run"
	
	# Display inventory and team tray
	display_inventory(tooltip_manager, styling, get_sell_price_func, create_tooltip_func, sell_callback if sell_callback else Callable())
	display_team_tray(card_interaction, tooltip_manager, styling, get_sell_price_func, get_card_texture_func, create_tooltip_func)

func update_team_composition() -> void:
	# Count runner types by archetype
	var front_runner_count = 0  # Speed/Power focused
	var stayer_count = 0  # Endurance/Stamina focused
	var kicker_count = 0  # Speed/Stamina focused
	var all_around_count = 0  # Balanced
	
	# Front Runner archetypes (Speed/Power)
	var front_runner_types = ["Hill Specialist", "The Closer", "Track Tourist", "Elite V-State Harrier", "Caffeine Fiend"]
	# Stayer archetypes (Endurance/Stamina)
	var stayer_types = ["Steady State Runner", "Ghost of the Woods"]
	# Kicker archetypes (Speed/Stamina)
	var kicker_types = ["Short-Cutter"]
	# All-Around types
	var all_around_types = ["Tempo Runner", "Freshman Walk-on", "All-Terrain Captain", "The Legend", "JV Legend"]
	
	for runner in GameManager.varsity_team:
		var base_name = runner.name
		if base_name in front_runner_types:
			front_runner_count += 1
		elif base_name in stayer_types:
			stayer_count += 1
		elif base_name in kicker_types:
			kicker_count += 1
		elif base_name in all_around_types:
			all_around_count += 1
	
	for runner in GameManager.jv_team:
		var base_name = runner.name
		if base_name in front_runner_types:
			front_runner_count += 1
		elif base_name in stayer_types:
			stayer_count += 1
		elif base_name in kicker_types:
			kicker_count += 1
		elif base_name in all_around_types:
			all_around_count += 1
	
	var composition_parts = []
	if front_runner_count > 0:
		composition_parts.append("%d Front Runners" % front_runner_count)
	if stayer_count > 0:
		composition_parts.append("%d Stayers" % stayer_count)
	if kicker_count > 0:
		composition_parts.append("%d Kickers" % kicker_count)
	if all_around_count > 0:
		composition_parts.append("%d All-Around" % all_around_count)
	
	if composition_parts.is_empty():
		team_labels.composition.text = "No runners"
	else:
		team_labels.composition.text = "Composition: " + ", ".join(composition_parts)

func setup_win_probability_gauge() -> void:
	# Setup the TextureProgressBar for radial display
	# Set pivot for scaling effects (will be set properly after layout)
	await get_tree().process_frame
	win_probability_gauge.pivot_offset = win_probability_gauge.size / 2

func setup_particle_system() -> void:
	# Configure the success glow particle system
	success_glow.visible = false
	success_glow.emitting = false
	# Set particle color to green using modulate
	success_glow.modulate = Color(0.3, 0.8, 0.4, 1.0)  # Green tint
	# Configure particle behavior
	var material = ParticleProcessMaterial.new()
	material.gravity = Vector3(0, -50, 0)
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 100.0
	material.angular_velocity_min = -180.0
	material.angular_velocity_max = 180.0
	material.scale_min = 0.5
	material.scale_max = 1.0
	success_glow.process_material = material

func update_probability_display(new_val: float, styling: RunStyling) -> void:
	var duration = 0.6  # Seconds
	var prob_increase = new_val - previous_probability
	
	# 1. Create a Tween for the Gauge and the Number
	var tween = get_tree().create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	# Animate the gauge fill
	tween.tween_property(win_probability_gauge, "value", new_val, duration)
	
	# Animate the number text (using a custom method to lerp the value)
	tween.tween_method(set_label_text, current_display_prob, new_val, duration)
	
	# 2. Add a "Squash and Stretch" effect to the gauge for impact
	var scale_tween = get_tree().create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	win_probability_gauge.pivot_offset = win_probability_gauge.size / 2
	scale_tween.tween_property(win_probability_gauge, "scale", Vector2(1.1, 1.1), 0.1)
	scale_tween.tween_property(win_probability_gauge, "scale", Vector2(1.0, 1.0), 0.3)
	
	# 3. Dynamic Color Shifting
	tween.tween_property(win_probability_gauge, "tint_progress", styling.get_color_for_prob(new_val), duration)
	
	# 4. Success Glow Effect (if probability increased significantly)
	if prob_increase >= 10.0:
		trigger_success_glow()
	
	# 5. Danger Shake and Pulsing (if probability is dangerously low)
	if new_val < 30.0:
		trigger_danger_effects()
	else:
		stop_danger_effects()
	
	# Update label color based on probability
	update_label_color(new_val, styling)
	
	current_display_prob = new_val
	previous_probability = new_val

func set_label_text(value: float) -> void:
	win_probability_label.text = "Win Probability: %d%%" % int(round(value))

func trigger_success_glow() -> void:
	# Create particle effect for success
	success_glow.visible = true
	success_glow.restart()
	success_glow.emitting = true
	
	# Hide after animation completes
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(func(): success_glow.visible = false)

func trigger_danger_effects() -> void:
	# Stop any existing danger effects first to prevent duplicates
	stop_danger_effects()
	
	# Shake the gauge container
	var shake_tween = get_tree().create_tween()
	var shake_amount = 5.0
	var original_pos = gauge_container.position
	
	# Create a shake pattern
	for i in range(8):
		var offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		shake_tween.tween_property(gauge_container, "position", original_pos + offset, 0.05)
		shake_tween.tween_property(gauge_container, "position", original_pos, 0.05)
	
	# Pulsing animation for the label
	# Use a simple finite loop instead of infinite to avoid errors
	# Make sure to kill any existing tween first
	if danger_pulse_tween and danger_pulse_tween.is_valid():
		danger_pulse_tween.kill()
	
	is_in_danger_mode = true
	_start_danger_pulse()

func _start_danger_pulse() -> void:
	# Only pulse if still in danger mode
	if not is_in_danger_mode:
		return
	if not win_probability_label or not is_instance_valid(win_probability_label):
		return
	
	# Check if node is in the scene tree before creating tween
	if not is_inside_tree():
		return
	
	var tree = get_tree()
	if not tree:
		return
	
	# Create a simple pulse animation (fade out then fade in)
	danger_pulse_tween = tree.create_tween()
	if not danger_pulse_tween:
		return
	
	danger_pulse_tween.tween_property(win_probability_label, "modulate:a", 0.5, 0.5)
	danger_pulse_tween.tween_property(win_probability_label, "modulate:a", 1.0, 0.5)
	# Restart after completion if still in danger
	danger_pulse_tween.finished.connect(_restart_danger_pulse)

func _restart_danger_pulse() -> void:
	# Only restart if still in danger mode and node is in tree
	if is_in_danger_mode and is_inside_tree() and win_probability_label and is_instance_valid(win_probability_label):
		_start_danger_pulse()

func stop_danger_effects() -> void:
	# Mark that we're no longer in danger mode
	is_in_danger_mode = false
	
	# Stop pulsing
	if danger_pulse_tween:
		if danger_pulse_tween.is_valid():
			# Disconnect the callback to prevent restart
			if danger_pulse_tween.finished.is_connected(_restart_danger_pulse):
				danger_pulse_tween.finished.disconnect(_restart_danger_pulse)
			danger_pulse_tween.kill()
		danger_pulse_tween = null
	
	# Reset label alpha
	if win_probability_label and is_instance_valid(win_probability_label):
		win_probability_label.modulate.a = 1.0
	
	# Reset container position
	var reset_tween = get_tree().create_tween()
	reset_tween.tween_property(gauge_container, "position", Vector2.ZERO, 0.2)

func update_label_color(prob: float, styling: RunStyling) -> void:
	win_probability_label.add_theme_color_override("font_color", styling.get_label_color_for_prob(prob))

func display_team_tray(card_interaction: CardInteraction, tooltip_manager: TooltipManager, styling: RunStyling, get_sell_price_func: Callable, get_card_texture_func: Callable, create_tooltip_func: Callable) -> void:
	# Clear existing team tray icons
	for child in team_tray.get_children(): child.queue_free()
	
	# Display Varsity runners (5 slots)
	for i in range(5):
		var container = VBoxContainer.new()
		container.custom_minimum_size = Vector2(120, 160)
		container.add_theme_constant_override("separation", 2)
		
		# Ensure container can receive mouse events
		container.mouse_filter = Control.MOUSE_FILTER_STOP
		
		if i < GameManager.varsity_team.size():
			var runner = GameManager.varsity_team[i]
			var base_name = runner.name
			
			# Get runner effect for hover functionality
			var effect = GameManager.get_item_effect(runner, "team")
			var item_data = {"name": runner.display_name, "category": "team", "index": i, "is_varsity": true}
			
			# Try to load card image
			var card_texture = get_card_texture_func.call(runner.display_name, "team")
			if card_texture:
				var texture_rect = TextureRect.new()
				texture_rect.texture = card_texture
				texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				texture_rect.custom_minimum_size = Vector2(110, 140)
				texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let mouse events pass through to container
				container.add_child(texture_rect)
			
			# Add label with slot number
			var label = Label.new()
			label.text = "V%d" % [i + 1]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			label.add_theme_font_size_override("font_size", 12)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let mouse events pass through to container
			container.add_child(label)
			
			# Create tooltip
			var tooltip = create_tooltip_func.call(runner.display_name, "team", effect, 0)  # No sell price in tray
			container.tooltip_text = tooltip
			
			# Connect hover events for stat deltas
			container.mouse_entered.connect(func():
				tooltip_manager.on_item_hovered(item_data, effect, self.stat_labels, self.stat_deltas)
			)
			container.mouse_exited.connect(func():
				tooltip_manager.on_item_unhovered(self.stat_labels, self.stat_deltas)
			)
			
			# Connect click handler for card selection
			container.gui_input.connect(func(event): 
				card_interaction.on_team_tray_card_clicked(event, item_data, container, get_sell_price_func)
			)
			
			styling.style_team_tray_container(container, true)
		else:
			# Empty slot
			var label = Label.new()
			label.text = "V%d\nEmpty" % [i + 1]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			container.add_child(label)
			styling.style_team_tray_container(container, true, true)
		
		team_tray.call_deferred("add_child", container)
	
	# Display JV runners (2 slots)
	for i in range(2):
		var container = VBoxContainer.new()
		container.custom_minimum_size = Vector2(120, 160)
		container.add_theme_constant_override("separation", 2)
		
		# Ensure container can receive mouse events
		container.mouse_filter = Control.MOUSE_FILTER_STOP
		
		if i < GameManager.jv_team.size():
			var runner = GameManager.jv_team[i]
			var base_name = runner.name
			
			# Get runner effect for hover functionality
			var effect = GameManager.get_item_effect(runner, "team")
			var item_data = {"name": runner.display_name, "category": "team", "index": i, "is_varsity": false}
			
			# Try to load card image
			var card_texture = get_card_texture_func.call(runner.display_name, "team")
			if card_texture:
				var texture_rect = TextureRect.new()
				texture_rect.texture = card_texture
				texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				texture_rect.custom_minimum_size = Vector2(110, 140)
				texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let mouse events pass through to container
				container.add_child(texture_rect)
			
			# Add label with slot number
			var label = Label.new()
			label.text = "JV%d" % [i + 1]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			label.add_theme_font_size_override("font_size", 12)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let mouse events pass through to container
			container.add_child(label)
			
			# Create tooltip
			var tooltip = create_tooltip_func.call(runner.display_name, "team", effect, 0)  # No sell price in tray
			container.tooltip_text = tooltip
			
			# Connect hover events for stat deltas
			container.mouse_entered.connect(func():
				tooltip_manager.on_item_hovered(item_data, effect, self.stat_labels, self.stat_deltas)
			)
			container.mouse_exited.connect(func():
				tooltip_manager.on_item_unhovered(self.stat_labels, self.stat_deltas)
			)
			
			# Connect click handler for card selection
			container.gui_input.connect(func(event): 
				card_interaction.on_team_tray_card_clicked(event, item_data, container, get_sell_price_func)
			)
			
			styling.style_team_tray_container(container, false)
		else:
			# Empty slot
			var label = Label.new()
			label.text = "JV%d\nEmpty" % [i + 1]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			container.add_child(label)
			styling.style_team_tray_container(container, false, true)
		
		team_tray.call_deferred("add_child", container)
	
	# Try to restore selection if the selected card still exists
	# Use call_deferred to restore after containers are added
	call_deferred("_restore_team_card_selection", card_interaction, get_sell_price_func)

func _restore_team_card_selection(card_interaction: CardInteraction, get_sell_price_func: Callable) -> void:
	if card_interaction.selected_team_card_data.has("index") and card_interaction.selected_team_card_data.has("is_varsity"):
		# Find the container that matches the selected data
		var index = card_interaction.selected_team_card_data.index
		var is_varsity = card_interaction.selected_team_card_data.is_varsity
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
					var item_data = {"name": runner.display_name, "category": "team", "index": index, "is_varsity": is_varsity}
					# Restore selection and show sell button
					card_interaction.selected_team_card = container
					card_interaction.selected_team_card_data = item_data
					card_interaction.animate_card_selection(container, true)
					if get_sell_price_func.is_valid():
						card_interaction.show_sell_button_for_selected_card(get_sell_price_func)

func display_inventory(tooltip_manager: TooltipManager, styling: RunStyling, get_sell_price_func: Callable, create_tooltip_func: Callable, sell_callback: Callable = Callable()) -> void:
	# Clear existing items
	for child in inventory_containers.deck.get_children(): child.queue_free()
	for child in inventory_containers.boosts.get_children(): child.queue_free()
	for child in inventory_containers.equipment.get_children(): child.queue_free()

	# Display Deck Items in Grid (4 columns)
	for i in range(GameManager.deck.size()):
		var item_name = GameManager.deck[i]
		var item_data = {"name": item_name, "category": "deck", "index": i}
		var button = create_inventory_item_button(item_data, tooltip_manager, styling, get_sell_price_func, create_tooltip_func, sell_callback)
		inventory_containers.deck.call_deferred("add_child", button)

	# Display Boosts
	for i in range(GameManager.jokers.size()):
		var item_name = GameManager.jokers[i]
		var item_data = {"name": item_name, "category": "boosts", "index": i}
		var button = create_inventory_item_button(item_data, tooltip_manager, styling, get_sell_price_func, create_tooltip_func, sell_callback)
		inventory_containers.boosts.call_deferred("add_child", button)

	# Display Equipment
	for i in range(GameManager.shop_inventory.size()):
		var item_name = GameManager.shop_inventory[i]
		var item_data = {"name": item_name, "category": "equipment", "index": i}
		var button = create_inventory_item_button(item_data, tooltip_manager, styling, get_sell_price_func, create_tooltip_func, sell_callback)
		inventory_containers.equipment.call_deferred("add_child", button)

func create_inventory_item_button(item_data: Dictionary, tooltip_manager: TooltipManager, styling: RunStyling, get_sell_price_func: Callable, create_tooltip_func: Callable, sell_callback: Callable = Callable()) -> Button:
	var button = Button.new()
	var item_name = item_data.name
	var category = item_data.category
	var index = item_data.index
	var is_varsity = item_data.get("is_varsity", false)

	var effect = GameManager.get_item_effect(item_name, category)
	var effect_text = tooltip_manager.format_effect_text(effect)
	var sell_price = get_sell_price_func.call(item_name, category)

	var prefix = ""
	if category == "team":
		prefix = "V%d: " % (index + 1) if is_varsity else "JV%d: " % (index + 1)
	
	# Get icon for category
	var icon = get_category_icon(category)
	button.text = "%s%s\n%s\n💰 Sell: %d" % [icon, prefix, item_name.split(":")[1] if ":" in item_name else item_name, sell_price]
	button.custom_minimum_size = Vector2(120, 100)
	
	# Create tooltip
	var tooltip = create_tooltip_func.call(item_name, category, effect, sell_price)
	button.tooltip_text = tooltip
	
	# Connect hover events for enhanced tooltip
	button.mouse_entered.connect(func():
		tooltip_manager.on_item_hovered(item_data, effect, self.stat_labels, self.stat_deltas)
	)
	button.mouse_exited.connect(func():
		tooltip_manager.on_item_unhovered(self.stat_labels, self.stat_deltas)
	)
	
	# Connect click to sell if callback provided
	if sell_callback.is_valid():
		button.pressed.connect(sell_callback.bind(item_data))
	
	# Disable sell button for varsity runners if team size is 5
	if category == "team" and is_varsity and GameManager.varsity_team.size() <= 5:
		button.disabled = true
		button.tooltip_text += "\n\n⚠️ Cannot sell: Must have at least 5 varsity runners."
	
	styling.style_item_button(button, category)
	return button

func get_category_icon(category: String) -> String:
	match category:
		"team": return "🏃 "
		"deck": return "🃏 "
		"boosts": return "⚡ "
		"equipment": return "🎒 "
	return ""

func show_result_display(message: String) -> void:
	result_label.text = message
	result_panel.visible = true

func clear_result_display() -> void:
	result_label.text = ""
	result_panel.visible = false

func show_loading_screen(message: String) -> void:
	loading_label.text = message
	loading_panel.visible = true
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	loading_panel.add_theme_stylebox_override("panel", style)

func hide_loading_screen() -> void:
	loading_panel.visible = false

func show_purchase_feedback(message: String, is_success: bool) -> void:
	purchase_feedback_label.text = message
	purchase_feedback_label.visible = true
	if is_success:
		purchase_feedback_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	else:
		purchase_feedback_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	
	# Animate fade in/out
	var tween = get_tree().create_tween()
	tween.tween_property(purchase_feedback_label, "modulate:a", 1.0, 0.2)
	await get_tree().create_timer(1.5).timeout
	tween = get_tree().create_tween()
	tween.tween_property(purchase_feedback_label, "modulate:a", 0.0, 0.3)
	await tween.finished
	purchase_feedback_label.visible = false
	purchase_feedback_label.modulate.a = 1.0
