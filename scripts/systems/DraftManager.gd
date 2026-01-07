class_name DraftManager
extends RefCounted

# Draft candidate generation system
# Generates runners with different tiers for the off-season draft

# Candidate pool configuration
const CANDIDATE_COUNT = 7  # Can be 7-10
const TIER_DISTRIBUTION = {
	"safe_pick": 3,
	"returner": 2,
	"walkon": 2,
	"special_talent": 2
}

# Runner pools by tier (for draft generation)
# These use the base runner names (without "Runner: " prefix)
const SAFE_PICK_POOL = [
	"Hill Specialist",
	"Steady State Runner",
	"Tempo Runner",
	"The Closer",
	"Track Tourist",
	"Short-Cutter"
]

const RETURNER_POOL = [
	"Steady State Runner",  # High endurance/stamina
	"Tempo Runner",         # Good endurance
	"All-Terrain Captain",  # Well-rounded with good endurance
	"Ghost of the Woods"     # High endurance
]

const WALKON_POOL = [
	"Freshman Walk-on",
	"Tempo Runner",
	"Hill Specialist",
	"The Closer"
]

const SPECIAL_TALENT_POOL = [
	"Freshman Walk-on",     # High growth potential
	"Tempo Runner",          # Good growth
	"Short-Cutter"          # Balanced growth
]

const OUTSTANDING_RECRUIT_POOL = [
	"Elite V-State Harrier",
	"All-Terrain Captain",
	"Ghost of the Woods",
	"Track Tourist",
	"The Legend"  # Very rare
]

# ============================================
# MAIN GENERATION FUNCTION
# ============================================

# Generate draft candidates based on division
static func generate_candidates(division: GameManager.Division, seed_value: int = 0) -> Array[Runner]:
	var candidates: Array[Runner] = []
	
	# Use seed for deterministic generation
	if seed_value > 0:
		seed(seed_value)
	
	# Determine if outstanding recruits are available (D1, D2, D3)
	var can_have_outstanding = division in [
		GameManager.Division.D1,
		GameManager.Division.D2,
		GameManager.Division.D3
	]
	
	# Chance for outstanding recruit (10% for D1/D2/D3)
	var has_outstanding = false
	if can_have_outstanding and randf() < 0.10:
		has_outstanding = true
		var outstanding = _generate_outstanding_recruit(division)
		candidates.append(outstanding)
	
	# Generate tier-based candidates
	var tier_counts = TIER_DISTRIBUTION.duplicate()
	
	# Adjust counts if we have an outstanding recruit
	if has_outstanding:
		# Reduce one safe pick to make room
		tier_counts["safe_pick"] = max(1, tier_counts["safe_pick"] - 1)
	
	# Generate Safe Picks
	for i in range(tier_counts["safe_pick"]):
		var candidate = _generate_safe_pick(division)
		candidates.append(candidate)
	
	# Generate Returners
	for i in range(tier_counts["returner"]):
		var candidate = _generate_returner(division)
		candidates.append(candidate)
	
	# Generate Walk-ons
	for i in range(tier_counts["walkon"]):
		var candidate = _generate_walkon(division)
		candidates.append(candidate)
	
	# Generate Special Talents
	for i in range(tier_counts["special_talent"]):
		var candidate = _generate_special_talent(division)
		candidates.append(candidate)
	
	# Shuffle candidates for random order
	candidates.shuffle()
	
	# Restore global RNG
	randomize()
	
	return candidates

# ============================================
# TIER-SPECIFIC GENERATION
# ============================================

# Generate a Safe Pick (race-ready, guaranteed performance)
static func _generate_safe_pick(division: GameManager.Division) -> Runner:
	var pool = SAFE_PICK_POOL.duplicate()
	var runner_name = pool[randi() % pool.size()]
	
	# Create runner
	var runner = Runner.new(runner_name)
	runner.draft_tier = "safe_pick"
	
	# Update growth potential now that draft_tier is set
	runner.update_growth_potential_for_draft_tier()
	
	# Safe picks get slight stat boost (they're race-ready)
	_apply_stat_boost(runner, 1.1)  # +10% to all stats
	
	return runner

# Generate a Returner (high Endurance/Stamina)
static func _generate_returner(division: GameManager.Division) -> Runner:
	var pool = RETURNER_POOL.duplicate()
	var runner_name = pool[randi() % pool.size()]
	
	var runner = Runner.new(runner_name)
	runner.draft_tier = "returner"
	
	# Update growth potential now that draft_tier is set
	runner.update_growth_potential_for_draft_tier()
	
	# Returners get boost to endurance/stamina specifically
	runner.base_stats.endurance = int(runner.base_stats.endurance * 1.3)
	runner.base_stats.stamina = int(runner.base_stats.stamina * 1.3)
	runner.current_stats = runner.base_stats.duplicate()
	
	return runner

