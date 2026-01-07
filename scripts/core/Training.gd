extends Control

# Training Phase Scene - allows players to train runners between races

# Workout type definitions
const WORKOUT_TYPES = {
	"speed": {"name": "Speed Training", "cost": 1, "base_gain": 2, "description": "Focus on speed"},
	"endurance": {"name": "Endurance Training", "cost": 1, "base_gain": 2, "description": "Focus on endurance"},
	"stamina": {"name": "Stamina Training", "cost": 1, "base_gain": 2, "description": "Focus on stamina"},
	"power": {"name": "Power Training", "cost": 1, "base_gain": 2, "description": "Focus on power"},
	"balanced": {"name": "Balanced Training", "cost": 1, "base_gain": 1.5, "description": "Small gains to all stats"},
	"recovery": {"name": "Recovery Session", "cost": 1, "base_gain": 0, "description": "Reduces injury meter"},
	"intensive": {"name": "Intensive Training", "cost": 2, "base_gain": 3, "description": "High gains, high injury risk"}
}

const MAX_TRAINING_PER_PHASE = 2  # Each runner can train 1-2 times per phase

# UI References
@onready var ante_label: Label = %AnteLabel
@onready var training_points_label: Label = %TrainingPointsLabel
@onready var runners_container: VBoxContainer = %RunnersContainer
@onready var workouts_container: HFlowContainer = %WorkoutsContainer
@onready var selected_runner_label: Label = %SelectedRunnerLabel
@onready var training_history_label: Label = %TrainingHistoryLabel
@onready var continue_button: Button = %ContinueButton
@onready var training_feedback_label: Label = %TrainingFeedbackLabel

# State
var selected_runner: String = ""  # Runner string (e.g., "Runner: Hill Specialist")
var training_sessions: Dictionary = {}  # Track training sessions per runner: {runner_string: sessions_used}

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	_reset_training_sessions()  # Initialize tracking for all runners
	_update_display()
	await get_tree().process_frame
	_display_runners()
	_display_workouts()
	
	# Hide feedback initially
	training_feedback_label.visible = false

func _reset_training_sessions() -> void:
	# Initialize training sessions tracking for all current runners
	training_sessions.clear()
	
	# Track varsity runners
	for runner_string in GameManager.varsity_team:
		training_sessions[runner_string] = 0
	
	# Track JV runners
	for runner_string in GameManager.jv_team:
		training_sessions[runner_string] = 0

func _update_display() -> void:
	ante_label.text = "Ante: %d" % GameManager.current_ante
	var points = GameManager.get_training_points()
	training_points_label.text = "🏋️ Training Points: %d" % points
	# Style training points label
	training_points_label.add_theme_color_override("font_color", Color(0.3, 0.7, 0.9))  # Blue color
	
	# Update selected runner display
	if selected_runner == "":
		selected_runner_label.text = "Selected: None"
		training_history_label.text = ""
	else:
		_update_selected_runner_display()

func _update_selected_runner_display() -> void:
	if selected_runner == "":
		return
	
	# Extract runner name for display
	var runner_name = selected_runner
	if ":" in selected_runner:
		runner_name = selected_runner.split(":")[1].strip_edges()
	
	selected_runner_label.text = "Selected: %s" % runner_name
	
	# Show training sessions used
	var sessions_used = training_sessions.get(selected_runner, 0)
	var sessions_text = "Training Sessions: %d / %d" % [sessions_used, MAX_TRAINING_PER_PHASE]
	
	# Get runner stats and injury status
	var runner = Runner.from_string(selected_runner)
	var stats = runner.get_display_stats()
	var injury_status = runner.get_injury_status()
	
	# Build history text
	var history_text = sessions_text + "\n\n"
	history_text += "Current Stats: Spd:%d End:%d Sta:%d Pow:%d\n" % [
		stats.current.speed, stats.current.endurance, stats.current.stamina, stats.current.power
	]
	
	# Show training gains
	var gains = stats.training_gains
	if gains.speed > 0 or gains.endurance > 0 or gains.stamina > 0 or gains.power > 0:
		history_text += "Training Gains: +%d Spd, +%d End, +%d Sta, +%d Pow\n" % [
			gains.speed, gains.endurance, gains.stamina, gains.power
		]
	
	# Show injury status
	if injury_status.is_injured:
		history_text += "⚠️ Injury: %.1f%% (%s)" % [injury_status.meter, injury_status.severity]
	else:
		history_text += "✓ Healthy (Injury: %.1f%%)" % injury_status.meter
	
	training_history_label.text = history_text

