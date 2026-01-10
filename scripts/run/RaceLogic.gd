extends Node
class_name RaceLogic

# Race calculation logic module
# Handles: Monte Carlo win probability, opponent generation, performance variance, difficulty scaling

# Performance variance constants (15-30% instead of 10-20%)
const MIN_VARIANCE: float = 0.15
const MAX_VARIANCE: float = 0.30

# Difficulty scaling constants (steeper than before)
const BASE_DIFFICULTY_MULTIPLIER: float = 0.20  # 20% harder per ante (was 15%)
const DIFFICULTY_EXPONENT: float = 1.1  # Exponential scaling for steeper difficulty

# Monte Carlo simulation constants
const MONTE_CARLO_ITERATIONS: int = 500  # Number of simulations for win probability (reduced for performance)


# Calculate win probability using Monte Carlo simulation
# This matches the actual race simulation logic
# fixed_seed: Optional seed for consistent comparisons (e.g., before/after training)
static func calculate_win_probability_monte_carlo(fixed_seed: int = -1) -> float:
	if GameManager.varsity_team.size() < 5:
		print("[DEBUG] Win Probability: Team size < 5, returning 0%")
		return 0.0
	
	var wins = 0
	var original_seed_state = randi()  # Save current RNG state
	
	# Calculate player team strength for comparison
	var player_team_strength = 0.0
	var player_performances: Array[float] = []
	for runner in GameManager.varsity_team:
		var strength = calculate_runner_strength(runner, true)
		player_team_strength += strength
		player_performances.append(strength)
	var avg_player_strength = player_team_strength / float(GameManager.varsity_team.size())
	
	# Track opponent strengths for comparison
	var opponent_strengths: Array[float] = []
	var opponent_performances: Array[float] = []
	var player_race_performances: Array[float] = []
	var opponent_race_performances: Array[float] = []
	
	# Run Monte Carlo simulations
	for i in range(MONTE_CARLO_ITERATIONS):
		# Use a different seed for each simulation to get varied results
		# If fixed_seed is provided, use it for consistent comparisons
		var simulation_seed: int
		if fixed_seed >= 0:
			# Use fixed seed + iteration offset for consistent but varied simulations
			simulation_seed = fixed_seed + i * 10000
		else:
			# Normal mode: Base seed + iteration offset + ante offset
			simulation_seed = GameManager.seed + i * 10000 + GameManager.current_ante * 1000
		seed(simulation_seed)
		
		# Simulate a race
		var race_result = _simulate_single_race()
		
		# Track performance data for first few simulations
		if i < 5:
			var player_avg = race_result.get("avg_player_perf", 0.0)
			var opponent_avg = race_result.get("avg_opponent_perf", 0.0)
			var placement = race_result.get("player_placement", -1)
			var score = race_result.get("player_score", -1)
			
			print("[DEBUG] Simulation %d:" % i)
			print("  Player Avg Performance: %.2f (lower is better)" % player_avg)
			print("  Opponent Avg Performance: %.2f (lower is better)" % opponent_avg)
			print("  Performance Ratio: %.2f (player/opponent, >1 means player slower)" % (player_avg / max(0.001, opponent_avg)))
			print("  Player Score: %d (lower is better)" % score)
			print("  Placement: %d" % placement)
			print("  Won: %s" % race_result.won)
			print("")
		
		if race_result.won:
			wins += 1
		
		# Track average performances across all simulations
		if i == 0:
			# Initialize tracking arrays
			player_race_performances.clear()
			opponent_race_performances.clear()
		
		player_race_performances.append(race_result.get("avg_player_perf", 0.0))
		opponent_race_performances.append(race_result.get("avg_opponent_perf", 0.0))
	
	# Restore original RNG state
	randomize()
	
	# Calculate win probability
	var win_probability = (float(wins) / float(MONTE_CARLO_ITERATIONS)) * 100.0
	
	# DEBUG: Log comprehensive statistics
	var separator = "============================================================"
	print(separator)
	print("[DEBUG] WIN PROBABILITY CALCULATION")
	print(separator)
	print("Ante: %d | Race Type: %s" % [GameManager.current_ante, GameManager.get_race_type_name()])
	print("Team Size: %d varsity runners" % GameManager.varsity_team.size())
	print("")
	print("PLAYER STRENGTH:")
	print("  Average Runner Strength: %.2f" % avg_player_strength)
	print("  Total Team Strength: %.2f" % player_team_strength)
	print("  Individual Strengths: ", player_performances)
	print("")
	print("BOOSTS & EQUIPMENT:")
	print("  Boosts (Jokers): %d" % GameManager.jokers.size())
	for boost in GameManager.jokers:
		var effect = GameManager.get_item_effect(boost, "boosts")
		print("    - %s: multiplier=%.2f, speed=%d, power=%d, endurance=%d, stamina=%d" % [
			boost, effect.multiplier, effect.speed, effect.power, effect.endurance, effect.stamina
		])
	print("  Equipment: %d items" % GameManager.shop_inventory.size())
	print("  Deck Cards: %d cards" % GameManager.deck.size())
	print("")
	# Calculate average performances across all simulations
	var avg_player_race_perf = 0.0
	var avg_opponent_race_perf = 0.0
	if player_race_performances.size() > 0:
		for perf in player_race_performances:
			avg_player_race_perf += perf
		avg_player_race_perf /= float(player_race_performances.size())
	if opponent_race_performances.size() > 0:
		for perf in opponent_race_performances:
			avg_opponent_race_perf += perf
		avg_opponent_race_perf /= float(opponent_race_performances.size())
	
	print("OPPONENT STRENGTH:")
	# Calculate target opponent strength for comparison
	var target_opponent_strength = calculate_target_opponent_strength()
	var difficulty_multiplier = 1.0 + (pow(GameManager.current_ante, DIFFICULTY_EXPONENT) * BASE_DIFFICULTY_MULTIPLIER)
	print("  Target Base Strength: %.2f" % target_opponent_strength)
	print("  Difficulty Multiplier: %.2f (ante %d)" % [difficulty_multiplier, GameManager.current_ante])
	print("  Effective Opponent Strength: %.2f" % (target_opponent_strength * difficulty_multiplier))
	print("")
	print("RACE PERFORMANCE (across all simulations):")
	print("  Avg Player Performance: %.2f (lower = better finish)" % avg_player_race_perf)
	print("  Avg Opponent Performance: %.2f (lower = better finish)" % avg_opponent_race_perf)
	if avg_opponent_race_perf > 0:
		var perf_ratio = avg_player_race_perf / avg_opponent_race_perf
		print("  Performance Ratio: %.2f (player/opponent)" % perf_ratio)
		if perf_ratio > 1.0:
			print("    ⚠️  Player is SLOWER than opponents (ratio > 1.0)")
		else:
			print("    ✓ Player is FASTER than opponents (ratio < 1.0)")
	print("")
	print("MONTE CARLO RESULTS:")
	print("  Simulations: %d" % MONTE_CARLO_ITERATIONS)
	print("  Wins: %d" % wins)
	print("  Losses: %d" % (MONTE_CARLO_ITERATIONS - wins))
	print("  Win Probability: %.2f%%" % win_probability)
	if win_probability == 0.0:
		print("  ⚠️  WARNING: Win probability is 0% - opponents may be too strong!")
	print(separator)
	
	# Return win probability as percentage
	return win_probability


