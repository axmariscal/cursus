extends Control

@onready var varsity_container: VBoxContainer = %VarsityContainer
@onready var jv_container: VBoxContainer = %JVContainer
@onready var back_button: Button = %BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	_update_display()

func _update_display() -> void:
	_clear_containers()
	_display_team()

func _display_team() -> void:
	# Display varsity team (5 slots)
	for i in range(5):
		var slot_container = HBoxContainer.new()
		slot_container.alignment = BoxContainer.ALIGNMENT_CENTER
		
		if i < GameManager.varsity_team.size():
			# Show runner info with management buttons
			var runner = GameManager.varsity_team[i]
			var runner_label = _create_runner_label_with_training("Slot %d: %s" % [i + 1, runner.display_name], runner)
			slot_container.add_child(runner_label)
			
			# Add management buttons
			var demote_button = Button.new()
			demote_button.text = "→ JV"
			demote_button.custom_minimum_size = Vector2(60, 30)
			demote_button.pressed.connect(_on_demote_varsity.bind(i))
			slot_container.add_child(demote_button)
			
			var remove_button = Button.new()
			remove_button.text = "Remove"
			remove_button.custom_minimum_size = Vector2(70, 30)
			remove_button.pressed.connect(_on_remove_varsity.bind(i))
			slot_container.add_child(remove_button)
		else:
			# Show empty slot
			var empty_label = _create_empty_slot_label("Slot %d: [Empty]" % [i + 1])
			slot_container.add_child(empty_label)
		
		varsity_container.add_child(slot_container)
	
	# Display JV team (2 slots)
	for i in range(2):
		var slot_container = HBoxContainer.new()
		slot_container.alignment = BoxContainer.ALIGNMENT_CENTER
		
		if i < GameManager.jv_team.size():
			# Show runner info with management buttons
			var runner = GameManager.jv_team[i]
			var runner_label = _create_runner_label_with_training("JV Slot %d: %s" % [i + 1, runner.display_name], runner)
			slot_container.add_child(runner_label)
			
			# Add management buttons
			var promote_button = Button.new()
			promote_button.text = "→ Varsity"
			promote_button.custom_minimum_size = Vector2(80, 30)
			promote_button.pressed.connect(_on_promote_jv.bind(i))
			slot_container.add_child(promote_button)
			
			var remove_button = Button.new()
			remove_button.text = "Remove"
			remove_button.custom_minimum_size = Vector2(70, 30)
			remove_button.pressed.connect(_on_remove_jv.bind(i))
			slot_container.add_child(remove_button)
		else:
			# Show empty slot
			var empty_label = _create_empty_slot_label("JV Slot %d: [Empty]" % [i + 1])
			slot_container.add_child(empty_label)
		
		jv_container.add_child(slot_container)

func _create_runner_label(text: String, effect: Dictionary) -> Label:
	var label = Label.new()
	var effect_parts: Array[String] = []
	
	if effect.speed > 0:
		effect_parts.append("Spd:%d" % effect.speed)
	if effect.endurance > 0:
		effect_parts.append("End:%d" % effect.endurance)
	if effect.stamina > 0:
		effect_parts.append("Sta:%d" % effect.stamina)
	if effect.power > 0:
		effect_parts.append("Pow:%d" % effect.power)
	
	var effect_text = ""
	if not effect_parts.is_empty():
		effect_text = " (" + ", ".join(effect_parts) + ")"
	
	label.text = text + effect_text
	label.horizontal_alignment = 1
	return label