func _display_runners() -> void:
	_clear_runners()
	
	# Display varsity runners
	var varsity_header = Label.new()
	varsity_header.text = "VARSITY TEAM:"
	varsity_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	varsity_header.add_theme_font_size_override("font_size", 18)
	runners_container.add_child(varsity_header)
	
	for runner_string in GameManager.varsity_team:
		_create_runner_button(runner_string, true)
	
	# Display JV runners
	if GameManager.jv_team.size() > 0:
		var jv_header = Label.new()
		jv_header.text = "JV TEAM:"
		jv_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		jv_header.add_theme_font_size_override("font_size", 18)
		jv_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		runners_container.add_child(jv_header)
		
		for runner_string in GameManager.jv_team:
			_create_runner_button(runner_string, false)

func _create_runner_button(runner_string: String, is_varsity: bool) -> void:
	var runner = Runner.from_string(runner_string)
	var runner_name = runner.name
	var display_name = runner.display_name
	
	# Get stats for display
	var stats = runner.get_display_stats()
	var injury_status = runner.get_injury_status()
	var sessions_used = training_sessions.get(runner_string, 0)
	
	# Create button
	var button = Button.new()
	var button_text = runner_name
	if is_varsity:
		button_text = "⭐ " + button_text
	
	# Add stats info
	button_text += "\nSpd:%d End:%d Sta:%d Pow:%d" % [
		stats.current.speed, stats.current.endurance, stats.current.stamina, stats.current.power
	]
	
	# Add training sessions info
	button_text += "\nTraining: %d/%d" % [sessions_used, MAX_TRAINING_PER_PHASE]
	
	# Add injury status
	if injury_status.is_injured:
		button_text += "\n⚠️ Injured (%.0f%%)" % injury_status.meter
	else:
		button_text += "\n✓ Healthy"
	
	button.text = button_text
	button.custom_minimum_size = Vector2(200, 120)
	
	# Style button
	_style_runner_button(button, is_varsity, sessions_used >= MAX_TRAINING_PER_PHASE)
	
	# Connect signal
	button.pressed.connect(_on_runner_selected.bind(runner_string))
	
	runners_container.add_child(button)

func _style_runner_button(button: Button, is_varsity: bool, is_maxed: bool) -> void:
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
	
	var style_disabled = StyleBoxFlat.new()
	style_disabled.corner_radius_top_left = 5
	style_disabled.corner_radius_top_right = 5
	style_disabled.corner_radius_bottom_right = 5
	style_disabled.corner_radius_bottom_left = 5
	
	# Base color
	var base_color = Color(0.3, 0.5, 0.8) if is_varsity else Color(0.5, 0.5, 0.5)
	
	if is_maxed:
		base_color = Color(0.4, 0.4, 0.4)  # Gray when maxed
	
	style_normal.bg_color = Color(base_color.r, base_color.g, base_color.b, 0.7)
	style_hover.bg_color = Color(base_color.r, base_color.g, base_color.b, 0.9)
	style_disabled.bg_color = Color(0.2, 0.2, 0.2, 0.5)
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("disabled", style_disabled)
	
	if is_maxed:
		button.disabled = true

func _display_workouts() -> void:
	_clear_workouts()
	
	for workout_type in WORKOUT_TYPES.keys():
		var workout_data = WORKOUT_TYPES[workout_type]
		_create_workout_button(workout_type, workout_data)

func _create_workout_button(workout_type: String, workout_data: Dictionary) -> void:
	var button = Button.new()
	var button_text = workout_data.name
	button_text += "\nCost: %d TP" % workout_data.cost
	button_text += "\n%s" % workout_data.description
	
	button.text = button_text
	button.custom_minimum_size = Vector2(180, 100)
	
	# Store workout type in button metadata
	button.set_meta("workout_type", workout_type)
	
	# Style button
	_style_workout_button(button, workout_type)
	
	# Connect signal
	button.pressed.connect(_on_workout_selected.bind(workout_type))
	
	workouts_container.add_child(button)

func _style_workout_button(button: Button, workout_type: String) -> void:
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
	
	# Color by workout type
	var base_color = Color(0.4, 0.7, 0.4)  # Green default
	match workout_type:
		"speed":
			base_color = Color(0.9, 0.3, 0.3)  # Red
		"endurance":
			base_color = Color(0.3, 0.6, 0.9)  # Blue
		"stamina":
			base_color = Color(0.9, 0.6, 0.3)  # Orange
		"power":
			base_color = Color(0.7, 0.3, 0.9)  # Purple
		"balanced":
			base_color = Color(0.5, 0.5, 0.5)  # Gray
		"recovery":
			base_color = Color(0.3, 0.8, 0.5)  # Green
		"intensive":
			base_color = Color(0.9, 0.5, 0.1)  # Gold/Orange
	
	style_normal.bg_color = Color(base_color.r, base_color.g, base_color.b, 0.7)
	style_hover.bg_color = Color(base_color.r, base_color.g, base_color.b, 0.9)
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)

func _on_runner_selected(runner_string: String) -> void:
	selected_runner = runner_string
	_update_selected_runner_display()
	_update_workout_buttons()

