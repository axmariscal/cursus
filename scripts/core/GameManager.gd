extends Node

# High-level game/run state manager
# This persists the entire run, similar to Balatro's RunManager

var current_ante := 1
var max_ante := 20

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
	run_active = true
	gold = 100  # Starting gold
	varsity_team.clear()
	jv_team.clear()
	deck.clear()
	jokers.clear()
	shop_inventory.clear()
	
	# Give starting runners (5 basic varsity runners)
	_give_starting_runners()
	
	print("New run started with seed: ", seed, " Gold: ", gold)


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
	print("Advanced to ante ", current_ante)

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
	return 25 + (current_ante * 5)


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


# Generate an opponent team for the race
func generate_opponent_team() -> Array[String]:
	var opponent_team: Array[String] = []
	
	# Base opponent strength scales with ante
	var base_strength = 50 + (current_ante * 10)
	
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


# Simulate a race and return results
# Returns: Dictionary with player_positions, opponent_positions, player_score, opponent_score, won
func simulate_race() -> Dictionary:
	# Use seed for deterministic race results
	seed(seed + current_ante * 1000)
	
	# Generate opponent team
	var opponent_team = generate_opponent_team()
	
	# Calculate performance for all runners
	var all_runners: Array[Dictionary] = []
	
	# Add player varsity runners
	for runner in varsity_team:
		var performance = calculate_runner_performance(runner, true)
		all_runners.append({
			"name": runner,
			"performance": performance,
			"is_player": true
		})
	
	# Add opponent runners
	for runner in opponent_team:
		var performance = calculate_runner_performance(runner, false)
		all_runners.append({
			"name": runner,
			"performance": performance,
			"is_player": false
		})
	
	# Sort by performance (lower = better finish)
	all_runners.sort_custom(func(a, b): return a.performance < b.performance)
	
	# Assign positions
	var player_positions: Array[int] = []
	var opponent_positions: Array[int] = []
	
	for i in range(all_runners.size()):
		var position = i + 1  # 1st, 2nd, 3rd, etc.
		if all_runners[i].is_player:
			player_positions.append(position)
		else:
			opponent_positions.append(position)
	
	# Calculate team scores (sum of top 5 positions, lower = better)
	player_positions.sort()
	opponent_positions.sort()
	
	var player_score = 0
	var opponent_score = 0
	
	# Sum top 5 positions for each team
	for i in range(min(5, player_positions.size())):
		player_score += player_positions[i]
	
	for i in range(min(5, opponent_positions.size())):
		opponent_score += opponent_positions[i]
	
	# Determine winner (lower score wins)
	var won = player_score < opponent_score
	
	# Restore global RNG state
	randomize()
	
	return {
		"player_positions": player_positions,
		"opponent_positions": opponent_positions,
		"player_score": player_score,
		"opponent_score": opponent_score,
		"won": won,
		"all_runners": all_runners  # For detailed display
	}