# Simulate a single race (used by Monte Carlo)
static func _simulate_single_race() -> Dictionary:
	# Generate all opponent teams based on race type
	var opponent_teams = generate_opponent_teams()
	
	# Calculate performance for all runners
	var all_runners: Array[Dictionary] = []
	
	# Track player and opponent performances for debugging
	var player_perfs: Array[float] = []
	var opponent_perfs: Array[float] = []
	
	# Add player varsity runners
	for runner in GameManager.varsity_team:
		var performance = calculate_runner_performance(runner, true)
		player_perfs.append(performance)
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
			opponent_perfs.append(performance)
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
	
	# Calculate average performances for debugging
	var avg_player_perf = 0.0
	var avg_opponent_perf = 0.0
	if player_perfs.size() > 0:
		for perf in player_perfs:
			avg_player_perf += perf
		avg_player_perf /= float(player_perfs.size())
	if opponent_perfs.size() > 0:
		for perf in opponent_perfs:
			avg_opponent_perf += perf
		avg_opponent_perf /= float(opponent_perfs.size())
	
	# Determine win condition
	var won = false
	match GameManager.current_race_type:
		GameManager.RaceType.DUAL_MEET, GameManager.RaceType.TRI_MEET:
			won = player_placement == 1
		GameManager.RaceType.INVITATIONAL:
			won = player_placement <= 2  # Top 2
		GameManager.RaceType.QUALIFIERS:
			won = player_placement <= 3  # Top 3
		GameManager.RaceType.CHAMPIONSHIP:
			won = player_placement <= 3  # Top 3
	
	return {
		"won": won,
		"player_placement": player_placement,
		"player_score": player_score,
		"avg_player_perf": avg_player_perf,
		"avg_opponent_perf": avg_opponent_perf,
		"player_perfs": player_perfs,
		"opponent_perfs": opponent_perfs
	}


