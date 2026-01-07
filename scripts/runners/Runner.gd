class_name Runner
extends RefCounted

# Runner class - represents a runner with stats, growth, injuries, and training history

# Basic properties
var name: String
var display_name: String  # Full display name like "Runner: Hill Specialist"
var draft_tier: String = ""  # "safe_pick", "returner", "walkon", "special_talent", "outstanding_recruit"

# Base stats (from runner type definition)
var base_stats: Dictionary = {
	"speed": 0,
	"endurance": 0,
	"stamina": 0,
	"power": 0
}

# Current stats (base + training gains - injury debuffs)
var current_stats: Dictionary = {
	"speed": 0,
	"endurance": 0,
	"stamina": 0,
	"power": 0
}

# Growth potential (multipliers for training gains)
# Higher values = more stat gain per training session
var growth_potential: Dictionary = {
	"speed": 1.0,
	"endurance": 1.0,
	"stamina": 1.0,
	"power": 1.0
}

# Injury system
var injury_meter: float = 0.0  # 0.0-100.0
var injury_debuffs: Dictionary = {}  # Active injury effects
var is_injured: bool = false

# Training history
var training_history: Array = []  # Array of completed workout types
var total_training_sessions: int = 0

# Team assignment
var is_varsity: bool = false
var team_index: int = -1  # Index in varsity_team or jv_team array

# Outstanding recruit flag (for D1/D2/D3)
var is_outstanding_recruit: bool = false

# ============================================
# CONSTRUCTOR
# ============================================

func _init(runner_name: String = "", runner_display_name: String = ""):
	name = runner_name
	display_name = runner_display_name if runner_display_name != "" else "Runner: " + runner_name
	
	# Initialize stats from GameManager's get_item_effect
	if runner_name != "":
		_load_stats_from_name(runner_name)
	
	# Start with current_stats equal to base_stats
	current_stats = base_stats.duplicate()

# ============================================
# STAT LOADING
# ============================================

func _load_stats_from_name(runner_name: String) -> void:
	# Get base stats from GameManager's existing system
	var effect = GameManager.get_item_effect("Runner: " + runner_name, "team")
	base_stats.speed = effect.get("speed", 0)
	base_stats.endurance = effect.get("endurance", 0)
	base_stats.stamina = effect.get("stamina", 0)
	base_stats.power = effect.get("power", 0)
	
	# Set growth potential based on runner type
	_set_growth_potential(runner_name)

func _set_growth_potential(runner_name: String) -> void:
	# Get base growth potential from runner type definition
	var base_growth = GameManager.get_runner_growth_potential(runner_name)
	growth_potential = base_growth.duplicate()
	
	# Apply draft tier modifiers on top of base growth
	# This allows draft tier to enhance or reduce the inherent growth potential
	match draft_tier:
		"special_talent":
			# Special talents get 2x multiplier on top of base growth
			# This makes them extremely high growth if they have good base growth
			growth_potential.speed *= 2.0
			growth_potential.endurance *= 2.0
			growth_potential.stamina *= 2.0
			growth_potential.power *= 2.0
		"outstanding_recruit":
			# Outstanding recruits get 1.5x multiplier (high base stats + good growth)
			growth_potential.speed *= 1.5
			growth_potential.endurance *= 1.5
			growth_potential.stamina *= 1.5
			growth_potential.power *= 1.5
		"returner":
			# Returners get bonus to endurance/stamina growth specifically
			growth_potential.endurance *= 1.4
			growth_potential.stamina *= 1.4
			# Other stats get slight boost
			growth_potential.speed *= 1.1
			growth_potential.power *= 1.1
		"walkon":
			# Walk-ons get moderate boost (1.2x)
			growth_potential.speed *= 1.2
			growth_potential.endurance *= 1.2
			growth_potential.stamina *= 1.2
			growth_potential.power *= 1.2
		"safe_pick", _:
			# Safe picks use base growth as-is (no modifier)
			# They're already race-ready, so no bonus growth needed
			pass

# ============================================
# STAT GETTERS
# ============================================

# Get current effective stats (for race calculations)
func get_effective_stats() -> Dictionary:
	var stats = current_stats.duplicate()
	
	# Apply injury debuffs
	if is_injured:
		var debuff_multiplier = _get_injury_debuff_multiplier()
		stats.speed = int(stats.speed * debuff_multiplier)
		stats.endurance = int(stats.endurance * debuff_multiplier)
		stats.stamina = int(stats.stamina * debuff_multiplier)
		stats.power = int(stats.power * debuff_multiplier)
	
	return stats

# Get stats in the format expected by existing get_item_effect system
# This allows backward compatibility
func get_item_effect_dict() -> Dictionary:
	var effective = get_effective_stats()
	return {
		"speed": effective.speed,
		"endurance": effective.endurance,
		"stamina": effective.stamina,
		"power": effective.power,
		"multiplier": 1.0
	}

