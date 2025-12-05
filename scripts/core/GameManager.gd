extends Node

# High-level game/run state manager
# This persists the entire run, similar to Balatro's RunManager

var current_ante := 1
var max_ante := 20

var team = []            # your runners
var deck = []            # race event cards
var jokers = []          # permanent runner modifiers
var shop_inventory = []  # practice/shop selections

var seed = 0             # run RNG seed
var run_active := false

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
	team.clear()
	deck.clear()
	jokers.clear()
	shop_inventory.clear()
	print("New run started with seed: ", seed)


func advance_ante():
	current_ante += 1
	print("Advanced to ante ", current_ante)


# Get item effect - returns a dictionary with stat bonuses
func get_item_effect(item_name: String, category: String) -> Dictionary:
	var effect = {
		"speed": 0,
		"endurance": 0,
		"stamina": 0,
		"power": 0,
		"multiplier": 1.0  # For jokers
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
		
		"jokers":
			# Jokers provide multipliers or special effects
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


# Calculate total stats from all items
func get_total_speed() -> int:
	var total = base_speed
	
	# Add team bonuses
	for runner in team:
		var effect = get_item_effect(runner, "team")
		total += effect.speed
	
	# Add equipment bonuses
	for equipment in shop_inventory:
		var effect = get_item_effect(equipment, "equipment")
		total += effect.speed
	
	# Apply joker multipliers
	var multiplier = 1.0
	for joker in jokers:
		var effect = get_item_effect(joker, "jokers")
		if effect.multiplier > 1.0:
			multiplier *= effect.multiplier
		total += effect.speed
	
	return int(total * multiplier)


func get_total_endurance() -> int:
	var total = base_endurance
	
	for runner in team:
		var effect = get_item_effect(runner, "team")
		total += effect.endurance
	
	for equipment in shop_inventory:
		var effect = get_item_effect(equipment, "equipment")
		total += effect.endurance
	
	var multiplier = 1.0
	for joker in jokers:
		var effect = get_item_effect(joker, "jokers")
		if effect.multiplier > 1.0:
			multiplier *= effect.multiplier
		total += effect.endurance
	
	return int(total * multiplier)


func get_total_stamina() -> int:
	var total = base_stamina
	
	for runner in team:
		var effect = get_item_effect(runner, "team")
		total += effect.stamina
	
	for equipment in shop_inventory:
		var effect = get_item_effect(equipment, "equipment")
		total += effect.stamina
	
	for joker in jokers:
		var effect = get_item_effect(joker, "jokers")
		total += effect.stamina
	
	return total


func get_total_power() -> int:
	var total = base_power
	
	for runner in team:
		var effect = get_item_effect(runner, "team")
		total += effect.power
	
	for equipment in shop_inventory:
		var effect = get_item_effect(equipment, "equipment")
		total += effect.power
	
	return total
