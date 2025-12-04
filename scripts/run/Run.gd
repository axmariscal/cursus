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
@onready var status_label: Label = $UI/VBoxContainer/StatusLabel
@onready var race_status_label: Label = $UI/VBoxContainer/RaceStatusLabel
@onready var result_panel: Panel = $UI/VBoxContainer/ResultPanel
@onready var result_label: Label = $UI/VBoxContainer/ResultPanel/ResultLabel
@onready var start_race_button: Button = $UI/VBoxContainer/StartRaceButton
@onready var complete_race_button: Button = $UI/VBoxContainer/CompleteRaceButton
@onready var back_button: Button = $UI/VBoxContainer/BackButton

var previous_ante: int = 1

func _ready() -> void:
	# Connect buttons
	back_button.pressed.connect(_on_back_button_pressed)
	start_race_button.pressed.connect(_on_start_race_pressed)
	complete_race_button.pressed.connect(_on_complete_race_pressed)
	
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
		RaceState.RACING:
			race_status_label.text = "Race In Progress"
			race_status_label.visible = true
			_clear_result_display()
			start_race_button.disabled = true
			complete_race_button.disabled = false
		RaceState.COMPLETED:
			# Hide race status label when showing results to avoid redundancy
			race_status_label.visible = false
			start_race_button.disabled = false
			complete_race_button.disabled = true

func _clear_result_display() -> void:
	result_label.text = ""
	result_panel.visible = false

func _show_result_display(message: String) -> void:
	result_label.text = message
	result_panel.visible = true

func _on_start_race_pressed() -> void:
	if race_state == RaceState.IDLE or race_state == RaceState.COMPLETED:
		previous_ante = GameManager.current_ante
		_set_race_state(RaceState.RACING)
		print("Race started for Ante ", GameManager.current_ante)

func _on_complete_race_pressed() -> void:
	if race_state == RaceState.RACING:
		# Store previous ante before advancing
		var completed_ante = GameManager.current_ante
		
		# Complete the race and advance ante
		GameManager.advance_ante()
		
		# Update ante display
		_update_display()
		
		# Show detailed result (simplified to avoid redundancy)
		var result_message = "✓ Race Completed!\n\n"
		result_message += "Completed: Ante %d\n" % completed_ante
		result_message += "Now at: Ante %d" % GameManager.current_ante
		
		_show_result_display(result_message)
		
		# Set state to completed
		_set_race_state(RaceState.COMPLETED)
		
		print("Race completed. Now at Ante ", GameManager.current_ante)

func _on_back_button_pressed() -> void:
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/core/Main.tscn")