# Calculate a runner's race performance score (lower = better finish)
# Updated with 15-30% variance and steeper difficulty scaling
static func calculate_runner_performance(runner_name: String, is_player: bool = true) -> float:
	# Get base runner stats
	var runner_effect = GameManager.get_item_effect(runner_name, "team")
	
	# For player runners, include all bonuses (equipment, boosts, deck cards)
	var speed = runner_effect.speed
	var power = runner_effect.power
	var endurance = runner_effect.endurance
	var stamina = runner_effect.stamina
	var multiplier = 1.0
	
	if is_player:
		# Add equipment bonuses (apply to all runners)
		for equipment in GameManager.shop_inventory:
			var equip_effect = GameManager.get_item_effect(equipment, "equipment")
			speed += equip_effect.speed
			power += equip_effect.power
			endurance += equip_effect.endurance
			stamina += equip_effect.stamina
		
		# Add boost bonuses (jokers) - both flat bonuses and multipliers
		for boost in GameManager.jokers:
			var boost_effect = GameManager.get_item_effect(boost, "boosts")
			speed += boost_effect.speed
			power += boost_effect.power
			endurance += boost_effect.endurance
			stamina += boost_effect.stamina
			if boost_effect.multiplier > 1.0:
				multiplier *= boost_effect.multiplier
		
		# Add deck card bonuses (apply to all runners)
		for card in GameManager.deck:
			var card_effect = GameManager.get_item_effect(card, "deck")
			speed += card_effect.speed
			power += card_effect.power
			endurance += card_effect.endurance
			stamina += card_effect.stamina
		
		# NOTE: Base stats should NOT be added per-runner in performance calculation
		# Base stats are team-wide bonuses that are already reflected in runner base stats
		# Adding them here makes players 3-4x slower than opponents!
		# The base stats (10 each) were causing player performance to be 15-20 vs opponent 4-5
		# speed += GameManager.base_speed  # REMOVED - causes massive performance imbalance
		# power += GameManager.base_power  # REMOVED
		# endurance += GameManager.base_endurance  # REMOVED
		# stamina += GameManager.base_stamina  # REMOVED
		
		# Apply multiplier to all stats
		speed = int(speed * multiplier)
		power = int(power * multiplier)
		endurance = int(endurance * multiplier)
		stamina = int(stamina * multiplier)
	else:
		# Opponents only get base runner stats (no equipment/boosts)
		speed = runner_effect.speed
		power = runner_effect.power
		endurance = runner_effect.endurance
		stamina = runner_effect.stamina
	
	# Base performance from stats
	# Speed + Power = early race performance
	# Endurance + Stamina = late race performance
	# IMPORTANT: Lower performance = better finish, so higher stats = lower performance
	var speed_score = speed * 0.4
	var power_score = power * 0.3
	var endurance_score = endurance * 0.2
	var stamina_score = stamina * 0.1
	
	# Calculate raw stat total (higher = better runner)
	var raw_stat_total = speed_score + power_score + endurance_score + stamina_score
	
	# Invert: higher stats = lower (better) performance
	# Use a scaling formula that prevents negative values
	# Formula: base_performance = base_value / (1 + raw_stat_total / scale_factor)
	# This ensures performance is always positive and scales smoothly
	var base_value = 15.0  # Base performance time
	var scale_factor = 10.0  # How much stats reduce performance
	var base_performance = base_value / (1.0 + raw_stat_total / scale_factor)
	
	# Ensure minimum performance (even very strong runners have some time)
	base_performance = max(base_performance, 1.0)
	
	# Add randomness (15-30% variance, increased from 10-20%)
	# Variance is applied to the base performance value
	var variance_range = MAX_VARIANCE - MIN_VARIANCE
	var variance = base_performance * (MIN_VARIANCE + (randf() * variance_range))
	if randf() < 0.5:
		variance = -variance  # Can be positive or negative
	
	var final_performance = base_performance + variance
	
	# For opponent teams, scale difficulty by ante (steeper scaling)
	# IMPORTANT: Since performance is inverted (lower = better), we divide to make opponents stronger
	# Dividing by > 1.0 makes performance lower (better finish) = opponents are stronger
	if not is_player:
		# Exponential scaling for steeper difficulty curve
		var difficulty_multiplier = 1.0 + (pow(GameManager.current_ante, DIFFICULTY_EXPONENT) * BASE_DIFFICULTY_MULTIPLIER)
		final_performance /= difficulty_multiplier  # Divide because lower = better
	
	return final_performance