# Get display stats (for UI)
func get_display_stats() -> Dictionary:
	return {
		"base": base_stats.duplicate(),
		"current": current_stats.duplicate(),
		"effective": get_effective_stats(),
		"growth": growth_potential.duplicate(),
		"training_gains": {
			"speed": current_stats.speed - base_stats.speed,
			"endurance": current_stats.endurance - base_stats.endurance,
			"stamina": current_stats.stamina - base_stats.stamina,
			"power": current_stats.power - base_stats.power
		}
	}

# ============================================
# TRAINING SYSTEM
# ============================================

# Apply training workout to this runner
func apply_training(workout_type: String, base_gain: int = 2) -> Dictionary:
	# Calculate stat gain based on workout type and growth potential
	var gains = {
		"speed": 0,
		"endurance": 0,
		"stamina": 0,
		"power": 0
	}
	
	match workout_type:
		"speed":
			gains.speed = int(base_gain * growth_potential.speed)
		"endurance":
			gains.endurance = int(base_gain * growth_potential.endurance)
		"stamina":
			gains.stamina = int(base_gain * growth_potential.stamina)
		"power":
			gains.power = int(base_gain * growth_potential.power)
		"balanced":
			# Balanced workout gives smaller gains to all stats
			var balanced_gain = int(base_gain * 0.75)
			gains.speed = int(balanced_gain * growth_potential.speed)
			gains.endurance = int(balanced_gain * growth_potential.endurance)
			gains.stamina = int(balanced_gain * growth_potential.stamina)
			gains.power = int(balanced_gain * growth_potential.power)
	
	# Apply gains to current stats
	current_stats.speed += gains.speed
	current_stats.endurance += gains.endurance
	current_stats.stamina += gains.stamina
	current_stats.power += gains.power
	
	# Record training
	training_history.append({
		"type": workout_type,
		"gains": gains.duplicate(),
		"session": total_training_sessions + 1
	})
	total_training_sessions += 1
	
	# Training increases injury risk slightly
	_increase_injury_meter(1.0 + (randf() * 2.0))  # 1-3 points per training
	
	return gains

# ============================================
# INJURY SYSTEM
# ============================================

func _get_injury_debuff_multiplier() -> float:
	# Calculate debuff based on injury meter level
	if injury_meter < 30.0:
		return 1.0  # No debuff
	elif injury_meter < 60.0:
		return 0.9  # -10% stats
	elif injury_meter < 80.0:
		return 0.75  # -25% stats
	else:
		return 0.5  # -50% stats (severe injury)

func _increase_injury_meter(amount: float) -> void:
	injury_meter = min(injury_meter + amount, 100.0)
	
	# Update injury status
	var was_injured = is_injured
	is_injured = injury_meter >= 30.0
	
	# Update debuffs
	if is_injured and not was_injured:
		_update_injury_debuffs()

func _update_injury_debuffs() -> void:
	# Set debuff effects based on injury level
	var multiplier = _get_injury_debuff_multiplier()
	injury_debuffs = {
		"multiplier": multiplier,
		"severity": _get_injury_severity()
	}

func _get_injury_severity() -> String:
	if injury_meter < 30.0:
		return "none"
	elif injury_meter < 60.0:
		return "minor"
	elif injury_meter < 80.0:
		return "moderate"
	else:
		return "severe"

# Recover from injury (rest or treatment)
func recover(amount: float) -> void:
	injury_meter = max(injury_meter - amount, 0.0)
	
	# Update injury status
	if injury_meter < 30.0:
		is_injured = false
		injury_debuffs.clear()
	else:
		_update_injury_debuffs()

# Get injury status for display
func get_injury_status() -> Dictionary:
	return {
		"meter": injury_meter,
		"is_injured": is_injured,
		"severity": _get_injury_severity(),
		"debuff_multiplier": _get_injury_debuff_multiplier()
	}

# ============================================
# UTILITY METHODS
# ============================================

# Create a Runner from an existing runner name string (for migration)
static func from_string(runner_string: String) -> Runner:
	var runner_name = runner_string
	if ":" in runner_string:
		runner_name = runner_string.split(":")[1].strip_edges()
	
	var runner = Runner.new(runner_name, runner_string)
	return runner

# Get total stat value (for sorting/comparison)
func get_total_stats() -> int:
	var effective = get_effective_stats()
	return effective.speed + effective.endurance + effective.stamina + effective.power

# Get growth potential score (for draft display)
func get_growth_score() -> float:
	return (growth_potential.speed + growth_potential.endurance + 
			growth_potential.stamina + growth_potential.power) / 4.0

# Check if runner is ready for varsity (meets minimum stat requirements)
func is_race_ready(min_total_stats: int = 50) -> bool:
	return get_total_stats() >= min_total_stats

# Convert to string (for debugging/saving)
func to_string() -> String:
	return "%s (Stats: %d/%d/%d/%d, Injury: %.1f%%)" % [
		display_name,
		current_stats.speed,
		current_stats.endurance,
		current_stats.stamina,
		current_stats.power,
		injury_meter
	]

