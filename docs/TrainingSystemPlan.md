# Phase 3: Training Cycle System - Implementation Plan

## Overview

Implement a hybrid training system that combines training points (earned from races) with a training phase between races. This gives players strategic control over athlete development while complementing the existing shop system.

## Recommended Hybrid Approach

**Training Phase System:**
1. After each race, players enter a Training Phase (before or after shop)
2. Players receive Training Points based on race performance:
   - Win: 5 points
   - Loss: 3 points
   - Bonus points for top placements
3. Each runner can train 1-2 times per phase (limited by energy/stamina)
4. Training options:
   - Speed/Endurance/Stamina/Power (1 point each)
   - Balanced (1 point, smaller gains)
   - Recovery (1 point, reduces injury)
   - Intensive Training (2 points, higher gains, higher injury risk)
5. Training facilities (purchased in shop):
   - Basic: Standard training
   - Upgraded: +20% effectiveness in specific areas
   - Recovery Center: Faster injury recovery

## Implementation Breakdown

### 1. Core Training Points System

**Location:** `scripts/core/GameManager.gd`

**Changes:**
- Add `training_points: int = 0` variable
- Add `earn_training_points(amount: int)` method
- Add `spend_training_points(amount: int) -> bool` method
- Add `get_training_points() -> int` method
- Integrate into `complete_race()` flow:
  ```gdscript
  # In RunState.complete_race() or GameManager.simulate_race()
  if race_result.won:
      GameManager.earn_training_points(5)
      # Bonus for top 3 placement
      if race_result.player_placement <= 3:
          GameManager.earn_training_points(1)
  else:
      GameManager.earn_training_points(3)
  ```

### 2. Training Scene

**New File:** `scenes/core/TrainingScene.tscn`
**New Script:** `scripts/core/Training.gd`

**UI Layout:**
- Header: Training Points display, Ante, Gold
- Runner Selection Panel: List of all runners (varsity + JV) with:
  - Runner name and stats
  - Training sessions used this phase (0/2)
  - Injury status
  - Current energy (if implemented)
- Workout Selection Panel: Buttons for each workout type:
  - Speed Training (1 point)
  - Endurance Training (1 point)
  - Stamina Training (1 point)
  - Power Training (1 point)
  - Balanced Training (1 point)
  - Recovery Session (1 point)
  - Intensive Training (2 points)
- Training History Panel: Show recent training for selected runner
- Continue Button: Return to Run scene or proceed to Shop

**Script Logic:**
- Track training sessions per runner (max 2 per phase)
- Validate training point costs
- Apply training using `Runner.apply_training()`
- Show stat gains feedback
- Update injury meters
- Reset training sessions counter at start of new phase

### 3. Runner Training Enhancements

**Location:** `scripts/runners/Runner.gd`

**Enhance `apply_training()` method:**
- Add support for "recovery" workout type (reduces injury meter)
- Add support for "intensive" workout type (higher gains, higher injury risk)
- Calculate injury risk based on workout type:
  - Basic workouts: +1-3 injury meter
  - Intensive: +3-6 injury meter
  - Recovery: -5-10 injury meter
- Apply facility bonuses if owned:
  - Weight Room: +20% power gains
  - Endurance Course: +20% endurance gains
  - Elite Facility: +10% all gains

**Add training session tracking:**
- `training_sessions_this_phase: int = 0`
- `max_training_per_phase: int = 2`
- `can_train() -> bool` method

### 4. Game Flow Integration

**Location:** `scripts/run/Run.gd`

**Changes:**
- After race completion, add "Go to Training" button (or auto-navigate)
- Update `_on_continue_to_shop_pressed()` to route through training:
  ```gdscript
  # Option 1: Race → Training → Shop → Run
  # Option 2: Race → Shop → Training → Run
  # Option 3: Race → Training → Run (skip shop if desired)
  ```
- Add training phase state tracking
- Reset training sessions counter when entering new phase

### 5. Training Facilities (Optional - Phase 1)

**Location:** `scripts/core/GameManager.gd`

**Add facility tracking:**
- `owned_facilities: Array[String] = []`
- Facility types:
  - "basic_track" (unlocked by default)
  - "weight_room" (cost: 100 gold, +20% power)
  - "endurance_course" (cost: 100 gold, +20% endurance)
  - "recovery_center" (cost: 150 gold, faster recovery)
  - "elite_facility" (cost: 300 gold, +10% all)

