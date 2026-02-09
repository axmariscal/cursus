extends Control

# Run Failed screen (Phase 4.1) - shown when run ends (e.g. 3 losses in a row)

@onready var title_label: Label = %Title
@onready var stats_label: Label = %StatsLabel
@onready var main_menu_button: Button = %MainMenuButton
@onready var new_run_button: Button = %NewRunButton

func _ready() -> void:
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	new_run_button.pressed.connect(_on_new_run_pressed)
	_populate_stats()

func _populate_stats() -> void:
	var stats = GameManager.get_last_run_stats()
	if stats.is_empty():
		title_label.text = "Run Ended"
		stats_label.text = "No run data."
		return

	var reason = stats.get("reason", "unknown")
	if reason == "consecutive_losses":
		title_label.text = "Run Failed"
		stats_label.text = "You lost 3 races in a row.\n\n"
	else:
		title_label.text = "Run Ended"
		stats_label.text = ""

	stats_label.text += "Division: %s\n" % stats.get("division_name", "?")
	stats_label.text += "Ante reached: %d / %d\n" % [stats.get("ante_reached", 0), stats.get("max_ante", 1)]
	stats_label.text += "Races won: %d\n" % stats.get("races_won", 0)
	stats_label.text += "Final gold: %d\n" % stats.get("final_gold", 0)
	var gold_earned = stats.get("gold_earned", 0)
	if gold_earned >= 0:
		stats_label.text += "Gold earned this run: +%d" % gold_earned
	else:
		stats_label.text += "Gold earned this run: %d" % gold_earned

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/core/Main.tscn")

func _on_new_run_pressed() -> void:
	GameManager.start_new_run(GameManager.current_division)
	get_tree().change_scene_to_file("res://scenes/run/Run.tscn")