# Generate a Walk-on (balanced, average potential)
static func _generate_walkon(division: GameManager.Division) -> Runner:
	var pool = WALKON_POOL.duplicate()
	var runner_name = pool[randi() % pool.size()]
	
	var runner = Runner.new(runner_name)
	runner.draft_tier = "walkon"
	
	# Update growth potential now that draft_tier is set
	runner.update_growth_potential_for_draft_tier()
	
	# Walk-ons are as-is (balanced, no modifications)
	return runner

# Generate a Special Talent (low stats, high growth)
static func _generate_special_talent(division: GameManager.Division) -> Runner:
	var pool = SPECIAL_TALENT_POOL.duplicate()
	var runner_name = pool[randi() % pool.size()]
	
	var runner = Runner.new(runner_name)
	runner.draft_tier = "special_talent"
	
	# Update growth potential now that draft_tier is set
	runner.update_growth_potential_for_draft_tier()
	
	# Special talents start with reduced stats (they'll grow)
	_apply_stat_reduction(runner, 0.75)  # 25% reduction
	
	return runner

# Generate an Outstanding Recruit (D1/D2/D3 only - dominates)
static func _generate_outstanding_recruit(division: GameManager.Division) -> Runner:
	var pool = OUTSTANDING_RECRUIT_POOL.duplicate()
	var runner_name = pool[randi() % pool.size()]
	
	var runner = Runner.new(runner_name)
	runner.draft_tier = "outstanding_recruit"
	runner.is_outstanding_recruit = true
	
	# Update growth potential now that draft_tier is set
	runner.update_growth_potential_for_draft_tier()
	
	# Outstanding recruits get significant stat boost
	_apply_stat_boost(runner, 1.4)  # +40% to all stats
	
	# They also get a small random bonus (5-15 points total)
	var bonus_points = randi_range(5, 15)
	var stats = ["speed", "endurance", "stamina", "power"]
	for i in range(bonus_points):
		var stat = stats[randi() % stats.size()]
		runner.base_stats[stat] += 1
		runner.current_stats[stat] += 1
	
	return runner

# ============================================
# STAT MODIFICATION HELPERS
# ============================================

# Apply stat boost multiplier to a runner
static func _apply_stat_boost(runner: Runner, multiplier: float) -> void:
	runner.base_stats.speed = int(runner.base_stats.speed * multiplier)
	runner.base_stats.endurance = int(runner.base_stats.endurance * multiplier)
	runner.base_stats.stamina = int(runner.base_stats.stamina * multiplier)
	runner.base_stats.power = int(runner.base_stats.power * multiplier)
	runner.current_stats = runner.base_stats.duplicate()

# Apply stat reduction multiplier to a runner
static func _apply_stat_reduction(runner: Runner, multiplier: float) -> void:
	runner.base_stats.speed = max(1, int(runner.base_stats.speed * multiplier))
	runner.base_stats.endurance = max(1, int(runner.base_stats.endurance * multiplier))
	runner.base_stats.stamina = max(1, int(runner.base_stats.stamina * multiplier))
	runner.base_stats.power = max(1, int(runner.base_stats.power * multiplier))
	runner.current_stats = runner.base_stats.duplicate()

# ============================================
# UTILITY FUNCTIONS
# ============================================

# Get tier display name
static func get_tier_display_name(tier: String) -> String:
	match tier:
		"safe_pick":
			return "Safe Pick"
		"returner":
			return "Returner"
		"walkon":
			return "Walk-on"
		"special_talent":
			return "Special Talent"
		"outstanding_recruit":
			return "⭐ Outstanding Recruit"
		_:
			return "Unknown"

# Get tier description
static func get_tier_description(tier: String) -> String:
	match tier:
		"safe_pick":
			return "Race-ready runner with guaranteed performance. Lower growth potential."
		"returner":
			return "High endurance and stamina. Good for long races. Moderate growth."
		"walkon":
			return "Balanced runner with average potential. Reliable choice."
		"special_talent":
			return "Low starting stats but extremely high growth potential. Long-term investment."
		"outstanding_recruit":
			return "Elite recruit that dominates. High stats and good growth. Rare!"
		_:
			return ""

# Get tier color (for UI)
static func get_tier_color(tier: String) -> Color:
	match tier:
		"safe_pick":
			return Color(0.4, 0.8, 0.4)  # Green
		"returner":
			return Color(0.4, 0.6, 0.9)  # Blue
		"walkon":
			return Color(0.7, 0.7, 0.7)  # Gray
		"special_talent":
			return Color(0.9, 0.7, 0.2)  # Gold
		"outstanding_recruit":
			return Color(1.0, 0.8, 0.0)  # Bright gold
		_:
			return Color.WHITE

