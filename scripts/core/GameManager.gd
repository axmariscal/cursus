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
var race_counter = 0     # counter to vary seed between races at same ante
var run_active := false
var draft_completed := false  # Track if initial draft has been completed

# Currency
var gold := 100          # Starting gold for new runs
var training_points := 0  # Training points earned from races

# Base stats
var base_speed := 10
var base_endurance := 10
var base_stamina := 10
var base_power := 10

# ============================================
# DIVISION SYSTEM
# ============================================

enum Division {
	MIDDLE_SCHOOL,
	HIGH_SCHOOL,
	JUNIOR_COLLEGE,
	D3,
	D2,
	D1,
	POST_COLLEGIATE,
	PROFESSIONAL,
	WORLD_CONTENDER
}

var current_division: Division = Division.HIGH_SCHOOL
var unlocked_divisions: Array[Division] = [Division.MIDDLE_SCHOOL, Division.HIGH_SCHOOL]
var division_config: Dictionary = {}
var newly_unlocked_divisions: Array[Division] = []

# Track special rule modifiers
var shop_price_multiplier: float = 1.0
var reward_multiplier_modifier: float = 1.0
var enable_contracts: bool = false
var enable_sponsorships: bool = false
var no_consolation_gold: bool = false
var opponent_base_strength_multiplier: float = 1.0

# Division definitions - using enum as keys
const DIVISION_DATA = {
	Division.MIDDLE_SCHOOL: {
		"name": "Middle School",
		"starting_gold": 50,
		"antes": 3,
		"difficulty_curve": 0.10,
		"reward_multiplier": 0.5,
		"starting_team_tier": "basic",
		"unlock_requirement": null,
		"special_rules": [],
		"description": "Start your running journey"
	},
	Division.HIGH_SCHOOL: {
		"name": "High School",
		"starting_gold": 100,
		"antes": 5,
		"difficulty_curve": 0.15,
		"reward_multiplier": 1.0,
		"starting_team_tier": "common",
		"unlock_requirement": Division.MIDDLE_SCHOOL,
		"special_rules": [],
		"description": "Competitive high school racing"
	},
	Division.JUNIOR_COLLEGE: {
		"name": "Junior College",
		"starting_gold": 120,
		"antes": 6,
		"difficulty_curve": 0.18,
		"reward_multiplier": 1.2,
		"starting_team_tier": "common+",
		"unlock_requirement": Division.HIGH_SCHOOL,
		"special_rules": [],
		"description": "Step up to college competition"
	},
	Division.D3: {
		"name": "Division 3",
		"starting_gold": 150,
		"antes": 8,
		"difficulty_curve": 0.20,
		"reward_multiplier": 1.5,
		"starting_team_tier": "rare",
		"unlock_requirement": Division.JUNIOR_COLLEGE,
		"special_rules": [],
		"description": "NCAA Division 3 competition"
	},
	Division.D2: {
		"name": "Division 2",
		"starting_gold": 180,
		"antes": 10,
		"difficulty_curve": 0.22,
		"reward_multiplier": 1.8,
		"starting_team_tier": "rare+",
		"unlock_requirement": Division.D3,
		"special_rules": [],
		"description": "NCAA Division 2 - serious competition"
	},
	Division.D1: {
		"name": "Division 1",
		"starting_gold": 200,
		"antes": 12,
		"difficulty_curve": 0.25,
		"reward_multiplier": 2.0,
		"starting_team_tier": "epic",
		"unlock_requirement": Division.D2,
		"special_rules": [],
		"description": "Elite NCAA Division 1 racing"
	},
	Division.POST_COLLEGIATE: {
		"name": "Post Collegiate",
		"starting_gold": 150,
		"antes": 10,
		"difficulty_curve": 0.28,
		"reward_multiplier": 2.2,
		"starting_team_tier": "epic",
		"unlock_requirement": Division.D1,
		"special_rules": ["limited_funding"],
		"description": "Limited funding, maximum effort"
	},
	Division.PROFESSIONAL: {
		"name": "Professional",
		"starting_gold": 250,
		"antes": 15,
		"difficulty_curve": 0.30,
		"reward_multiplier": 2.5,
		"starting_team_tier": "legendary",
		"unlock_requirement": Division.POST_COLLEGIATE,
		"special_rules": ["contracts", "sponsorships"],
		"description": "Professional racing circuit"
	},
	Division.WORLD_CONTENDER: {
		"name": "World Contender",
		"starting_gold": 300,
		"antes": 20,
		"difficulty_curve": 0.35,
		"reward_multiplier": 3.0,
		"starting_team_tier": "legendary",
		"unlock_requirement": Division.PROFESSIONAL,
		"special_rules": ["no_consolation", "elite_opponents"],
		"description": "Elite world-class competition"
	}
}

