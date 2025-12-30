extends Node

# High-level game/run state manager
# This persists the entire run, similar to Balatro's RunManager

enum RaceType {
	DUAL_MEET,      # 2 teams (player + 1 opponent)
	TRI_MEET,       # 3 teams (player + 2 opponents)
	INVITATIONAL,   # 4-6 teams (player + 3-5 opponents)
	QUALIFIERS,     # 8-10 teams (player + 7-9 opponents)
	CHAMPIONSHIP    # 12+ teams (player + 11+ opponents)
}

var current_ante := 1
var max_ante := 20
var current_race_type: RaceType = RaceType.DUAL_MEET

# Team structure: 5 varsity + 2 JV
var varsity_team = []    # 5 varsity runners (main scoring team)
var jv_team = []         # 2 JV runners (support/development)
var deck = []            # race event cards (support items)
var jokers = []          # permanent runner modifiers
var shop_inventory = []  # practice/shop selections (equipment)

var seed = 0             # run RNG seed
var run_active := false

# Currency
var gold := 100          # Starting gold for new runs

# Base stats
var base_speed := 10
var base_endurance := 10
var base_stamina := 10
var base_power := 10


func start_new_run():
	seed = randi()
	randomize()
	current_ante = 1
	current_race_type = get_race_type_for_ante(current_ante)
	run_active = true
	gold = 100  # Starting gold
	varsity_team.clear()
	jv_team.clear()
	deck.clear()
	jokers.clear()
	shop_inventory.clear()
	
	# Give starting runners (5 basic varsity runners)
	_give_starting_runners()
	
	print("New run started with seed: ", seed, " Gold: ", gold, " Race Type: ", get_race_type_name())


func _give_starting_runners():
	# Give 5 balanced starting runners for varsity team
	# Mix of different types for variety
	var starting_runners = [
		"Runner: Sprinter",
		"Runner: Endurance Runner",
		"Runner: Sprinter",
		"Runner: Endurance Runner",
		"Runner: Sprinter"
	]
	
	for runner in starting_runners:
		add_varsity_runner(runner)
	
	print("Starting team: ", varsity_team.size(), " varsity runners")


func advance_ante():
	current_ante += 1
	# Update race type for new ante
	current_race_type = get_race_type_for_ante(current_ante)
	print("Advanced to ante ", current_ante, " Race Type: ", _get_race_type_name(current_race_type))

# ============================================
# RACE TYPE SYSTEM
# ============================================

func get_race_type_for_ante(ante: int) -> RaceType:
	# Determine race type based on ante with some randomness
	# Use seed for deterministic but varied results
	seed(seed + ante * 100)
	
	var base_type: RaceType
	if ante <= 5:
		# Early antes: Dual/Tri Meets
		base_type = RaceType.DUAL_MEET if randf() < 0.6 else RaceType.TRI_MEET
	elif ante <= 12:
		# Mid antes: Invitationals
		base_type = RaceType.INVITATIONAL
	elif ante <= 19:
		# Late antes: Qualifiers
		base_type = RaceType.QUALIFIERS
	else:
		# Final ante: Championship
		base_type = RaceType.CHAMPIONSHIP
	
	# Restore global RNG
	randomize()
	return base_type

func _get_race_type_name(race_type: RaceType) -> String:
	match race_type:
		RaceType.DUAL_MEET:
			return "Dual Meet"
		RaceType.TRI_MEET:
			return "Tri Meet"
		RaceType.INVITATIONAL:
			return "Invitational"
		RaceType.QUALIFIERS:
			return "Qualifiers"
		RaceType.CHAMPIONSHIP:
			return "Championship"
		_:
			return "Unknown"

func get_race_type_name(race_type: Variant = null) -> String:
	if race_type == null:
		return _get_race_type_name(current_race_type)
	else:
		return _get_race_type_name(race_type as RaceType)

# ============================================
# CURRENCY SYSTEM
# ============================================

func earn_gold(amount: int) -> void:
	gold += amount
	print("Earned %d gold. Total: %d" % [amount, gold])

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		print("Spent %d gold. Remaining: %d" % [amount, gold])
		return true
	print("Not enough gold! Need %d, have %d" % [amount, gold])
	return false

func get_gold() -> int:
	return gold