# Calculate the total strength of a runner based on their stats
# For player runners, includes all bonuses (equipment, boosts, deck)
static func calculate_runner_strength(runner_name: String, is_player: bool = true) -> float:
	var runner_effect = GameManager.get_item_effect(runner_name, "team")
	
	# For player runners, include all bonuses (equipment, boosts, deck cards)
	var speed = runner_effect.speed
	var power = runner_effect.power
	var endurance = runner_effect.endurance
	var stamina = runner_effect.stamina
	var multiplier = 1.0
	
	if is_player:
		# Add equipment bonuses (apply to all runners)
		for equipment in GameManager.shop_inventory:
			var equip_effect = GameManager.get_item_effect(equipment, "equipment")
			speed += equip_effect.speed
			power += equip_effect.power
			endurance += equip_effect.endurance
			stamina += equip_effect.stamina
		
		# Add boost bonuses (jokers) - both flat bonuses and multipliers
		for boost in GameManager.jokers:
			var boost_effect = GameManager.get_item_effect(boost, "boosts")
			speed += boost_effect.speed
			power += boost_effect.power
			endurance += boost_effect.endurance
			stamina += boost_effect.stamina
			if boost_effect.multiplier > 1.0:
				multiplier *= boost_effect.multiplier
		
		# Add deck card bonuses (apply to all runners)
		for card in GameManager.deck:
			var card_effect = GameManager.get_item_effect(card, "deck")
			speed += card_effect.speed
			power += card_effect.power
			endurance += card_effect.endurance
			stamina += card_effect.stamina
		
		# NOTE: Base stats should NOT be added per-runner in strength calculation either
		# This matches the performance calculation fix above
		# speed += GameManager.base_speed  # REMOVED
		# power += GameManager.base_power  # REMOVED
		# endurance += GameManager.base_endurance  # REMOVED
		# stamina += GameManager.base_stamina  # REMOVED
		
		# Apply multiplier to all stats
		speed = int(speed * multiplier)
		power = int(power * multiplier)
		endurance = int(endurance * multiplier)
		stamina = int(stamina * multiplier)
	
	# Use the same formula as performance calculation (without variance)
	# IMPORTANT: Lower performance = better finish, so higher stats = lower performance
	var speed_score = speed * 0.4
	var power_score = power * 0.3
	var endurance_score = endurance * 0.2
	var stamina_score = stamina * 0.1
	
	# Calculate raw stat total (higher = better runner)
	var raw_stat_total = speed_score + power_score + endurance_score + stamina_score
	
	# Invert: higher stats = lower (better) performance
	# Use the same scaling formula as performance calculation (without variance)
	# Formula: base_strength = base_value / (1 + raw_stat_total / scale_factor)
	var base_value = 15.0  # Base performance time
	var scale_factor = 10.0  # How much stats reduce performance
	var base_strength = base_value / (1.0 + raw_stat_total / scale_factor)
	
	# Ensure minimum strength (even very strong runners have some time)
	base_strength = max(base_strength, 1.0)
	
	return base_strength