# Runner rarity classifications
const RUNNER_TIERS = {
	"basic": [
		"Runner: Freshman Walk-on"  # Only basic runner
	],
	"common": [
		"Runner: Freshman Walk-on",
		"Runner: Hill Specialist",
		"Runner: Steady State Runner",
		"Runner: Tempo Runner",
		"Runner: The Closer"
	],
	"rare": [
		"Runner: Track Tourist",
		"Runner: Short-Cutter",
		"Runner: Hill Specialist",  # Can appear in multiple tiers
		"Runner: Tempo Runner",
		"Runner: The Closer"
	],
	"epic": [
		"Runner: Elite V-State Harrier",
		"Runner: All-Terrain Captain",
		"Runner: Caffeine Fiend",
		"Runner: Ghost of the Woods",
		"Runner: Track Tourist"  # Strong common runner
	],
	"legendary": [
		"Runner: The Legend",
		"Runner: Elite V-State Harrier",
		"Runner: All-Terrain Captain",
		"Runner: Ghost of the Woods",
		"Runner: JV Legend"  # Balanced legendary
	]
}

# Runner growth potential data
# Defines how well each runner type responds to training
# Values are multipliers: 1.0 = normal, >1.0 = better growth, <1.0 = slower growth
# Growth can be specialized (high in one stat) or balanced
const RUNNER_GROWTH_POTENTIAL = {
	# Common Runners
	"Freshman Walk-on": {
		"speed": 2.0,      # High growth - young and undeveloped
		"endurance": 2.0,
		"stamina": 2.0,
		"power": 2.0
	},
	"Hill Specialist": {
		"speed": 1.2,      # Moderate growth, specializes in power
		"endurance": 1.1,
		"stamina": 1.1,
		"power": 1.8       # High power growth (their specialty)
	},
	"Steady State Runner": {
		"speed": 1.1,      # Specializes in endurance/stamina
		"endurance": 1.7,
		"stamina": 1.8,
		"power": 1.1
	},
	"Tempo Runner": {
		"speed": 1.5,      # Balanced, good growth in speed/endurance
		"endurance": 1.6,
		"stamina": 1.3,
		"power": 1.2
	},
	"The Closer": {
		"speed": 1.6,      # Specializes in speed/stamina (finishing kick)
		"endurance": 1.2,
		"stamina": 1.7,
		"power": 1.3
	},
	# Rare Runners
	"Track Tourist": {
		"speed": 1.4,      # Already fast, moderate growth
		"endurance": 1.2,
		"stamina": 1.1,
		"power": 1.8       # Can improve power to offset negative stat
	},
	"Short-Cutter": {
		"speed": 1.5,      # Balanced growth
		"endurance": 1.6,
		"stamina": 1.4,
		"power": 1.3
	},
	# Epic Runners
	"Elite V-State Harrier": {
		"speed": 1.3,      # Already elite, slower growth
		"endurance": 1.2,
		"stamina": 1.1,
		"power": 1.4       # Can still improve power
	},
	"All-Terrain Captain": {
		"speed": 1.4,      # Well-rounded, good balanced growth
		"endurance": 1.5,
		"stamina": 1.5,
		"power": 1.4
	},
	"Caffeine Fiend": {
		"speed": 1.2,      # Already very fast, limited growth
		"endurance": 1.1,
		"stamina": 1.9,    # High stamina growth (to offset negative)
		"power": 1.2
	},
	"Ghost of the Woods": {
		"speed": 1.2,      # Specializes in endurance/power
		"endurance": 1.7,
		"stamina": 1.3,
		"power": 1.6
	},
	# Legendary Runners
	"The Legend": {
		"speed": 1.1,      # Near peak performance, minimal growth
		"endurance": 1.1,
		"stamina": 1.0,
		"power": 1.0
	},
	"JV Legend": {
		"speed": 1.3,      # Balanced legendary, moderate growth
		"endurance": 1.3,
		"stamina": 1.3,
		"power": 1.3
	}
}