func calculate_race_reward() -> int:
	# Base reward: 25 gold + (ante * 5)
	# Early races give less, later races give more
	var base_reward = 25 + (current_ante * 5)
	
	# Scale with race type (championship = more gold)
	var race_type_multiplier = 1.0
	match current_race_type:
		RaceType.CHAMPIONSHIP:
			race_type_multiplier = 1.5  # 50% bonus
		RaceType.QUALIFIERS:
			race_type_multiplier = 1.3  # 30% bonus
		RaceType.INVITATIONAL:
			race_type_multiplier = 1.15  # 15% bonus
		RaceType.TRI_MEET:
			race_type_multiplier = 1.05  # 5% bonus
		_:
			race_type_multiplier = 1.0  # Base
	
	return int(base_reward * race_type_multiplier)


# Get item effect - returns a dictionary with stat bonuses
func get_item_effect(item_name: String, category: String) -> Dictionary:
	var effect = {
		"speed": 0,
		"endurance": 0,
		"stamina": 0,
		"power": 0,
		"multiplier": 1.0  # For boosts
	}
	
	# Extract base name (remove prefix like "Runner: ", "Card: ", etc.)
	var base_name = item_name
	if ":" in item_name:
		base_name = item_name.split(":")[1].strip_edges()
	
	match category:
		"team":
			# Runners add base stats
			match base_name:
				"Sprinter", "Speed Demon":
					effect.speed = 15
					effect.power = 5
				"Endurance Runner", "Marathon Runner":
					effect.endurance = 15
					effect.stamina = 10
				"Sprint Specialist":
					effect.speed = 20
					effect.power = 10
				# Rare runners
				"Elite Sprinter":
					effect.speed = 25
					effect.power = 15
				"Champion Runner":
					effect.speed = 20
					effect.endurance = 20
					effect.power = 10
				"All-Star Athlete":
					effect.speed = 18
					effect.endurance = 18
					effect.stamina = 15
					effect.power = 12
				_:
					effect.speed = 10
					effect.endurance = 10
		
		"deck":
			# Cards provide temporary boosts (tracked but not permanent)
			match base_name:
				"Speed Boost":
					effect.speed = 10
				"Stamina Card":
					effect.stamina = 15
				"Recovery Card":
					effect.stamina = 20
					effect.endurance = 5
				"Pace Card":
					effect.speed = 5
					effect.endurance = 10
				"Finish Strong":
					effect.power = 15
					effect.speed = 5
				# Rare deck cards
				"Power Surge":
					effect.speed = 20
					effect.power = 20
				"Final Sprint":
					effect.power = 25
					effect.speed = 15
				"Victory Lap":
					effect.speed = 15
					effect.endurance = 15
					effect.stamina = 15
					effect.power = 15
		
		"boosts":
			# Boosts provide multipliers or special effects
			match base_name:
				"Speed":
					effect.multiplier = 1.2  # 20% speed boost
				"Endurance":
					effect.multiplier = 1.15  # 15% endurance boost
				"Recovery":
					effect.stamina = 10
					effect.multiplier = 1.1
				"Pace":
					effect.speed = 5
					effect.endurance = 5
				"Stamina":
					effect.stamina = 15
				# Rare boosts
				"Elite Training":
					effect.multiplier = 1.3  # 30% multiplier
					effect.speed = 10
					effect.endurance = 10
				"Peak Performance":
					effect.multiplier = 1.25  # 25% multiplier
					effect.stamina = 20
					effect.power = 15
				"Champion's Edge":
					effect.multiplier = 1.35  # 35% multiplier
					effect.speed = 15
					effect.power = 10
		
		"equipment":
			# Equipment provides permanent bonuses
			match base_name:
				"Lightweight Shoes":
					effect.speed = 10
					effect.power = 5
				"Energy Gel":
					effect.stamina = 15
				"Training Program":
					effect.speed = 5
					effect.endurance = 10
					effect.stamina = 5
				"Recovery Kit":
					effect.stamina = 20
					effect.endurance = 5
				"Performance Monitor":
					effect.speed = 5
					effect.endurance = 5
					effect.stamina = 5
					effect.power = 5
				# Rare equipment
				"Pro Racing Shoes":
					effect.speed = 20
					effect.power = 15
				"Elite Training Kit":
					effect.speed = 10
					effect.endurance = 15
					effect.stamina = 15
					effect.power = 10
				"Championship Gear":
					effect.speed = 15
					effect.endurance = 15
					effect.stamina = 20
					effect.power = 15
	
	return effect