# Calculate target strength for an opponent team based on ante and race type
# This calculates the BASE strength (before difficulty multiplier is applied in performance)
# IMPORTANT: Opponents ONLY scale with ante, NOT with player team strength
# This makes player improvements (equipment, training, boosts) feel impactful
static func calculate_target_opponent_strength() -> float:
	# Fixed base opponent strength (independent of player team strength)
	# This is a performance value where lower = better finish
	# At ante 1, opponents are moderately challenging
	var base_opponent_strength = 6.0
	
	# Scale with ante: opponents get progressively stronger as ante increases
	# Each ante level makes opponents ~12% stronger (divide by scaling factor)
	# Ante 1: 6.0 (base)
	# Ante 2: 6.0 / 1.12 = 5.36 (~12% stronger)
	# Ante 3: 6.0 / 1.24 = 4.84 (~24% stronger)
	# Ante 4: 6.0 / 1.36 = 4.41 (~36% stronger)
	# etc.
	var ante_scaling_factor = 1.0 + ((GameManager.current_ante - 1) * 0.12)
	var scaled_strength = base_opponent_strength / ante_scaling_factor
	
	# Apply special rule opponent strength multiplier (e.g., elite_opponents makes them 20% stronger)
	# Since lower performance = better finish, divide by multiplier to make opponents stronger
	scaled_strength = scaled_strength / GameManager.opponent_base_strength_multiplier
	
	# Championship races have stronger opponents (applied to base, before difficulty multiplier)
	# IMPORTANT: With new formula, lower performance = better finish
	# To make opponents stronger, we multiply by a factor < 1.0 (lowers performance)
	# To make opponents weaker, we multiply by a factor > 1.0 (raises performance)
	var race_type_modifier = 1.0
	match GameManager.current_race_type:
		GameManager.RaceType.CHAMPIONSHIP:
			race_type_modifier = 0.85  # 15% stronger (multiply by < 1.0 to lower performance)
		GameManager.RaceType.QUALIFIERS:
			race_type_modifier = 0.90  # 10% stronger (multiply by < 1.0 to lower performance)
		GameManager.RaceType.INVITATIONAL:
			race_type_modifier = 0.95  # 5% stronger (multiply by < 1.0 to lower performance)
		_:
			race_type_modifier = 1.0
	
	# Return base strength (the difficulty multiplier will be applied during performance calculation)
	# Multiply by < 1.0 to make opponents stronger (lower performance = better finish)
	# Ensure minimum strength to prevent opponents from being too weak
	return max(scaled_strength * race_type_modifier, 1.0)


# Get base runner stats (without training gains or equipment)
# This is used for opponent scaling so training doesn't make opponents stronger
static func _get_base_runner_stats(runner_name: String) -> Dictionary:
	var effect = {
		"speed": 0,
		"endurance": 0,
		"stamina": 0,
		"power": 0
	}
	
	match runner_name:
		# Common Runners (Ante 1+)
		"Hill Specialist":
			effect.power = 15
			effect.speed = 5
		"Steady State Runner":
			effect.endurance = 15
			effect.stamina = 10
		"Tempo Runner":
			effect.endurance = 10
			effect.speed = 10
		"The Closer":
			effect.speed = 15
			effect.stamina = 5
		"Freshman Walk-on":
			effect.speed = 5
			effect.endurance = 5
			effect.stamina = 5
			effect.power = 5
		"Track Tourist":
			effect.speed = 22
			effect.power = -5  # Negative stat
		"Short-Cutter":
			effect.speed = 12
			effect.endurance = 8
		# Rare Runners (Ante 5+)
		"Elite V-State Harrier":
			effect.speed = 25
			effect.power = 15
		"All-Terrain Captain":
			effect.speed = 18
			effect.endurance = 18
			effect.stamina = 15
			effect.power = 12
		"Caffeine Fiend":
			effect.speed = 25
			effect.stamina = -15  # Negative stat
		"Ghost of the Woods":
			effect.endurance = 20
			effect.power = 12
		# Epic Runners (Ante 8+)
		"The Legend":
			effect.speed = 30
			effect.endurance = 30
		"JV Legend":
			effect.speed = 10
			effect.endurance = 10
			effect.stamina = 10
			effect.power = 10
		_:
			# Default fallback
			effect.speed = 10
			effect.endurance = 10
	
	return effect


