extends Control

@onready var varsity_container: VBoxContainer = $UI/ScrollContainer/VBoxContainer/VarsitySection/VarsityContainer
@onready var jv_container: VBoxContainer = $UI/ScrollContainer/VBoxContainer/JVSection/JVContainer
@onready var back_button: Button = $UI/ScrollContainer/VBoxContainer/BackButton

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
			var effect = GameManager.get_item_effect(runner, "team")
			var runner_label = _create_runner_label("Slot %d: %s" % [i + 1, runner], effect)
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
			var effect = GameManager.get_item_effect(runner, "team")
			var runner_label = _create_runner_label("JV Slot %d: %s" % [i + 1, runner], effect)
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

