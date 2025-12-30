extends Control

enum RaceState {
	IDLE,
	RACING,
	COMPLETED
}

var race_state: RaceState = RaceState.IDLE

@onready var ante_label: Label = $UI/VBoxContainer/AnteLabel
@onready var progress_label: Label = $UI/VBoxContainer/ProgressLabel
@onready var seed_label: Label = $UI/VBoxContainer/SeedLabel
@onready var gold_label: Label = $UI/VBoxContainer/GoldLabel
@onready var speed_label: Label = $UI/VBoxContainer/SpeedLabel
@onready var endurance_label: Label = $UI/VBoxContainer/EnduranceLabel
@onready var stamina_label: Label = $UI/VBoxContainer/StaminaLabel
@onready var power_label: Label = $UI/VBoxContainer/PowerLabel
@onready var team_info_label: Label = $UI/VBoxContainer/TeamInfoLabel
@onready var status_label: Label = $UI/VBoxContainer/StatusLabel
@onready var race_status_label: Label = $UI/VBoxContainer/RaceStatusLabel
@onready var result_panel: Panel = $UI/VBoxContainer/ResultPanel
@onready var result_label: Label = $UI/VBoxContainer/ResultPanel/ResultLabel
@onready var start_race_button: Button = $UI/VBoxContainer/StartRaceButton
@onready var complete_race_button: Button = $UI/VBoxContainer/CompleteRaceButton
@onready var continue_to_shop_button: Button = $UI/VBoxContainer/ContinueToShopButton
@onready var view_team_button: Button = $UI/VBoxContainer/ViewTeamButton
@onready var back_button: Button = $UI/VBoxContainer/BackButton
@onready var loading_panel: Panel = $UI/LoadingPanel
@onready var loading_label: Label = $UI/LoadingPanel/LoadingLabel

var previous_ante: int = 1
var last_race_result: Dictionary = {}

func _ready() -> void:
	# Connect buttons
	back_button.pressed.connect(_on_back_button_pressed)
	start_race_button.pressed.connect(_on_start_race_pressed)
	complete_race_button.pressed.connect(_on_complete_race_pressed)
	continue_to_shop_button.pressed.connect(_on_continue_to_shop_pressed)
	view_team_button.pressed.connect(_on_view_team_pressed)
	
	# Update display with current run state
	_update_display()
	
	# Start a new run if one isn't active
	if not GameManager.run_active:
		GameManager.start_new_run()
		_update_display()
	
	# Initialize race state
	_set_race_state(RaceState.IDLE)

func _update_display() -> void:
	ante_label.text = "Ante: %d" % GameManager.current_ante
	progress_label.text = "Progress: %d / %d" % [GameManager.current_ante, GameManager.max_ante]
	seed_label.text = "Seed: %d" % GameManager.seed
	gold_label.text = "Gold: %d" % GameManager.get_gold()
	
	# Update stats
	speed_label.text = "Speed: %d" % GameManager.get_total_speed()
	endurance_label.text = "Endurance: %d" % GameManager.get_total_endurance()
	stamina_label.text = "Stamina: %d" % GameManager.get_total_stamina()
	power_label.text = "Power: %d" % GameManager.get_total_power()
	
	# Update team info
	var team_size = GameManager.get_team_size()
	team_info_label.text = "Team: %d Varsity, %d JV" % [team_size.varsity, team_size.jv]
	
	if GameManager.run_active:
		status_label.text = "Status: Run Active"
	else:
		status_label.text = "Status: No Active Run"

func _set_race_state(new_state: RaceState) -> void:
	race_state = new_state
	
	match race_state:
		RaceState.IDLE:
			race_status_label.text = "Ready to Start Race"
			race_status_label.visible = true
			_clear_result_display()
			start_race_button.disabled = false
			complete_race_button.disabled = true
			continue_to_shop_button.visible = false
		RaceState.RACING:
			race_status_label.text = "Race In Progress"
			race_status_label.visible = true
			_clear_result_display()
			start_race_button.disabled = true
			complete_race_button.disabled = false
			continue_to_shop_button.visible = false
		RaceState.COMPLETED:
			# Hide race status label when showing results to avoid redundancy
			race_status_label.visible = false
			start_race_button.disabled = false
			complete_race_button.disabled = true
			# Show continue button only if player won
			if last_race_result.has("won") and last_race_result.won:
				continue_to_shop_button.visible = true
			else:
				continue_to_shop_button.visible = false

func _clear_result_display() -> void:
	result_label.text = ""
	result_panel.visible = false
	continue_to_shop_button.visible = false

