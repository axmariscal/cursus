extends Control

# Training Phase Scene - allows players to train runners between races

# Workout type definitions
# Increased base_gain values to make training more impactful compared to shop items
# Shop items give team-wide bonuses (e.g., +10 speed to all 5 runners = +50 total)
# Training affects individual runners, so needs higher per-runner gains to compete
const WORKOUT_TYPES = {
	"speed": {"name": "Speed Training", "cost": 1, "base_gain": 5, "description": "Focus on speed"},
	"endurance": {"name": "Endurance Training", "cost": 1, "base_gain": 5, "description": "Focus on endurance"},
	"stamina": {"name": "Stamina Training", "cost": 1, "base_gain": 5, "description": "Focus on stamina"},
	"power": {"name": "Power Training", "cost": 1, "base_gain": 5, "description": "Focus on power"},
	"balanced": {"name": "Balanced Training", "cost": 1, "base_gain": 3, "description": "Small gains to all stats"},
	"recovery": {"name": "Recovery Session", "cost": 1, "base_gain": 0, "description": "Reduces injury meter"},
	"intensive": {"name": "Intensive Training", "cost": 2, "base_gain": 8, "description": "High gains, high injury risk"}
}

const MAX_TRAINING_PER_PHASE = 3  # Each runner can train up to 3 times per phase (increased from 2)

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
var selected_runner: Runner = null  # Selected Runner object
var training_sessions: Dictionary = {}  # Track training sessions per runner: {runner.unique_id: sessions_used}

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
	
	# Track varsity runners (they're already Runner objects)
	for runner in GameManager.varsity_team:
		training_sessions[runner.get_id()] = 0
	
	# Track JV runners (they're already Runner objects)
	for runner in GameManager.jv_team:
		training_sessions[runner.get_id()] = 0

func _update_display() -> void:
	ante_label.text = "Ante: %d" % GameManager.current_ante
	var points = GameManager.get_training_points()
	training_points_label.text = "🏋️ Training Points: %d" % points
	# Style training points label
	training_points_label.add_theme_color_override("font_color", Color(0.3, 0.7, 0.9))  # Blue color
	
	# Update selected runner display
	if selected_runner == null:
		selected_runner_label.text = "Selected: None"
		training_history_label.text = ""
	else:
		_update_selected_runner_display()

func _update_selected_runner_display() -> void:
	if selected_runner == null:
		return
	
	# Use runner properties directly
	selected_runner_label.text = "Selected: %s" % selected_runner.name
	
	# Show training sessions used (use unique_id as key)
	var sessions_used = training_sessions.get(selected_runner.get_id(), 0)
	var sessions_text = "Training Sessions: %d / %d" % [sessions_used, MAX_TRAINING_PER_PHASE]
	
	# Get runner stats and injury status
	var stats = selected_runner.get_display_stats()
	var injury_status = selected_runner.get_injury_status()
	
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
	
	for runner in GameManager.varsity_team:
		_create_runner_button(runner, true)
	
	# Display JV runners
	if GameManager.jv_team.size() > 0:
		var jv_header = Label.new()
		jv_header.text = "JV TEAM:"
		jv_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		jv_header.add_theme_font_size_override("font_size", 18)
		jv_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		runners_container.add_child(jv_header)
		
		for runner in GameManager.jv_team:
			_create_runner_button(runner, false)

func _create_runner_button(runner: Runner, is_varsity: bool) -> void:
	var runner_name = runner.name
	var display_name = runner.display_name
	
	# Get stats for display
	var stats = runner.get_display_stats()
	var injury_status = runner.get_injury_status()
	var sessions_used = training_sessions.get(runner.get_id(), 0)
	
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
	button.pressed.connect(_on_runner_selected.bind(runner))
	
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

func _on_runner_selected(runner: Runner) -> void:
	selected_runner = runner
	_update_selected_runner_display()
	_update_workout_buttons()