# Team management functions
func add_varsity_runner(runner_name: String) -> bool:
	# Returns true if added, false if team is full
	if varsity_team.size() >= 5:
		return false
	varsity_team.append(runner_name)
	return true

func add_jv_runner(runner_name: String) -> bool:
	# Returns true if added, false if JV is full
	if jv_team.size() >= 2:
		return false
	jv_team.append(runner_name)
	return true

func remove_varsity_runner(index: int) -> String:
	# Remove runner at index, return runner name
	if index >= 0 and index < varsity_team.size():
		return varsity_team.pop_at(index)
	return ""

func remove_jv_runner(index: int) -> String:
	# Remove runner at index, return runner name
	if index >= 0 and index < jv_team.size():
		return jv_team.pop_at(index)
	return ""

func replace_varsity_runner(index: int, new_runner: String) -> String:
	# Replace runner at index, return old runner name
	if index >= 0 and index < varsity_team.size():
		var old_runner = varsity_team[index]
		varsity_team[index] = new_runner
		return old_runner
	return ""

func replace_jv_runner(index: int, new_runner: String) -> String:
	# Replace runner at index, return old runner name
	if index >= 0 and index < jv_team.size():
		var old_runner = jv_team[index]
		jv_team[index] = new_runner
		return old_runner
	return ""

func get_team_size() -> Dictionary:
	return {
		"varsity": varsity_team.size(),
		"jv": jv_team.size(),
		"total": varsity_team.size() + jv_team.size()
	}

# Swap functions for team management
func swap_varsity_to_jv(varsity_index: int, jv_index: int) -> bool:
	# Swap a varsity runner with a JV runner
	if varsity_index < 0 or varsity_index >= varsity_team.size():
		return false
	if jv_index < 0 or jv_index >= jv_team.size():
		return false
	
	var varsity_runner = varsity_team[varsity_index]
	var jv_runner = jv_team[jv_index]
	
	varsity_team[varsity_index] = jv_runner
	jv_team[jv_index] = varsity_runner
	return true

func promote_jv_to_varsity(jv_index: int, varsity_index: int) -> bool:
	# Promote a JV runner to varsity, demoting the varsity runner to JV
	if jv_index < 0 or jv_index >= jv_team.size():
		return false
	if varsity_index < 0 or varsity_index >= varsity_team.size():
		return false
	
	var jv_runner = jv_team[jv_index]
	var varsity_runner = varsity_team[varsity_index]
	
	varsity_team[varsity_index] = jv_runner
	jv_team[jv_index] = varsity_runner
	return true

func demote_varsity_to_jv(varsity_index: int, jv_index: int) -> bool:
	# Demote a varsity runner to JV, promoting the JV runner to varsity
	return promote_jv_to_varsity(jv_index, varsity_index)

# Calculate total stats from all items
# Varsity counts fully for scoring, JV provides 25% bonus (support/development)
func get_total_speed() -> int:
	var total = base_speed
	
	# Add varsity team bonuses (full value for race scoring)
	for runner in varsity_team:
		var effect = get_item_effect(runner, "team")
		total += effect.speed
	
	# Add JV team bonuses (25% value - support/development bonus)
	for runner in jv_team:
		var effect = get_item_effect(runner, "team")
		total += int(effect.speed * 0.25)  # JV provides 25% of their stats
	
	# Add equipment bonuses
	for equipment in shop_inventory:
		var effect = get_item_effect(equipment, "equipment")
		total += effect.speed
	
	# Apply boost multipliers
	var multiplier = 1.0
	for joker in jokers:
		var effect = get_item_effect(joker, "boosts")
		if effect.multiplier > 1.0:
			multiplier *= effect.multiplier
		total += effect.speed
	
	return int(total * multiplier)