func _show_result_display(message: String) -> void:
	result_label.text = message
	result_panel.visible = true
	# Style the result panel for better visibility
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)  # Dark background with slight transparency
	style.border_color = Color(0.5, 0.5, 0.5, 1.0)  # Light gray border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	result_panel.add_theme_stylebox_override("panel", style)
	# Style the label text for better readability
	result_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	# Calculate approximate height needed based on line count
	var line_count = message.count("\n") + 1
	var estimated_height = max(200, line_count * 25 + 40)  # ~25px per line + padding
	result_panel.custom_minimum_size = Vector2(0, estimated_height)

func _on_start_race_pressed() -> void:
	if race_state == RaceState.IDLE or race_state == RaceState.COMPLETED:
		# Check if team is ready
		if GameManager.varsity_team.size() < 5:
			_show_result_display("❌ Cannot Start Race!\n\nYou need 5 varsity runners.\nCurrent: %d\n\nGo to Shop to recruit more runners." % GameManager.varsity_team.size())
			_set_race_state(RaceState.IDLE)
			return
		
		previous_ante = GameManager.current_ante
		_set_race_state(RaceState.RACING)
		print("Race started for Ante ", GameManager.current_ante)

func _on_complete_race_pressed() -> void:
	if race_state == RaceState.RACING:
		# Store previous ante
		var completed_ante = GameManager.current_ante
		
		# Check if player has a valid team
		if GameManager.varsity_team.size() < 5:
			_show_result_display("❌ Cannot race!\n\nYou need 5 varsity runners.\nCurrent: %d" % GameManager.varsity_team.size())
			_set_race_state(RaceState.IDLE)
			return
		
		# Simulate the race
		var race_result = GameManager.simulate_race()
		
		# Build result message
		var result_message = ""
		
		if race_result.won:
			result_message += "✓ VICTORY!\n\n"
			# Advance ante on win
			GameManager.advance_ante()
			# Award gold for winning
			var gold_reward = GameManager.calculate_race_reward()
			GameManager.earn_gold(gold_reward)
			result_message += "Gold Earned: +%d\n\n" % gold_reward
		else:
			result_message += "✗ DEFEAT\n\n"
			# End run on loss
			GameManager.run_active = false
		
		result_message += "--- RACE RESULTS ---\n\n"
		result_message += "Your Team Score: %d\n" % race_result.player_score
		result_message += "Opponent Score: %d\n\n" % race_result.opponent_score
		
		# Show top 5 positions
		result_message += "Your Top 5 Finishes:\n"
		for i in range(min(5, race_result.player_positions.size())):
			var pos = race_result.player_positions[i]
			var suffix = _get_position_suffix(pos)
			result_message += "  %d%s place\n" % [pos, suffix]
		
		result_message += "\n"
		
		if race_result.won:
			result_message += "Ante %d → Ante %d\n" % [completed_ante, GameManager.current_ante]
		else:
			result_message += "Run Ended at Ante %d" % completed_ante
		
		# Store race result for button handler
		last_race_result = race_result
		
		_show_result_display(result_message)
		
		# Update ante display
		_update_display()
		
		# Set state to completed
		_set_race_state(RaceState.COMPLETED)
		
		print("Race completed. Won: ", race_result.won, " Score: ", race_result.player_score, " vs ", race_result.opponent_score)
		
		# Don't automatically transition - wait for button click
		if not race_result.won:
			# On loss, wait a bit then go to main menu
			await get_tree().create_timer(3.0).timeout
			get_tree().change_scene_to_file("res://scenes/core/Main.tscn")

func _get_position_suffix(position: int) -> String:
	match position:
		1, 21, 31, 41, 51, 61, 71, 81, 91:
			return "st"
		2, 22, 32, 42, 52, 62, 72, 82, 92:
			return "nd"
		3, 23, 33, 43, 53, 63, 73, 83, 93:
			return "rd"
		_:
			return "th"

func _on_continue_to_shop_pressed() -> void:
	# Show loading screen before transitioning to shop
	_show_loading_screen("Loading Shop...")
	# Give extra time for shop to prepare
	await get_tree().create_timer(0.5).timeout
	# Go to shop
	get_tree().change_scene_to_file("res://scenes/core/ShopScene.tscn")

func _on_view_team_pressed() -> void:
	# Open team management scene
	get_tree().change_scene_to_file("res://scenes/core/TeamManagement.tscn")

func _show_loading_screen(message: String) -> void:
	loading_label.text = message
	loading_panel.visible = true
	# Make loading panel cover everything with a semi-transparent background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)  # Dark semi-transparent background
	loading_panel.add_theme_stylebox_override("panel", style)

func _hide_loading_screen() -> void:
	loading_panel.visible = false

func _on_back_button_pressed() -> void:
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/core/Main.tscn")