func _create_runner_label_with_training(text: String, runner: Runner) -> VBoxContainer:
	# Create a container for all runner information
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	
	# Get runner stats (runner is already a Runner object)
	var stats = runner.get_display_stats()
	var injury_status = runner.get_injury_status()
	
	# Main runner name and base info
	var main_label = Label.new()
	var runner_name = runner.name
	main_label.text = text
	main_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_label.add_theme_font_size_override("font_size", 14)
	container.add_child(main_label)
	
	# Current stats (base + training gains)
	var stats_label = Label.new()
	stats_label.text = "Stats: Spd:%d End:%d Sta:%d Pow:%d" % [
		stats.current.speed, stats.current.endurance, stats.current.stamina, stats.current.power
	]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 12)
	container.add_child(stats_label)
	
	# Training gains (if any)
	var gains = stats.training_gains
	if gains.speed > 0 or gains.endurance > 0 or gains.stamina > 0 or gains.power > 0:
		var gains_label = Label.new()
		gains_label.text = "Training: +%d Spd, +%d End, +%d Sta, +%d Pow" % [
			gains.speed, gains.endurance, gains.stamina, gains.power
		]
		gains_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gains_label.add_theme_font_size_override("font_size", 11)
		gains_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))  # Green for gains
		container.add_child(gains_label)
	
	# Injury status
	var injury_label = Label.new()
	if injury_status.is_injured:
		injury_label.text = "⚠️ Injured: %.0f%% (%s)" % [injury_status.meter, injury_status.severity]
		injury_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))  # Red for injury
	else:
		injury_label.text = "✓ Healthy (Injury: %.0f%%)" % injury_status.meter
		injury_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))  # Green for healthy
	injury_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	injury_label.add_theme_font_size_override("font_size", 11)
	container.add_child(injury_label)
	
	# Training history count
	if runner.total_training_sessions > 0:
		var history_label = Label.new()
		history_label.text = "Training Sessions: %d" % runner.total_training_sessions
		history_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		history_label.add_theme_font_size_override("font_size", 10)
		history_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))  # Light blue
		container.add_child(history_label)
	
	return container

func _create_empty_slot_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = 1
	label.modulate = Color(0.7, 0.7, 0.7)  # Gray out empty slots
	return label

func _clear_containers() -> void:
	for child in varsity_container.get_children():
		child.queue_free()
	for child in jv_container.get_children():
		child.queue_free()

func _on_demote_varsity(varsity_index: int) -> void:
	# Demote varsity runner to JV (swap with first available JV slot)
	if varsity_index >= 0 and varsity_index < GameManager.varsity_team.size():
		# Find first empty JV slot or swap with first JV runner
		if GameManager.jv_team.size() < 2:
			# Move to empty JV slot
			var runner = GameManager.remove_varsity_runner(varsity_index)
			GameManager.add_jv_runner(runner)
		elif GameManager.jv_team.size() > 0:
			# Swap with first JV runner
			GameManager.swap_varsity_to_jv(varsity_index, 0)
		_update_display()

func _on_promote_jv(jv_index: int) -> void:
	# Promote JV runner to varsity (swap with first available varsity slot)
	if jv_index >= 0 and jv_index < GameManager.jv_team.size():
		# Find first empty varsity slot or swap with first varsity runner
		if GameManager.varsity_team.size() < 5:
			# Move to empty varsity slot
			var runner = GameManager.remove_jv_runner(jv_index)
			if runner != null:
				GameManager.add_varsity_runner(runner)
		elif GameManager.varsity_team.size() > 0:
			# Swap with first varsity runner
			GameManager.swap_varsity_to_jv(0, jv_index)
		_update_display()

func _on_remove_varsity(varsity_index: int) -> void:
	# Remove runner from varsity team
	if varsity_index >= 0 and varsity_index < GameManager.varsity_team.size():
		GameManager.remove_varsity_runner(varsity_index)
		_update_display()

func _on_remove_jv(jv_index: int) -> void:
	# Remove runner from JV team
	if jv_index >= 0 and jv_index < GameManager.jv_team.size():
		GameManager.remove_jv_runner(jv_index)
		_update_display()

func _on_back_button_pressed() -> void:
	# Return to previous scene (could be Run or Shop)
	# For now, go back to Run scene
	get_tree().change_scene_to_file("res://scenes/run/Run.tscn")