func get_total_endurance() -> int:
	var total = base_endurance
	
	# Varsity counts fully for race scoring
	for runner in varsity_team:
		var effect = get_item_effect(runner, "team")
		total += effect.endurance
	
	# JV provides 25% bonus
	for runner in jv_team:
		var effect = get_item_effect(runner, "team")
		total += int(effect.endurance * 0.25)
	
	for equipment in shop_inventory:
		var effect = get_item_effect(equipment, "equipment")
		total += effect.endurance
	
	var multiplier = 1.0
	for joker in jokers:
		var effect = get_item_effect(joker, "boosts")
		if effect.multiplier > 1.0:
			multiplier *= effect.multiplier
		total += effect.endurance
	
	return int(total * multiplier)


func get_total_stamina() -> int:
	var total = base_stamina
	
	# Varsity counts fully for race scoring
	for runner in varsity_team:
		var effect = get_item_effect(runner, "team")
		total += effect.stamina
	
	# JV provides 25% bonus
	for runner in jv_team:
		var effect = get_item_effect(runner, "team")
		total += int(effect.stamina * 0.25)
	
	for equipment in shop_inventory:
		var effect = get_item_effect(equipment, "equipment")
		total += effect.stamina
	
	for joker in jokers:
		var effect = get_item_effect(joker, "boosts")
		total += effect.stamina
	
	return total


func get_total_power() -> int:
	var total = base_power
	
	# Varsity counts fully for race scoring
	for runner in varsity_team:
		var effect = get_item_effect(runner, "team")
		total += effect.power
	
	# JV provides 25% bonus
	for runner in jv_team:
		var effect = get_item_effect(runner, "team")
		total += int(effect.power * 0.25)
	
	for equipment in shop_inventory:
		var effect = get_item_effect(equipment, "equipment")
		total += effect.power
	
	return total


# ============================================
# RACE SCORING SYSTEM
# ============================================

# Calculate a runner's race performance score (lower = better finish)
# Based on stats with some randomness
func calculate_runner_performance(runner_name: String, is_player: bool = true) -> float:
	var effect = get_item_effect(runner_name, "team")
	
	# Base performance from stats
	# Speed + Power = early race performance
	# Endurance + Stamina = late race performance
	var speed_score = effect.speed * 0.4
	var power_score = effect.power * 0.3
	var endurance_score = effect.endurance * 0.2
	var stamina_score = effect.stamina * 0.1
	
	var base_performance = speed_score + power_score + endurance_score + stamina_score
	
	# Add randomness (10-20% variance)
	var variance = base_performance * (0.1 + (randf() * 0.1))
	if randf() < 0.5:
		variance = -variance  # Can be positive or negative
	
	var final_performance = base_performance + variance
	
	# For opponent teams, scale difficulty by ante
	if not is_player:
		var difficulty_multiplier = 1.0 + (current_ante * 0.15)  # 15% harder per ante
		final_performance *= difficulty_multiplier
	
	return final_performance


# Generate a single opponent team
func _generate_single_opponent_team(team_index: int = 0) -> Array[String]:
	var opponent_team: Array[String] = []
	
	# Base opponent strength scales with ante and race type
	var base_strength = 50 + (current_ante * 10)
	
	# Championship races have stronger opponents
	var difficulty_modifier = 1.0
	match current_race_type:
		RaceType.CHAMPIONSHIP:
			difficulty_modifier = 1.3  # 30% stronger
		RaceType.QUALIFIERS:
			difficulty_modifier = 1.2  # 20% stronger
		RaceType.INVITATIONAL:
			difficulty_modifier = 1.1  # 10% stronger
		_:
			difficulty_modifier = 1.0
	
	base_strength = int(base_strength * difficulty_modifier)
	
	# Generate 5 opponent runners
	for i in range(5):
		var strength = base_strength + (randi() % 20) - 10  # ±10 variance
		
		# Create a runner name based on strength
		var runner_type = ""
		if strength < 60:
			runner_type = "Endurance Runner"
		elif strength < 70:
			runner_type = "Sprinter"
		else:
			runner_type = "Sprint Specialist"
		
		opponent_team.append("Runner: " + runner_type)
	
	return opponent_team