**Integration:**
- Purchase facilities in Shop (new category)
- Check facility ownership when applying training
- Apply bonuses in `Runner.apply_training()`

### 6. Training Energy System (Optional - Phase 2)

**Location:** `scripts/runners/Runner.gd`

**Add energy tracking:**
- `training_energy: int = 100` (max 100)
- Energy costs:
  - Light workout: 20 energy
  - Moderate workout: 40 energy
  - Intensive workout: 60 energy
- Energy recovery: +20 per phase, +50 on rest days
- Prevent training if energy < cost

**UI Updates:**
- Display energy bar in Training scene
- Show energy cost for each workout
- Disable workouts if insufficient energy

### 7. Team Management Integration

**Location:** `scripts/core/TeamManagement.gd`

**Display training information:**
- Training history per runner
- Total training sessions
- Training gains (current stats - base stats)
- Injury status and meter
- Training sessions used this phase

## Implementation Order

### Phase 1: Core System (Essential)
1. ✅ Add training points to GameManager
2. ✅ Create TrainingScene.tscn and Training.gd
3. ✅ Enhance Runner.apply_training() for all workout types
4. ✅ Integrate training phase into game flow
5. ✅ Add training limits (1-2 sessions per runner per phase)
6. ✅ Test basic training flow

### Phase 2: Facilities (Enhancement)
7. Add facility system to GameManager
8. Add facility purchase in Shop
9. Apply facility bonuses in training
10. Test facility bonuses

### Phase 3: Energy System (Optional)
11. Add energy tracking to Runner
12. Add energy costs to workouts
13. Add energy display to Training UI
14. Test energy system

### Phase 4: Polish
15. Update Team Management UI with training info
16. Add training history display
17. Balance stat gains and costs
18. Add visual feedback for training gains
19. Test complete system

## Technical Details

### Training Point Calculation
```gdscript
func calculate_training_points(race_result: Dictionary) -> int:
    var points = 0
    if race_result.won:
        points = 5
        # Bonus for top placement
        if race_result.player_placement == 1:
            points += 2
        elif race_result.player_placement <= 3:
            points += 1
    else:
        points = 3
        # Small bonus for good placement even on loss
        if race_result.player_placement <= 3:
            points += 1
    return points
```

### Workout Type Definitions
```gdscript
const WORKOUT_TYPES = {
    "speed": {"cost": 1, "base_gain": 2, "injury_risk": 1.0},
    "endurance": {"cost": 1, "base_gain": 2, "injury_risk": 1.0},
    "stamina": {"cost": 1, "base_gain": 2, "injury_risk": 1.0},
    "power": {"cost": 1, "base_gain": 2, "injury_risk": 1.0},
    "balanced": {"cost": 1, "base_gain": 1.5, "injury_risk": 0.8},
    "recovery": {"cost": 1, "base_gain": 0, "injury_recovery": 5.0},
    "intensive": {"cost": 2, "base_gain": 3, "injury_risk": 2.0}
}
```

### Training Session Tracking
```gdscript
# In Runner.gd
var training_sessions_this_phase: int = 0
const MAX_TRAINING_PER_PHASE: int = 2

func can_train() -> bool:
    return training_sessions_this_phase < MAX_TRAINING_PER_PHASE

func reset_training_sessions() -> void:
    training_sessions_this_phase = 0
```

## Integration Points

1. **Race Completion** → Award training points
2. **Run Scene** → Add "Go to Training" button after race
3. **Training Scene** → Apply training, track sessions
4. **Shop Scene** → Optionally purchase facilities
5. **Team Management** → Display training history and gains
6. **Runner Class** → Handle training application and limits

## Benefits

✅ Gives strategic control over athlete development
✅ Complements the money-based shop system
✅ Creates meaningful choices (train vs. rest, specialize vs. balance)
✅ Adds depth without overwhelming complexity
✅ Works with the existing injury system
✅ Allows long-term team building strategies

## Testing Checklist

- [ ] Training points awarded correctly after races
- [ ] All workout types function correctly
- [ ] Training limits enforced (1-2 per runner)
- [ ] Injury system integrates properly
- [ ] Stat gains are balanced
- [ ] UI flow works smoothly (Race → Training → Shop → Run)
- [ ] Training history displays correctly
- [ ] Facilities apply bonuses correctly (if implemented)
- [ ] Energy system prevents over-training (if implemented)