func _on_workout_selected(workout_type: String) -> void:
	if selected_runner == "":
		_show_feedback("⚠️ Please select a runner first!", false)
		return
	
	# Check if runner can train more
	var sessions_used = training_sessions.get(selected_runner, 0)
	if sessions_used >= MAX_TRAINING_PER_PHASE:
		_show_feedback("⚠️ This runner has reached the training limit (%d sessions)!" % MAX_TRAINING_PER_PHASE, false)
		return
	
	# Check training points
	var workout_data = WORKOUT_TYPES[workout_type]
	var cost = workout_data.cost
	if GameManager.get_training_points() < cost:
		_show_feedback("⚠️ Not enough training points! Need %d, have %d" % [cost, GameManager.get_training_points()], false)
		return
	
	# Apply training using enhanced apply_training() method
	var runner = Runner.from_string(selected_runner)
	var base_gain = workout_data.base_gain
	
	# Get injury status before training
	var injury_before = runner.get_injury_status()
	
	# Apply training (handles all workout types including recovery and intensive)
	var gains = runner.apply_training(workout_type, base_gain)
	
	# Get injury status after training
	var injury_after = runner.get_injury_status()
	
	# Build feedback message
	var feedback_text = "✓ Training complete! "
	
	if workout_type == "recovery":
		# Recovery workout feedback
		var recovery_amount = injury_before.meter - injury_after.meter
		feedback_text += "Recovered %.1f%% injury. " % recovery_amount
		if injury_after.meter < 30.0 and injury_before.meter >= 30.0:
			feedback_text += "Runner is now healthy!"
		else:
			feedback_text += "Injury: %.1f%%" % injury_after.meter
	else:
		# Regular training feedback
		var gain_parts: Array[String] = []
		if gains.speed > 0:
			gain_parts.append("+%d Speed" % gains.speed)
		if gains.endurance > 0:
			gain_parts.append("+%d Endurance" % gains.endurance)
		if gains.stamina > 0:
			gain_parts.append("+%d Stamina" % gains.stamina)
		if gains.power > 0:
			gain_parts.append("+%d Power" % gains.power)
		
		if not gain_parts.is_empty():
			feedback_text += "Gains: " + ", ".join(gain_parts)
		else:
			feedback_text += "No stat gains."
		
		# Add injury warning for intensive training
		if workout_type == "intensive":
			feedback_text += "\n⚠️ High injury risk! "
			if injury_after.is_injured:
				feedback_text += "Runner is now injured (%.1f%%)!" % injury_after.meter
		elif injury_after.is_injured and not injury_before.is_injured:
			# Runner became injured during training
			feedback_text += "\n⚠️ Runner became injured (%.1f%%)!" % injury_after.meter
	
	_show_feedback(feedback_text, true)
	
	# Spend training points
	GameManager.spend_training_points(cost)
	
	# Increment training sessions
	training_sessions[selected_runner] = sessions_used + 1
	
	# Update display
	_update_display()
	_display_runners()
	_update_selected_runner_display()
	_update_workout_buttons()

func _update_workout_buttons() -> void:
	# Enable/disable workout buttons based on selected runner and available points
	var can_train = false
	var sessions_used = 0
	
	if selected_runner != "":
		sessions_used = training_sessions.get(selected_runner, 0)
		can_train = sessions_used < MAX_TRAINING_PER_PHASE
	
	for child in workouts_container.get_children():
		if child is Button:
			var button = child as Button
			var workout_type = button.get_meta("workout_type", "")
			var workout_data = WORKOUT_TYPES.get(workout_type, {})
			var cost = workout_data.get("cost", 1)
			
			var can_afford = GameManager.get_training_points() >= cost
			var should_disable = not (can_afford and can_train and selected_runner != "")
			
			button.disabled = should_disable
			
			# Update button text to show why it's disabled
			if should_disable and selected_runner != "":
				var reason = ""
				if not can_afford:
					reason = " (Need %d TP)" % cost
				elif not can_train:
					reason = " (Max sessions)"
				# Don't change text if no runner selected (that's handled by empty selection)

func _clear_runners() -> void:
	for child in runners_container.get_children():
		child.queue_free()

func _clear_workouts() -> void:
	for child in workouts_container.get_children():
		child.queue_free()

func _show_feedback(message: String, is_success: bool) -> void:
	training_feedback_label.text = message
	training_feedback_label.visible = true
	
	if is_success:
		training_feedback_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	else:
		training_feedback_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	
	# Animate fade in/out
	var tween = create_tween()
	tween.tween_property(training_feedback_label, "modulate:a", 1.0, 0.2)
	await get_tree().create_timer(2.0).timeout
	tween = create_tween()
	tween.tween_property(training_feedback_label, "modulate:a", 0.0, 0.3)
	await tween.finished
	training_feedback_label.visible = false
	training_feedback_label.modulate.a = 1.0

func _on_continue_pressed() -> void:
	# Navigate back to Run scene (similar to Shop scene)
	get_tree().change_scene_to_file("res://scenes/run/Run.tscn")

