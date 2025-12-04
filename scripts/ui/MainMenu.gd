extends Node2D

@onready var new_run_button: Button = get_node("UI/New Run")
@onready var continue_button: Button = $UI/Continue
@onready var collection_button: Button = $UI/Collection

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect button signals
	new_run_button.pressed.connect(_on_new_run_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	collection_button.pressed.connect(_on_collection_pressed)

func _on_new_run_pressed() -> void:
	# Start a new run and transition to Run scene
	GameManager.start_new_run()
	get_tree().change_scene_to_file("res://scenes/run/Run.tscn")

func _on_continue_pressed() -> void:
	# Continue existing run if one is active
	if GameManager.run_active:
		get_tree().change_scene_to_file("res://scenes/run/Run.tscn")
	else:
		print("No active run to continue")

func _on_collection_pressed() -> void:
	# TODO: Implement collection view
	print("Collection button pressed - not yet implemented")
