# Shop/Practice System Implementation

Add a shop/practice phase that appears after completing races, allowing players to upgrade their team, deck, jokers, and equipment before the next race.

## Overview

After completing a race and advancing the ante, players should be taken to a Shop/Practice scene where they can:
- **Team** - Add/upgrade runners/athletes
- **Deck** - Add/upgrade race event cards  
- **Jokers** - Add permanent runner modifiers
- **Equipment/Training** - Boost capabilities

This completes the core game loop: **Race → Shop → Race → Shop...**

## Changes

### 1. Create Shop Scene (`scenes/core/ShopScene.tscn`)
- Replace the placeholder ShopScene with a proper UI
- Add sections for each category (Team, Deck, Jokers, Equipment)
- Display current inventory for each category
- Add purchase/selection buttons for available items
- Add "Continue to Next Race" button to return to Run scene
- Keep it text-based for the prototype

### 2. Create Shop Script (`scripts/core/Shop.gd`)
- Handle item display and purchase logic
- Generate available items based on current ante (scaling difficulty)
- Add purchased items to appropriate GameManager arrays:
  - `GameManager.team` for runners
  - `GameManager.deck` for cards
  - `GameManager.jokers` for modifiers
  - `GameManager.shop_inventory` for equipment/training
- Display current inventory counts
- Handle "Continue" button to transition back to Run scene

### 3. Integrate Shop into Race Flow (`scripts/run/Run.gd`)
- After completing a race, automatically transition to Shop scene
- Or add a "Go to Shop" button after race completion
- Shop should appear before starting the next race

### 4. Enhance GameManager (if needed)
- Add currency/resource system for purchasing (if needed)
- Or make shop selections free for now (text-based prototype)
- Add helper functions to manage inventory arrays

## Implementation Details

- Start with simple text-based items (e.g., "Runner: Sprinter", "Card: Speed Boost", "Joker: Endurance")
- Items can be represented as dictionaries or simple strings for now
- Shop inventory can be randomly generated or fixed for prototype
- After purchasing, items are added to GameManager arrays
- Display shows what you currently own before showing new options
- Keep it simple - focus on establishing the loop, not complex mechanics

## Game Flow

1. Player completes race → Ante advances
2. **NEW:** Transition to Shop scene
3. Player views available items and current inventory
4. Player purchases/selects items (adds to GameManager arrays)
5. Player clicks "Continue to Next Race"
6. Return to Run scene → Start next race

## To-dos

- [ ] Create Shop scene UI with categories and inventory display
- [ ] Create Shop.gd script with purchase logic
- [ ] Add item generation system (simple for now)
- [ ] Integrate shop transition into race completion flow
- [ ] Add inventory display showing current team/deck/jokers
- [ ] Test complete loop: Race → Shop → Race