# Save file path for unlocks
const UNLOCKS_SAVE_PATH = "user://unlocks.save"

func _ready() -> void:
	# Load unlocked divisions on game start
	load_unlocks()

func is_division_unlocked(division: Division) -> bool:
	return unlocked_divisions.has(division)

func unlock_division(division: Division) -> void:
	if not unlocked_divisions.has(division):
		unlocked_divisions.append(division)
		newly_unlocked_divisions.append(division)  # Track as newly unlocked
		save_unlocks()  # Persist to file
		show_unlock_notification(division)

func mark_division_viewed(division: Division) -> void:
	newly_unlocked_divisions.erase(division)

func is_division_newly_unlocked(division: Division) -> bool:
	return newly_unlocked_divisions.has(division)

func get_next_unlock(completed_division: Division) -> Division:
	# Find what division this one unlocks
	for div in Division.values():
		if DIVISION_DATA.has(div):
			var data = DIVISION_DATA[div]
			if data.get("unlock_requirement") == completed_division:
				return div
	return -1  # No unlock

func get_division_config(division: Division) -> Dictionary:
	if DIVISION_DATA.has(division):
		return DIVISION_DATA[division]
	return {}

func save_unlocks() -> void:
	# Convert enum array to string array for JSON serialization
	var unlock_strings: Array[String] = []
	for div in unlocked_divisions:
		unlock_strings.append(_division_to_string(div))
	
	var newly_unlocked_strings: Array[String] = []
	for div in newly_unlocked_divisions:
		newly_unlocked_strings.append(_division_to_string(div))
	
	var save_data = {
		"unlocked_divisions": unlock_strings,
		"newly_unlocked": newly_unlocked_strings,
		"version": 1
	}
	
	var file = FileAccess.open(UNLOCKS_SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		print("Saved unlocks to: ", UNLOCKS_SAVE_PATH)
	else:
		print("Error: Could not save unlocks to file")

func load_unlocks() -> void:
	if not FileAccess.file_exists(UNLOCKS_SAVE_PATH):
		# First time - use defaults
		unlocked_divisions = [Division.MIDDLE_SCHOOL, Division.HIGH_SCHOOL]
		newly_unlocked_divisions.clear()
		return
	
	var file = FileAccess.open(UNLOCKS_SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			if save_data.has("unlocked_divisions"):
				unlocked_divisions.clear()
				for div_string in save_data.unlocked_divisions:
					var div = _string_to_division(div_string)
					if div != -1:
						unlocked_divisions.append(div)
				
				# Load newly unlocked divisions if they exist
				newly_unlocked_divisions.clear()
				if save_data.has("newly_unlocked"):
					for div_string in save_data.newly_unlocked:
						var div = _string_to_division(div_string)
						if div != -1:
							newly_unlocked_divisions.append(div)
				
				print("Loaded unlocks: ", unlocked_divisions.size(), " divisions")
			else:
				# Fallback to defaults if format is wrong
				unlocked_divisions = [Division.MIDDLE_SCHOOL, Division.HIGH_SCHOOL]
				newly_unlocked_divisions.clear()
		else:
			print("Error parsing unlocks file, using defaults")
			unlocked_divisions = [Division.MIDDLE_SCHOOL, Division.HIGH_SCHOOL]
			newly_unlocked_divisions.clear()
	else:
		print("Error: Could not load unlocks file, using defaults")
		unlocked_divisions = [Division.MIDDLE_SCHOOL, Division.HIGH_SCHOOL]
		newly_unlocked_divisions.clear()

func _division_to_string(division: Division) -> String:
	match division:
		Division.MIDDLE_SCHOOL:
			return "middle_school"
		Division.HIGH_SCHOOL:
			return "high_school"
		Division.JUNIOR_COLLEGE:
			return "junior_college"
		Division.D3:
			return "d3"
		Division.D2:
			return "d2"
		Division.D1:
			return "d1"
		Division.POST_COLLEGIATE:
			return "post_collegiate"
		Division.PROFESSIONAL:
			return "professional"
		Division.WORLD_CONTENDER:
			return "world_contender"
		_:
			return ""

func _string_to_division(div_string: String) -> Division:
	match div_string:
		"middle_school":
			return Division.MIDDLE_SCHOOL
		"high_school":
			return Division.HIGH_SCHOOL
		"junior_college":
			return Division.JUNIOR_COLLEGE
		"d3":
			return Division.D3
		"d2":
			return Division.D2
		"d1":
			return Division.D1
		"post_collegiate":
			return Division.POST_COLLEGIATE
		"professional":
			return Division.PROFESSIONAL
		"world_contender":
			return Division.WORLD_CONTENDER
		_:
			return -1

func show_unlock_notification(division: Division) -> void:
	var config = get_division_config(division)
	var division_name = config.get("name", "Unknown Division")
	print("🎉 UNLOCKED: %s" % division_name)
	# TODO: Show in-game notification/popup
	# For now, just print to console

func start_new_run(division: Division = Division.HIGH_SCHOOL) -> void:
	current_division = division
	division_config = DIVISION_DATA[division]
	
	# Set run parameters
	seed = randi()
	race_counter = 0
	randomize()
	current_ante = 1
	max_ante = division_config.get("antes", 5)
	current_race_type = get_race_type_for_ante(current_ante)
	run_active = true
	
	# Set starting gold
	gold = division_config.get("starting_gold", 100)
	
	# Clear collections
	varsity_team.clear()
	jv_team.clear()
	deck.clear()
	jokers.clear()
	shop_inventory.clear()
	
	# Clear Runner objects (training resets on new run)
	runner_objects.clear()
	
	# Reset currency
	training_points = 0
	
	# Reset draft flag
	draft_completed = false
	
	# Give starting team based on tier (will be cleared if player goes through draft)
	_give_starting_team_for_division(division_config.get("starting_team_tier", "common"))
	
	# Apply special rules
	_apply_division_special_rules(division_config.get("special_rules", []))
	
	print("New run started: %s | Gold: %d | Antes: %d" % [
		division_config.get("name", "Unknown"), gold, max_ante
	])


func _give_starting_team_for_division(tier: String) -> void:
	# Clear existing team first
	varsity_team.clear()
	
	match tier:
		"basic":
			# Middle School: 5 Freshman Walk-ons (weakest team)
			_give_basic_team()
		"common":
			# High School: Balanced mix of common runners
			_give_common_team()
		"common+":
			# Junior College: Common team with 1 rare upgrade
			_give_common_plus_team()
		"rare":
			# D3: Mix of rare runners with good stats
			_give_rare_team()
		"rare+":
			# D2: Rare team with 1 epic upgrade
			_give_rare_plus_team()
		"epic":
			# D1 & Post Collegiate: Strong epic runners
			_give_epic_team()
		"legendary":
			# Professional & World Contender: Best starting team
			_give_legendary_team()
		_:
			# Fallback to common
			print("Unknown tier: ", tier, ", defaulting to common")
			_give_common_team()
	
	print("Starting team (tier: %s): %d varsity runners" % [tier, varsity_team.size()])
	_log_team_stats()

# Helper function to log team stats for debugging
func _log_team_stats() -> void:
	var total_speed = 0
	var total_power = 0
	var total_endurance = 0
	var total_stamina = 0
	
	for runner in varsity_team:
		var effect = get_item_effect(runner, "team")
		total_speed += effect.speed
		total_power += effect.power
		total_endurance += effect.endurance
		total_stamina += effect.stamina
	
	print("Team Stats - Speed: %d, Power: %d, Endurance: %d, Stamina: %d" % [
		total_speed, total_power, total_endurance, total_stamina
	])

func _give_basic_team() -> void:
	# 5 Freshman Walk-ons (5/5/5/5 each = 25/25/25/25 total)
	for i in range(5):
		add_varsity_runner("Runner: Freshman Walk-on")

func _give_common_team() -> void:
	# Use seed for deterministic but varied teams
	seed(seed)
	
	var team_variants = [
		# Variant 1: Balanced (default)
		[
			"Runner: Hill Specialist",
			"Runner: Steady State Runner",
			"Runner: Tempo Runner",
			"Runner: The Closer",
			"Runner: Freshman Walk-on"
		],
		# Variant 2: Speed-focused
		[
			"Runner: The Closer",
			"Runner: Tempo Runner",
			"Runner: Tempo Runner",
			"Runner: Hill Specialist",
			"Runner: Freshman Walk-on"
		],
		# Variant 3: Endurance-focused
		[
			"Runner: Steady State Runner",
			"Runner: Steady State Runner",
			"Runner: Tempo Runner",
			"Runner: Hill Specialist",
			"Runner: Freshman Walk-on"
		]
	]
	
	var selected_variant = team_variants[randi() % team_variants.size()]
	
	for runner in selected_variant:
		add_varsity_runner(runner)
	
	randomize()  # Restore global RNG

func _give_common_plus_team() -> void:
	# Common team but replace one with Track Tourist (rare)
	# Total stats: ~75-85 per stat
	var common_plus_runners = [
		"Runner: Track Tourist",         # Speed: 22, Power: -5 (rare upgrade)
		"Runner: Hill Specialist",       # Power: 15, Speed: 5
		"Runner: Steady State Runner",   # Endurance: 15, Stamina: 10
		"Runner: Tempo Runner",          # Endurance: 10, Speed: 10
		"Runner: The Closer"             # Speed: 15, Stamina: 5
	]
	
	for runner in common_plus_runners:
		add_varsity_runner(runner)

func _give_rare_team() -> void:
	# Mix of rare runners with strong stats
	# Total stats: ~90-100 per stat
	var rare_runners = [
		"Runner: Track Tourist",         # Speed: 22, Power: -5
		"Runner: Short-Cutter",          # Speed: 12, Endurance: 8
		"Runner: Hill Specialist",       # Power: 15, Speed: 5
		"Runner: Tempo Runner",          # Endurance: 10, Speed: 10
		"Runner: The Closer"             # Speed: 15, Stamina: 5
	]
	
	for runner in rare_runners:
		add_varsity_runner(runner)

func _give_rare_plus_team() -> void:
	# Rare team with 1 epic upgrade (Elite V-State Harrier)
	# Total stats: ~110-120 per stat
	var rare_plus_runners = [
		"Runner: Elite V-State Harrier", # Speed: 25, Power: 15 (epic)
		"Runner: Track Tourist",         # Speed: 22, Power: -5
		"Runner: Short-Cutter",          # Speed: 12, Endurance: 8
		"Runner: Tempo Runner",          # Endurance: 10, Speed: 10
		"Runner: The Closer"             # Speed: 15, Stamina: 5
	]
	
	for runner in rare_plus_runners:
		add_varsity_runner(runner)

func _give_epic_team() -> void:
	# Strong epic runners with diverse stat profiles
	# Total stats: ~130-150 per stat
	var epic_runners = [
		"Runner: Elite V-State Harrier", # Speed: 25, Power: 15
		"Runner: All-Terrain Captain",   # Speed: 18, Endurance: 18, Stamina: 15, Power: 12
		"Runner: Ghost of the Woods",    # Endurance: 20, Power: 12
		"Runner: Track Tourist",         # Speed: 22, Power: -5
		"Runner: The Closer"             # Speed: 15, Stamina: 5
	]
	
	for runner in epic_runners:
		add_varsity_runner(runner)

func _give_legendary_team() -> void:
	# Best starting team - all legendary/epic runners
	# Total stats: ~150-180 per stat
	var legendary_runners = [
		"Runner: The Legend",            # Speed: 30, Endurance: 30 (best runner)
		"Runner: Elite V-State Harrier", # Speed: 25, Power: 15
		"Runner: All-Terrain Captain",    # Speed: 18, Endurance: 18, Stamina: 15, Power: 12
		"Runner: Ghost of the Woods",     # Endurance: 20, Power: 12
		"Runner: JV Legend"               # Balanced: 10/10/10/10
	]
	
	for runner in legendary_runners:
		add_varsity_runner(runner)

func _apply_division_special_rules(special_rules: Array) -> void:
	# Reset all modifiers to defaults
	shop_price_multiplier = 1.0
	reward_multiplier_modifier = 1.0
	enable_contracts = false
	enable_sponsorships = false
	no_consolation_gold = false
	opponent_base_strength_multiplier = 1.0
	
	# Apply rules from the array
	for rule in special_rules:
		match rule:
			"limited_funding":
				# Post Collegiate: Shop costs 1.5x, rewards -20%
				shop_price_multiplier = 1.5
				reward_multiplier_modifier = 0.8
			"contracts":
				# Professional: Can sign contracts with runners
				enable_contracts = true
			"sponsorships":
				# Professional: Passive gold income
				enable_sponsorships = true
			"no_consolation":
				# World Contender: No gold on losses
				no_consolation_gold = true
			"elite_opponents":
				# World Contender: Opponents start stronger
				opponent_base_strength_multiplier = 1.2


func advance_ante():
	current_ante += 1
	# Check if we've reached max ante for this division
	if current_ante > max_ante:
		current_ante = max_ante
		print("Reached max ante for division: ", max_ante)
	
	# Update race type for new ante
	current_race_type = get_race_type_for_ante(current_ante)
	print("Advanced to ante ", current_ante, " Race Type: ", _get_race_type_name(current_race_type))
	
	# Check if we completed the division (unlock next one)
	if current_ante >= max_ante:
		_check_division_completion()

func _check_division_completion() -> void:
	# Find what division this one unlocks
	var next_unlock = get_next_unlock(current_division)
	if next_unlock != -1:
		unlock_division(next_unlock)
		var config = get_division_config(next_unlock)
		print("Completed division! Unlocked: ", config.get("name", "Unknown"))

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
	
	# Apply division reward multiplier
	var division_multiplier = division_config.get("reward_multiplier", 1.0)
	
	# Apply special rule reward modifier (e.g., limited_funding reduces rewards by 20%)
	var final_reward = base_reward * race_type_multiplier * division_multiplier * reward_multiplier_modifier
	
	return int(final_reward)

func calculate_consolation_reward() -> int:
	# Check if consolation gold is disabled by special rules
	if no_consolation_gold:
		return 0
	
	# Consolation reward for losing: 35% of win reward
	# This allows players to still progress even when losing
	var win_reward = calculate_race_reward()
	return max(5, int(win_reward * 0.35))  # Minimum 5 gold, even for early antes

# ============================================
# TRAINING POINTS SYSTEM
# ============================================

func earn_training_points(amount: int) -> void:
	training_points += amount
	print("Earned %d training points. Total: %d" % [amount, training_points])

func spend_training_points(amount: int) -> bool:
	if training_points >= amount:
		training_points -= amount
		print("Spent %d training points. Remaining: %d" % [amount, training_points])
		return true
	print("Not enough training points! Need %d, have %d" % [amount, training_points])
	return false

func get_training_points() -> int:
	return training_points

# Calculate training points awarded based on race performance
# Win: 5 points, Loss: 3 points, with bonuses for top placements
func calculate_training_points(race_result: Dictionary) -> int:
	var points = 0
	
	if race_result.get("won", false):
		# Base points for winning
		points = 5
		
		# Bonus for top placement
		var placement = race_result.get("player_placement", 999)
		if placement == 1:
			points += 2  # +2 bonus for 1st place
		elif placement <= 3:
			points += 1  # +1 bonus for top 3
	else:
		# Base points for losing (still get some points for participation)
		points = 3
		
		# Small bonus for good placement even on loss
		var placement = race_result.get("player_placement", 999)
		if placement <= 3:
			points += 1  # +1 bonus for top 3 even if lost
	
	return points


# Store Runner objects to persist training gains
var runner_objects: Dictionary = {}  # Maps runner_string -> Runner object

# Get or create Runner object for a runner string
func get_runner_object(runner_string: String) -> Runner:
	if not runner_objects.has(runner_string):
		# Create and store Runner object
		var runner = Runner.from_string(runner_string)
		runner_objects[runner_string] = runner
	return runner_objects[runner_string]

# Get item effect - returns a dictionary with stat bonuses
# For runners, now includes training gains if Runner object exists
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
			# Check if we have a Runner object with training gains
			if runner_objects.has(item_name):
				var runner = runner_objects[item_name]
				var effective_stats = runner.get_effective_stats()
				effect.speed = effective_stats.speed
				effect.endurance = effective_stats.endurance
				effect.stamina = effective_stats.stamina
				effect.power = effective_stats.power
				return effect
			
			# Otherwise, use base stats from runner type definition
			# Runners add base stats
			match base_name:
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

# Get runner growth potential - returns growth multipliers for training
func get_runner_growth_potential(runner_name: String) -> Dictionary:
	# Extract base name (remove prefix like "Runner: ", etc.)
	var base_name = runner_name
	if ":" in runner_name:
		base_name = runner_name.split(":")[1].strip_edges()
	
	# Default growth potential (1.0 = normal growth)
	var default_growth = {
		"speed": 1.0,
		"endurance": 1.0,
		"stamina": 1.0,
		"power": 1.0
	}
	
	# Look up growth potential from data
	if RUNNER_GROWTH_POTENTIAL.has(base_name):
		return RUNNER_GROWTH_POTENTIAL[base_name].duplicate()
	
	# Return default if not found
	return default_growth


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
# Delegates to RaceLogic for consistent calculations with updated variance and difficulty scaling
func calculate_runner_performance(runner_name: String, is_player: bool = true) -> float:
	return RaceLogic.calculate_runner_performance(runner_name, is_player)


# Generate a single opponent team
# Delegates to RaceLogic for opponent generation with calculated strength
func _generate_single_opponent_team(team_index: int = 0) -> Array[String]:
	return RaceLogic.generate_single_opponent_team(team_index)

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
	# Increment race counter to vary results between races at same ante
	race_counter += 1
	# Use seed for deterministic but varied race results
	# Add race_counter so each race at the same ante gets different results
	seed(seed + current_ante * 1000 + race_counter * 100)
	
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

# ============================================
# TESTING & VALIDATION
# ============================================

# Add to GameManager.gd for testing
func test_all_tiers() -> void:
	var tiers = ["basic", "common", "common+", "rare", "rare+", "epic", "legendary"]
	
	for tier in tiers:
		print("\n=== Testing Tier: %s ===" % tier)
		varsity_team.clear()
		_give_starting_team_for_division(tier)
		
		if varsity_team.size() != 5:
			print("ERROR: Team size is %d, expected 5!" % varsity_team.size())
