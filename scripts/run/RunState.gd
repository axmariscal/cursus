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
	# Calculate win probability based on stats vs ante difficulty
	var player_strength = (GameManager.get_total_speed() + GameManager.get_total_endurance() + GameManager.get_total_stamina() + GameManager.get_total_power()) / 4.0
	var opponent_strength = 50 + (GameManager.current_ante * 10)
	return clamp((player_strength / opponent_strength) * 100, 0, 100)

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
	
	last_race_result = race_result
	race_state = RaceState.COMPLETED
	
	return race_result

func get_result_message(race_result: Dictionary) -> String:
	var result_message = ""
	var race_type_name = GameManager.get_race_type_name(race_result.race_type)
	result_message += "--- %s ---\n\n" % race_type_name
	
	if race_result.won:
		result_message += "✓ VICTORY!\n\n"
		var gold_reward = GameManager.calculate_race_reward()
		result_message += "Gold Earned: +%d\n\n" % gold_reward
	else:
		result_message += "✗ DEFEAT\n\n"
	
	result_message += "--- RACE RESULTS ---\n\n"
	result_message += "Total Teams: %d\n" % (race_result.team_scores.size())
	result_message += "Your Placement: %d%s\n\n" % [race_result.player_placement, _get_position_suffix(race_result.player_placement)]
	
	result_message += "Top Team Scores:\n"
	for i in range(min(3, race_result.team_scores.size())):
		var team_res = race_result.team_scores[i]
		var team_name = "Team %d" % (team_res.team_index + 1)
		if team_res.has("is_player") and team_res.is_player:
			team_name = "You"
		result_message += "  %d%s: %s (Score: %d)\n" % [i + 1, _get_position_suffix(i + 1), team_name, team_res.score]
	
	result_message += "\nYour Top 5 Finishes:\n"
	for i in range(min(5, race_result.player_positions.size())):
		var pos = race_result.player_positions[i]
		var suffix = _get_position_suffix(pos)
		result_message += "  %d%s place\n" % [pos, suffix]
	
	result_message += "\n"
	
	var completed_ante = race_result.get("completed_ante", GameManager.current_ante)
	if race_result.won:
		result_message += "Ante %d → Ante %d\n" % [completed_ante, GameManager.current_ante]
	else:
		result_message += "Run Ended at Ante %d" % completed_ante
	
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