# Generate a single opponent team with calculated strength
static func generate_single_opponent_team(team_index: int = 0) -> Array[String]:
	var opponent_team: Array[String] = []
	
	# Calculate target strength for this opponent team
	var target_strength = calculate_target_opponent_strength()
	var target_runner_strength = target_strength / 5.0  # Average strength per runner
	
	# Available runner types with their base strengths
	# Use is_player=false since opponents don't get equipment/boosts/deck
	var runner_types = [
		{"name": "Hill Specialist", "strength": calculate_runner_strength("Runner: Hill Specialist", false)},
		{"name": "Steady State Runner", "strength": calculate_runner_strength("Runner: Steady State Runner", false)},
		{"name": "Tempo Runner", "strength": calculate_runner_strength("Runner: Tempo Runner", false)},
		{"name": "The Closer", "strength": calculate_runner_strength("Runner: The Closer", false)},
		{"name": "Freshman Walk-on", "strength": calculate_runner_strength("Runner: Freshman Walk-on", false)},
		{"name": "Track Tourist", "strength": calculate_runner_strength("Runner: Track Tourist", false)},
		{"name": "Short-Cutter", "strength": calculate_runner_strength("Runner: Short-Cutter", false)},
	]
	
	# Generate 5 runners that approximate the target strength
	# Sort runners by strength to help with selection
	runner_types.sort_custom(func(a, b): return a.strength < b.strength)
	
	var current_team_strength = 0.0
	var remaining_slots = 5
	
	for i in range(5):
		var remaining_target = target_strength - current_team_strength
		var target_per_runner = remaining_target / float(remaining_slots)
		
		var best_runner = null
		var best_diff = INF
		
		# Find runner that gets us closest to target per runner
		for runner_data in runner_types:
			var diff = abs(runner_data.strength - target_per_runner)
			
			# Prefer runners close to target, with some randomness for variety
			if diff < best_diff:
				best_diff = diff
				best_runner = runner_data
			elif diff < best_diff * 1.2 and randf() < 0.2:  # 20% chance to pick slightly worse match for variety
				best_diff = diff
				best_runner = runner_data
		
		# Use the selected runner
		if best_runner != null:
			opponent_team.append("Runner: " + best_runner.name)
			current_team_strength += best_runner.strength
			remaining_slots -= 1
		else:
			# Fallback: pick the strongest available runner
			var strongest_runner = runner_types[runner_types.size() - 1]
			opponent_team.append("Runner: " + strongest_runner.name)
			current_team_strength += strongest_runner.strength
			remaining_slots -= 1
	
	return opponent_team


# Generate all opponent teams based on race type
static func generate_opponent_teams() -> Array[Array]:
	var opponent_teams: Array[Array] = []
	var num_opponents = 0
	
	match GameManager.current_race_type:
		GameManager.RaceType.DUAL_MEET:
			num_opponents = 1
		GameManager.RaceType.TRI_MEET:
			num_opponents = 2
		GameManager.RaceType.INVITATIONAL:
			num_opponents = 3 + randi() % 3  # 3-5 opponents
		GameManager.RaceType.QUALIFIERS:
			num_opponents = 6 + randi() % 4  # 6-9 opponents
		GameManager.RaceType.CHAMPIONSHIP:
			num_opponents = 10 + randi() % 5  # 10-14 opponents
	
	for i in range(num_opponents):
		opponent_teams.append(generate_single_opponent_team(i))
	
	return opponent_teams