# Generate all opponent teams based on race type
func generate_opponent_teams() -> Array[Array]:
	var opponent_teams: Array[Array] = []
	var num_opponents = 0
	
	match current_race_type:
		RaceType.DUAL_MEET:
			num_opponents = 1
		RaceType.TRI_MEET:
			num_opponents = 2
		RaceType.INVITATIONAL:
			num_opponents = 3 + randi() % 3  # 3-5 opponents
		RaceType.QUALIFIERS:
			num_opponents = 6 + randi() % 4  # 6-9 opponents
		RaceType.CHAMPIONSHIP:
			num_opponents = 10 + randi() % 5  # 10-14 opponents
	
	for i in range(num_opponents):
		opponent_teams.append(_generate_single_opponent_team(i))
	
	return opponent_teams


# Simulate a race and return results
# Returns: Dictionary with player_positions, team_scores, placement, won, race_type
func simulate_race() -> Dictionary:
	# Use seed for deterministic race results
	seed(seed + current_ante * 1000)
	
	# Generate all opponent teams based on race type
	var opponent_teams = generate_opponent_teams()
	
	# Calculate performance for all runners
	var all_runners: Array[Dictionary] = []
	
	# Add player varsity runners
	for runner in varsity_team:
		var performance = calculate_runner_performance(runner, true)
		all_runners.append({
			"name": runner,
			"performance": performance,
			"team_id": "player",
			"team_index": -1  # -1 for player
		})
	
	# Add opponent runners from all teams
	for team_index in range(opponent_teams.size()):
		var opponent_team = opponent_teams[team_index]
		for runner in opponent_team:
			var performance = calculate_runner_performance(runner, false)  # false = is opponent
			all_runners.append({
				"name": runner,
				"performance": performance,
				"team_id": "opponent",
				"team_index": team_index
			})
	
	# Sort by performance (lower = better finish)
	all_runners.sort_custom(func(a, b): return a.performance < b.performance)
	
	# Assign positions and track by team
	var player_positions: Array[int] = []
	var team_positions: Dictionary = {}  # team_index -> [positions]
	
	# Initialize team positions
	team_positions[-1] = []  # Player team
	for i in range(opponent_teams.size()):
		team_positions[i] = []
	
	# Assign positions
	for i in range(all_runners.size()):
		var position = i + 1  # 1st, 2nd, 3rd, etc.
		var team_index = all_runners[i].team_index
		
		if team_index == -1:
			player_positions.append(position)
		else:
			if not team_positions.has(team_index):
				team_positions[team_index] = []
			team_positions[team_index].append(position)
	
	# Calculate team scores (sum of top 5 positions, lower = better)
	player_positions.sort()
	var player_score = 0
	for i in range(min(5, player_positions.size())):
		player_score += player_positions[i]
	
	# Calculate scores for all opponent teams
	var team_scores: Array[Dictionary] = []
	for team_index in range(opponent_teams.size()):
		if team_positions.has(team_index):
			var positions = team_positions[team_index]
			positions.sort()
			var score = 0
			for i in range(min(5, positions.size())):
				score += positions[i]
			team_scores.append({
				"team_index": team_index,
				"score": score,
				"positions": positions
			})
	
	# Add player score to comparison
	team_scores.append({
		"team_index": -1,
		"score": player_score,
		"positions": player_positions,
		"is_player": true
	})
	
	# Sort teams by score (lower = better)
	team_scores.sort_custom(func(a, b): return a.score < b.score)
	
	# Find player's placement
	var player_placement = 0
	for i in range(team_scores.size()):
		if team_scores[i].has("is_player") and team_scores[i].is_player:
			player_placement = i + 1  # 1st, 2nd, 3rd, etc.
			break
	
	# Determine win condition
	# For small meets (Dual/Tri), must be 1st
	# For larger meets, top 3 is acceptable
	var won = false
	match current_race_type:
		RaceType.DUAL_MEET, RaceType.TRI_MEET:
			won = player_placement == 1
		RaceType.INVITATIONAL:
			won = player_placement <= 2  # Top 2
		RaceType.QUALIFIERS:
			won = player_placement <= 3  # Top 3
		RaceType.CHAMPIONSHIP:
			won = player_placement <= 3  # Top 3
	
	# Restore global RNG state
	randomize()
	
	return {
		"player_positions": player_positions,
		"player_score": player_score,
		"team_scores": team_scores,  # All teams with scores
		"player_placement": player_placement,
		"won": won,
		"race_type": current_race_type,
		"race_type_name": get_race_type_name(),
		"total_teams": team_scores.size(),
		"all_runners": all_runners  # For detailed display
	}
