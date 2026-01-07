extends Node
class_name RunState

# Race state management and race logic

enum RaceState {
	IDLE,
	RACING,
	COMPLETED
}

var race_state: RaceState = RaceState.IDLE
var last_race_result: Dictionary = {}
var previous_ante: int = 1

func set_race_state(new_state: RaceState) -> void:
	race_state = new_state

func get_race_state() -> RaceState:
	return race_state

func calculate_win_probability() -> float:
	# Calculate win probability using Monte Carlo simulation to match actual race results
	return RaceLogic.calculate_win_probability_monte_carlo()

func can_start_race() -> bool:
	return GameManager.varsity_team.size() >= 5

func start_race() -> bool:
	if not can_start_race():
		return false
	
	previous_ante = GameManager.current_ante
	race_state = RaceState.RACING
	print("Race started for Ante ", GameManager.current_ante)
	return true

func complete_race() -> Dictionary:
	if race_state != RaceState.RACING:
		return {}
	
	if not can_start_race():
		return {}
	
	var completed_ante = GameManager.current_ante
	var race_result = GameManager.simulate_race()
	
	# Store the completed ante in the race result for message formatting
	race_result["completed_ante"] = completed_ante
	
	if race_result.won:
		GameManager.advance_ante()
		var gold_reward = GameManager.calculate_race_reward()
		GameManager.earn_gold(gold_reward)
	else:
		# Give consolation gold for losing to allow progression
		var consolation_reward = GameManager.calculate_consolation_reward()
		GameManager.earn_gold(consolation_reward)
	
	# Award training points based on race performance
	var training_points_earned = GameManager.calculate_training_points(race_result)
	GameManager.earn_training_points(training_points_earned)
	
	last_race_result = race_result
	race_state = RaceState.COMPLETED
	
	return race_result

func get_result_message(race_result: Dictionary) -> String:
	var result_message = ""
	var race_type_name = GameManager.get_race_type_name(race_result.race_type)
	result_message += "%s\n" % race_type_name
	
	if race_result.won:
		result_message += "\n✓ VICTORY!\n"
	else:
		result_message += "\n✗ DEFEAT\n"
	
	result_message += "\n"
	
	# Rewards section
	if race_result.won:
		var gold_reward = GameManager.calculate_race_reward()
		result_message += "Gold: +%d\n" % gold_reward
	else:
		var consolation_reward = GameManager.calculate_consolation_reward()
		result_message += "Gold: +%d\n" % consolation_reward
	
	var training_points_earned = GameManager.calculate_training_points(race_result)
	result_message += "Training Points: +%d\n" % training_points_earned
	
	result_message += "\n"
	result_message += "Team Placement: %d%s of %d\n" % [
		race_result.player_placement, 
		_get_position_suffix(race_result.player_placement),
		race_result.team_scores.size()
	]
	
	result_message += "\n"
	
	# Show runner finishing order with names
	result_message += "Your Runners' Finishes:\n"
	
	# Get all runners sorted by position from race result
	var all_runners = race_result.get("all_runners", [])
	if all_runners.size() > 0:
		# Find player runners and their positions
		var player_finishes: Array[Dictionary] = []
		for i in range(all_runners.size()):
			var runner_data = all_runners[i]
			if runner_data.get("team_index", 0) == -1:  # Player team
				var runner_name = runner_data.get("name", "Unknown")
				# Extract just the runner type name (remove "Runner: " prefix)
				var display_name = runner_name
				if ":" in runner_name:
					display_name = runner_name.split(":")[1].strip_edges()
				
				player_finishes.append({
					"position": i + 1,
					"name": display_name
				})
		
		# Sort by position
		player_finishes.sort_custom(func(a, b): return a.position < b.position)
		
		# Display top 5 or all if less than 5
		var num_to_show = min(5, player_finishes.size())
		for i in range(num_to_show):
			var finish = player_finishes[i]
			var pos = finish.position
			var suffix = _get_position_suffix(pos)
			var name = finish.name
			# Truncate long names to fit better
			if name.length() > 25:
				name = name.substr(0, 22) + "..."
			result_message += "  %d%s: %s\n" % [pos, suffix, name]
		
		if player_finishes.size() > 5:
			result_message += "  ... (%d total runners)\n" % player_finishes.size()
	else:
		# Fallback to old format if all_runners not available
		for i in range(min(5, race_result.player_positions.size())):
			var pos = race_result.player_positions[i]
			var suffix = _get_position_suffix(pos)
			result_message += "  %d%s place\n" % [pos, suffix]
	
	result_message += "\n"
	
	# Ante progression
	var completed_ante = race_result.get("completed_ante", GameManager.current_ante)
	if race_result.won:
		result_message += "Ante: %d → %d\n" % [completed_ante, GameManager.current_ante]
		
		# Check if division is completed
		if GameManager.current_ante >= GameManager.max_ante:
			result_message += "\n🏆 DIVISION COMPLETE! 🏆\n"
			result_message += "Completed: %s\n" % GameManager.division_config.get("name", "this division")
			# Check what was unlocked
			var next_unlock = GameManager.get_next_unlock(GameManager.current_division)
			if next_unlock != -1:
				var config = GameManager.get_division_config(next_unlock)
				if GameManager.is_division_unlocked(next_unlock):
					result_message += "Unlocked: %s" % config.get("name", "Unknown")
	else:
		result_message += "Ante: %d" % completed_ante
	
	return result_message

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