func _on_workout_selected(workout_type: String) -> void:
	if selected_runner == null:
		_show_feedback("⚠️ Please select a runner first!", false)
		return
	
	# Check if runner can train more (use unique_id as key)
	var sessions_used = training_sessions.get(selected_runner.get_id(), 0)
	if sessions_used >= MAX_TRAINING_PER_PHASE:
		_show_feedback("⚠️ This runner has reached the training limit (%d sessions)!" % MAX_TRAINING_PER_PHASE, false)
		return
	
	# Check training points
	var workout_data = WORKOUT_TYPES[workout_type]
	var cost = workout_data.cost
	if GameManager.get_training_points() < cost:
		_show_feedback("⚠️ Not enough training points! Need %d, have %d" % [cost, GameManager.get_training_points()], false)
		return
	
	# Generate a fixed seed for consistent before/after comparison
	# This eliminates random variance so we can see the actual impact of training
	var comparison_seed = randi()  # Generate once, use for both before and after
	
	# Get win probability BEFORE training (using fixed seed)
	# IMPORTANT: Set seed before calculation to ensure deterministic results
	seed(comparison_seed)
	var win_prob_before = RaceLogic.calculate_win_probability_monte_carlo(comparison_seed)
	var team_stats_before = _get_team_stats_summary()
	var opponent_target_before = RaceLogic.calculate_target_opponent_strength()
	
	# Calculate individual runner strengths before training
	var runner_strengths_before: Dictionary = {}
	var team_avg_strength_before = 0.0
	for runner_obj in GameManager.varsity_team:
		var stats = runner_obj.get_display_stats()
		var strength = _calculate_runner_strength_from_stats(stats.current)
		runner_strengths_before[runner_obj.get_id()] = strength
		team_avg_strength_before += strength
	team_avg_strength_before /= float(GameManager.varsity_team.size())
	
	# Use selected runner directly (already a Runner object)
	var runner = selected_runner
	var base_gain = workout_data.base_gain
	
	# Get runner stats before training
	var runner_stats_before = runner.get_display_stats()
	var injury_before = runner.get_injury_status()
	
	# Apply training (handles all workout types including recovery and intensive)
	# Use a separate seed for training to avoid affecting race simulation RNG state
	# This ensures training's randf() calls don't interfere with opponent generation
	var training_seed = comparison_seed + 999999  # Large offset to separate from race RNG
	seed(training_seed)
	var gains = runner.apply_training(workout_type, base_gain)
	
	# Reset seed before "after" calculation to ensure same RNG sequence as "before"
	seed(comparison_seed)
	
	# Get runner stats after training
	var runner_stats_after = runner.get_display_stats()
	var injury_after = runner.get_injury_status()
	
	# Get win probability AFTER training (using SAME fixed seed for fair comparison)
	var win_prob_after = RaceLogic.calculate_win_probability_monte_carlo(comparison_seed)
	var team_stats_after = _get_team_stats_summary()
	var opponent_target_after = RaceLogic.calculate_target_opponent_strength()
	
	# Calculate individual runner strengths after training
	var runner_strengths_after: Dictionary = {}
	var team_avg_strength_after = 0.0
	for runner_obj in GameManager.varsity_team:
		var stats = runner_obj.get_display_stats()
		var strength = _calculate_runner_strength_from_stats(stats.current)
		runner_strengths_after[runner_obj.get_id()] = strength
		team_avg_strength_after += strength
	team_avg_strength_after /= float(GameManager.varsity_team.size())
	
	# Log training impact (pass runner object for logging)
	_log_training_impact(selected_runner, workout_type, runner_stats_before, runner_stats_after, 
		win_prob_before, win_prob_after, team_stats_before, team_stats_after, opponent_target_before, opponent_target_after,
		runner_strengths_before, runner_strengths_after, team_avg_strength_before, team_avg_strength_after, comparison_seed)
	
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
	
	# Increment training sessions (use unique_id as key)
	training_sessions[selected_runner.get_id()] = sessions_used + 1
	
	# Update display
	_update_display()
	_display_runners()
	_update_selected_runner_display()
	_update_workout_buttons()

func _update_workout_buttons() -> void:
	# Enable/disable workout buttons based on selected runner and available points
	var can_train = false
	var sessions_used = 0
	
	if selected_runner != null:
		sessions_used = training_sessions.get(selected_runner.get_id(), 0)
		can_train = sessions_used < MAX_TRAINING_PER_PHASE
	
	for child in workouts_container.get_children():
		if child is Button:
			var button = child as Button
			var workout_type = button.get_meta("workout_type", "")
			var workout_data = WORKOUT_TYPES.get(workout_type, {})
			var cost = workout_data.get("cost", 1)
			
			var can_afford = GameManager.get_training_points() >= cost
			var should_disable = not (can_afford and can_train and selected_runner != null)
			
			button.disabled = should_disable
			
			# Update button text to show why it's disabled
			if should_disable and selected_runner != null:
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

func _calculate_avg_team_strength(team_stats: Dictionary) -> float:
	# Calculate average team strength using the same formula as RaceLogic
	# This approximates what calculate_runner_strength would return
	var speed_score = team_stats.speed * 0.4
	var power_score = team_stats.power * 0.3
	var endurance_score = team_stats.endurance * 0.2
	var stamina_score = team_stats.stamina * 0.1
	var raw_stat_total = speed_score + power_score + endurance_score + stamina_score
	var base_strength = 15.0 / (1.0 + raw_stat_total / 10.0)
	return base_strength

