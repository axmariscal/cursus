extends Control

@onready var ante_label: Label = $UI/VBoxContainer/AnteLabel
@onready var seed_label: Label = $UI/VBoxContainer/SeedLabel
@onready var status_label: Label = $UI/VBoxContainer/StatusLabel
@onready var back_button: Button = $UI/VBoxContainer/BackButton

func _ready() -> void:
	# Connect the back button
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Update display with current run state
	_update_display()
	
	# Start a new run if one isn't active
	if not GameManager.run_active:
		GameManager.start_new_run()
		_update_display()

func _update_display() -> void:
	ante_label.text = "Ante: %d" % GameManager.current_ante
	seed_label.text = "Seed: %d" % GameManager.seed
	
	if GameManager.run_active:
		status_label.text = "Status: Run Active"
	else:
		status_label.text = "Status: No Active Run"

func _on_back_button_pressed() -> void:
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/core/Main.tscn")