func _calculate_runner_strength_from_stats(stats: Dictionary) -> float:
	# Calculate individual runner strength from stats
	var speed_score = stats.speed * 0.4
	var power_score = stats.power * 0.3
	var endurance_score = stats.endurance * 0.2
	var stamina_score = stats.stamina * 0.1
	var raw_stat_total = speed_score + power_score + endurance_score + stamina_score
	var base_strength = 15.0 / (1.0 + raw_stat_total / 10.0)
	return base_strength

func _get_team_stats_summary() -> Dictionary:
	# Calculate total team stats for debugging
	# Use get_item_effect to see what stats are actually used in race calculations
	var total_speed = 0
	var total_endurance = 0
	var total_stamina = 0
	var total_power = 0
	
	for runner in GameManager.varsity_team:
		# Use get_item_effect to see what race calculations actually use
		var effect = GameManager.get_item_effect(runner, "team")
		total_speed += effect.speed
		total_endurance += effect.endurance
		total_stamina += effect.stamina
		total_power += effect.power
	
	return {
		"speed": total_speed,
		"endurance": total_endurance,
		"stamina": total_stamina,
		"power": total_power,
		"total": total_speed + total_endurance + total_stamina + total_power
	}

func _log_training_impact(runner: Runner, workout_type: String, stats_before: Dictionary, 
		stats_after: Dictionary, win_prob_before: float, win_prob_after: float,
		team_stats_before: Dictionary, team_stats_after: Dictionary, 
		opponent_target_before: float, opponent_target_after: float,
		runner_strengths_before: Dictionary, runner_strengths_after: Dictionary,
		team_avg_strength_before: float, team_avg_strength_after: float, comparison_seed: int) -> void:
	
	var separator = "============================================================"
	print("\n" + separator)
	print("[TRAINING IMPACT DEBUG]")
	print(separator)
	
	# Runner info
	var runner_name = runner.name
	var runner_id = runner.get_id()
	
	print("Runner: %s (ID: %d)" % [runner_name, runner_id])
	print("Workout: %s" % workout_type)
	print("Comparison Seed: %d (fixed seed for consistent before/after comparison)" % comparison_seed)
	print("")
	
	# Runner stat changes
	print("RUNNER STAT CHANGES:")
	var before_current = stats_before.current
	var after_current = stats_after.current
	
	print("  Speed:    %d → %d (%+d)" % [before_current.speed, after_current.speed, after_current.speed - before_current.speed])
	print("  Endurance: %d → %d (%+d)" % [before_current.endurance, after_current.endurance, after_current.endurance - before_current.endurance])
	print("  Stamina:   %d → %d (%+d)" % [before_current.stamina, after_current.stamina, after_current.stamina - before_current.stamina])
	print("  Power:     %d → %d (%+d)" % [before_current.power, after_current.power, after_current.power - before_current.power])
	
	var runner_total_before = before_current.speed + before_current.endurance + before_current.stamina + before_current.power
	var runner_total_after = after_current.speed + after_current.endurance + after_current.stamina + after_current.power
	print("  Total:     %d → %d (%+d)" % [runner_total_before, runner_total_after, runner_total_after - runner_total_before])
	print("")
	
	# Team stat changes
	print("TEAM STAT CHANGES (Varsity Total):")
	print("  Speed:    %d → %d (%+d)" % [team_stats_before.speed, team_stats_after.speed, team_stats_after.speed - team_stats_before.speed])
	print("  Endurance: %d → %d (%+d)" % [team_stats_before.endurance, team_stats_after.endurance, team_stats_after.endurance - team_stats_before.endurance])
	print("  Stamina:   %d → %d (%+d)" % [team_stats_before.stamina, team_stats_after.stamina, team_stats_after.stamina - team_stats_before.stamina])
	print("  Power:     %d → %d (%+d)" % [team_stats_before.power, team_stats_after.power, team_stats_after.power - team_stats_before.power])
	print("  Total:     %d → %d (%+d)" % [team_stats_before.total, team_stats_after.total, team_stats_after.total - team_stats_before.total])
	print("")
	
	# Win probability changes
	var win_prob_change = win_prob_after - win_prob_before
	var win_prob_change_pct = 0.0
	if win_prob_before > 0:
		win_prob_change_pct = (win_prob_change / win_prob_before) * 100.0
	
	print("WIN PROBABILITY IMPACT (Fixed Seed Comparison):")
	print("  Before: %.2f%%" % win_prob_before)
	print("  After:  %.2f%%" % win_prob_after)
	print("  Change: %+.2f%% (%+.2f%%)" % [win_prob_change, win_prob_change_pct])
	
	if abs(win_prob_change) < 0.1:
		print("  ⚠️  WARNING: Win probability change is minimal (< 0.1%)!")
		print("     Possible reasons:")
		print("     - Training only affects 1/5 of team (20% impact)")
		print("     - Diminishing returns in performance formula")
		print("     - Team scoring uses sum of top 5 positions (one strong runner helps less)")
		print("     - Check if Runner objects are being used in get_item_effect()")
	else:
		if win_prob_change > 0:
			print("  ✓ Win probability IMPROVED! Training is working!")
		else:
			print("  ⚠️  Win probability DECREASED. This shouldn't happen with fixed seed.")
			print("     Possible causes:")
			print("     - Bug in stat calculation or application")
			print("     - Training gains not being applied correctly")
			print("     - Check debug output above for clues")
	
	# Show what stats race calculations are actually using
	# Note: We can't get "before" stats from get_item_effect after training is applied
	# because the Runner object has been modified. So we compare with runner_stats_before
	print("STATS USED IN RACE CALCULATIONS (via get_item_effect):")
	var race_effect_after = GameManager.get_item_effect(runner, "team")
	
	print("  Runner Stats (from Runner object):")
	print("    Before: Spd:%d End:%d Sta:%d Pow:%d" % [
		stats_before.current.speed, stats_before.current.endurance,
		stats_before.current.stamina, stats_before.current.power
	])
	print("    After:  Spd:%d End:%d Sta:%d Pow:%d" % [
		stats_after.current.speed, stats_after.current.endurance,
		stats_after.current.stamina, stats_after.current.power
	])
	print("  Race Calculation (via get_item_effect):")
	print("    After:  Spd:%d End:%d Sta:%d Pow:%d" % [
		race_effect_after.speed, race_effect_after.endurance,
		race_effect_after.stamina, race_effect_after.power
	])
	
	# Check if training gains are being used
	var using_trained_stats = (
		race_effect_after.speed == stats_after.current.speed and
		race_effect_after.endurance == stats_after.current.endurance and
		race_effect_after.stamina == stats_after.current.stamina and
		race_effect_after.power == stats_after.current.power
	)
	
	if using_trained_stats:
		print("  ✓ Race calculations ARE using trained stats!")
		print("    get_item_effect() returns the same stats as Runner.get_effective_stats()")
	else:
		print("  ⚠️  Race calculations are NOT using trained stats!")
		print("     Race is using: %d/%d/%d/%d" % [
			race_effect_after.speed, race_effect_after.endurance, race_effect_after.stamina, race_effect_after.power
		])
		print("     Trained stats: %d/%d/%d/%d" % [
			stats_after.current.speed, stats_after.current.endurance,
			stats_after.current.stamina, stats_after.current.power
		])
		print("     ⚠️  BUG: Training gains are not being applied to race calculations!")
		print("     Check GameManager.get_item_effect() and Runner.get_effective_stats()")
	print("")
	
	# Show opponent scaling impact
	print("OPPONENT SCALING ANALYSIS:")
	
	var ante = GameManager.current_ante
	var difficulty_multiplier = 1.0 + (pow(ante, 1.1) * 0.20)
	
	print("  Player Team Avg Strength (before): %.2f" % team_avg_strength_before)
	print("  Player Team Avg Strength (after):  %.2f" % team_avg_strength_after)
	print("  Opponent Target Base (before):     %.2f" % opponent_target_before)
	print("  Opponent Target Base (after):      %.2f" % opponent_target_after)
	print("  Difficulty Multiplier (Ante %d):    %.2fx" % [ante, difficulty_multiplier])
	print("  Effective Opponent Strength:       %.2f" % (opponent_target_before * difficulty_multiplier))
	print("")
	
	# Check if opponent target changed
	var opponent_target_change = abs(opponent_target_after - opponent_target_before)
	if opponent_target_change < 0.01:
		print("  ✓ CORRECT: Opponents ONLY scale with ante, NOT with player strength!")
		print("     Opponent target stayed at %.2f (fixed base strength)" % opponent_target_before)
		print("     Training, equipment, and boosts now give you a REAL advantage!")
		print("")
		
		# Calculate performance ratio
		var player_performance_ratio = team_avg_strength_after / max(0.001, opponent_target_before * difficulty_multiplier)
		print("  PERFORMANCE RATIO ANALYSIS:")
		print("     Player Strength / Opponent Strength = %.2f" % player_performance_ratio)
		if player_performance_ratio < 1.0:
			print("     ✓ Player is FASTER than opponents (ratio < 1.0)")
		else:
			print("     ⚠️  Player is SLOWER than opponents (ratio > 1.0)")
		print("")
		
		# Explain why win probability might decrease
		if win_prob_after < win_prob_before:
			print("  ⚠️  Win probability DECREASED despite training:")
			print("     This is unexpected with fixed seed comparison!")
			print("     Possible causes:")
			print("     1. Bug in stat application (check 'STATS USED IN RACE CALCULATIONS' above)")
			print("     2. Training gains not being used in race calculations")
			print("     3. Diminishing returns making small stat gains ineffective")
			print("     4. Team scoring formula (sum of top 5) dilutes individual improvements")
		else:
			print("  ✓ Win probability IMPROVED! Training is working correctly!")
	else:
		print("  ⚠️  WARNING: Opponent target changed from %.2f → %.2f (%.2f change)" % [
			opponent_target_before, opponent_target_after, opponent_target_change
		])
		print("     This should NOT happen - opponents should only scale with ante!")
		print("     Check RaceLogic.calculate_target_opponent_strength() for bugs")
	print("")
	
	# Show individual runner strength changes
	print("INDIVIDUAL RUNNER STRENGTH CHANGES:")
	print("  (Lower strength = better performance)")
	for runner_id_key in runner_strengths_before.keys():
		# Get runner from registry to get display name
		var runner_obj = GameManager.get_runner_by_id(runner_id_key)
		var runner_display_name = "Unknown"
		if runner_obj != null:
			runner_display_name = runner_obj.name
		
		var strength_before = runner_strengths_before[runner_id_key]
		var strength_after = runner_strengths_after.get(runner_id_key, strength_before)
		var strength_change = strength_after - strength_before
		
		var marker = ""
		if runner_id_key == runner_id:
			marker = " ← TRAINED"
		
		print("    %s: %.2f → %.2f (%+.2f)%s" % [
			runner_display_name, strength_before, strength_after, strength_change, marker
		])
	
	print("")
	print("TEAM AVERAGE STRENGTH:")
	print("  Before: %.2f" % team_avg_strength_before)
	print("  After:  %.2f" % team_avg_strength_after)
	print("  Change: %+.2f (%.2f%%)" % [
		team_avg_strength_after - team_avg_strength_before,
		((team_avg_strength_after - team_avg_strength_before) / max(0.001, team_avg_strength_before)) * 100.0
	])
	print("  Note: Lower strength = better performance, so negative change is GOOD")
	print("")
	
	# Show which runner was trained and their position in team
	var runner_index = -1
	for i in range(GameManager.varsity_team.size()):
		if GameManager.varsity_team[i].get_id() == runner_id:
			runner_index = i
			break
	
	if runner_index >= 0:
		print("TRAINED RUNNER DETAILS:")
		print("  Position: %d of %d in varsity team" % [runner_index + 1, GameManager.varsity_team.size()])
		print("  Individual Strength: %.2f → %.2f (%+.2f)" % [
			runner_strengths_before[runner_id], runner_strengths_after[runner_id],
			runner_strengths_after[runner_id] - runner_strengths_before[runner_id]
		])
		print("  Team Impact: %.2f%% of team average strength" % [
			((runner_strengths_after[runner_id] - runner_strengths_before[runner_id]) / max(0.001, team_avg_strength_before)) * 100.0
		])
		print("")
	
	print("DIAGNOSTIC SUMMARY:")
	print("  ✓ Fixed seed comparison eliminates random variance")
	print("  ✓ Opponent scaling is independent of player training")
	
	if win_prob_after > win_prob_before:
		print("  ✓ Training improved win probability by %.2f%%" % (win_prob_after - win_prob_before))
	else:
		print("  ⚠️  Training did NOT improve win probability (check stats above)")
	
	print("")
	print("TIPS FOR MAXIMUM IMPACT:")
	print("     - Train multiple runners (not just one) for bigger team improvement")
	print("     - Combine training with equipment/boosts for multiplicative effects")
	print("     - Train your WEAKEST runners first (helps balance team)")
	print("     - Use intensive training for bigger gains (higher injury risk)")
	print("     - Remember: Team scoring uses sum of top 5 positions")
	print("       → One very strong runner helps less than 5 moderately improved runners")
	
	print(separator)
	print("")

func _on_continue_pressed() -> void:
	# Navigate back to Run scene (similar to Shop scene)
	get_tree().change_scene_to_file("res://scenes/run/Run.tscn")
