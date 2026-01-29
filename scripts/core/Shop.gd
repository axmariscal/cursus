extends Control

# Item rarity enum
enum ItemRarity {
	COMMON,
	RARE,
	EPIC
}

# Simple item data structure
class Item:
	var name: String
	var category: String  # "team", "deck", "boosts", "equipment"
	var price: int        # Gold cost
	var rarity: ItemRarity = ItemRarity.COMMON
	
	func _init(item_name: String, item_category: String, item_price: int = 0, item_rarity: ItemRarity = ItemRarity.COMMON):
		name = item_name
		category = item_category
		price = item_price
		rarity = item_rarity

@onready var ante_label: Label = %AnteLabel
@onready var gold_label: Label = %GoldLabel
@onready var speed_label: Label = %SpeedLabel
@onready var endurance_label: Label = %EnduranceLabel
@onready var stamina_label: Label = %StaminaLabel
@onready var power_label: Label = %PowerLabel
@onready var team_count_label: Label = %TeamCountLabel
@onready var deck_count_label: Label = %DeckCountLabel
@onready var boosts_count_label: Label = %BoostsCountLabel
@onready var equipment_count_label: Label = %EquipmentCountLabel
@onready var team_container: VBoxContainer = %TeamItemsContainer
@onready var deck_container: VBoxContainer = %DeckItemsContainer
@onready var boosts_container: VBoxContainer = %BoostsItemsContainer
@onready var equipment_container: VBoxContainer = %EquipmentItemsContainer
@onready var continue_button: Button = %ContinueButton
@onready var purchase_feedback_label: Label = %PurchaseFeedbackLabel

# Training section UI (will be created dynamically)
var training_section: VBoxContainer = null
var training_points_label: Label = null
var training_runners_container: VBoxContainer = null
var training_workouts_container: HFlowContainer = null
var selected_training_runner: Runner = null
var training_feedback_label: Label = null

var available_items: Array[Item] = []

# Simple item pools for each category
# Common Runners (Ante 1+)
var team_items = [
	"Hill Specialist",
	"Steady State Runner",
	"Tempo Runner",
	"The Closer",
	"Freshman Walk-on",
	"Track Tourist",
	"Short-Cutter"
]

var deck_items = ["Speed Boost", "Stamina Card", "Recovery Card", "Pace Card", "Finish Strong"]
var boost_items = ["Endurance", "Speed", "Recovery", "Pace", "Stamina"]
var equipment_items = ["Lightweight Shoes", "Energy Gel", "Training Program", "Recovery Kit", "Performance Monitor"]

# Rare item pools (appear less frequently)
# Rare Runners (Ante 5+)
var rare_team_items = [
	"Elite V-State Harrier",
	"All-Terrain Captain",
	"Caffeine Fiend",
	"Ghost of the Woods"
]

# Epic Runners (Ante 5+, very rare)
var epic_team_items = [
	"The Legend",
	"JV Legend"
]
var rare_deck_items = ["Power Surge", "Final Sprint", "Victory Lap"]
var rare_boost_items = ["Elite Training", "Peak Performance", "Champion's Edge"]
var rare_equipment_items = ["Pro Racing Shoes", "Elite Training Kit", "Championship Gear"]

# Item limits
const MAX_DECK = 10
const MAX_BOOSTS = 5
const MAX_EQUIPMENT = 15

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	_update_display()
	_generate_available_items()
	# Wait for frame to ensure UI is fully ready before displaying items
	await get_tree().process_frame
	_display_available_items()
	_setup_training_section()
	
	# Hide purchase feedback initially
	purchase_feedback_label.visible = false

func _update_display() -> void:
	ante_label.text = "Ante: %d" % GameManager.current_ante
	gold_label.text = "💰 Gold: %d" % GameManager.get_gold()
	# Style gold label to make it more prominent
	gold_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))  # Gold color
	
	# Update stats
	speed_label.text = "Speed: %d" % GameManager.get_total_speed()
	endurance_label.text = "Endurance: %d" % GameManager.get_total_endurance()
	stamina_label.text = "Stamina: %d" % GameManager.get_total_stamina()
	power_label.text = "Power: %d" % GameManager.get_total_power()
	
	# Update inventory counts with limits
	var team_size = GameManager.get_team_size()
	team_count_label.text = "Team: %d Varsity, %d JV" % [team_size.varsity, team_size.jv]
	
	# Show limits and highlight if full
	var deck_count = GameManager.deck.size()
	var deck_text = "Deck: %d / %d" % [deck_count, MAX_DECK]
	if deck_count >= MAX_DECK:
		deck_text += " [FULL]"
	deck_count_label.text = deck_text
	
	var boosts_count = GameManager.jokers.size()
	var boosts_text = "Boosts: %d / %d" % [boosts_count, MAX_BOOSTS]
	if boosts_count >= MAX_BOOSTS:
		boosts_text += " [FULL]"
	boosts_count_label.text = boosts_text
	
	var equipment_count = GameManager.shop_inventory.size()
	var equipment_text = "Equipment: %d / %d" % [equipment_count, MAX_EQUIPMENT]
	if equipment_count >= MAX_EQUIPMENT:
		equipment_text += " [FULL]"
	equipment_count_label.text = equipment_text

func _get_item_price(category: String, base_name: String, rarity: ItemRarity = ItemRarity.COMMON) -> int:
	# Base prices by category
	var base_price = 0
	match category:
		"team":
			base_price = 40  # Runners are expensive
			# Special runners cost more
			if base_name in ["The Closer", "Tempo Runner", "Track Tourist"]:
				base_price = 50
			# Freshman Walk-on is cheaper (balanced stats but low cost)
			if base_name == "Freshman Walk-on":
				base_price = 30
		"deck":
			base_price = 20  # Cards are moderate
		"boosts":
			base_price = 50  # Boosts are expensive (powerful)
		"equipment":
			base_price = 30  # Equipment is moderate
	
	# Apply rarity multiplier
	match rarity:
		ItemRarity.RARE:
			base_price = int(base_price * 1.5)  # 50% more expensive
		ItemRarity.EPIC:
			base_price = int(base_price * 2.0)  # 100% more expensive (double)
		_:
			pass  # Common stays the same
	
	# Scale price with ante (later antes = slightly more expensive)
	var ante_modifier = 1.0 + (GameManager.current_ante * 0.05)  # 5% increase per ante
	var final_price = int(base_price * ante_modifier)
	
	# Apply division special rules (e.g., limited_funding makes shop 1.5x more expensive)
	final_price = int(final_price * GameManager.shop_price_multiplier)
	
	return final_price

func _get_item_rarity(category: String, base_name: String) -> ItemRarity:
	# Determine if item is rare or epic
	var roll = randf()
	
	# Check if it's an epic item by name (from epic item pools)
	var is_epic_item = false
	match category:
		"team":
			is_epic_item = base_name in epic_team_items
	
	if is_epic_item:
		# Epic items are always Epic
		return ItemRarity.EPIC
	
	# Check if it's a rare item by name (from rare item pools)
	var is_rare_item = false
	match category:
		"team":
			is_rare_item = base_name in rare_team_items
		"deck":
			is_rare_item = base_name in rare_deck_items
		"boosts":
			is_rare_item = base_name in rare_boost_items
		"equipment":
			is_rare_item = base_name in rare_equipment_items
	
	if is_rare_item:
		# Rare items from pools: 10% chance to be Epic, 90% Rare
		if roll < 0.10:
			return ItemRarity.EPIC
		else:
			return ItemRarity.RARE
	
	# Common items can rarely become Rare (3% chance) or Epic (1% chance)
	if roll < 0.01:
		return ItemRarity.EPIC
	elif roll < 0.04:
		return ItemRarity.RARE
	
	return ItemRarity.COMMON

func _generate_available_items() -> void:
	available_items.clear()
	
	# Use seed for deterministic generation
	seed(GameManager.seed + GameManager.current_ante * 1000)
	
	# Generate 2-3 items per category based on ante level
	var items_per_category = 2 + (GameManager.current_ante / 5)
	
	# Team items (include rare items from ante 5+, epic items from ante 8+)
	var all_team_items = team_items.duplicate()
	if GameManager.current_ante >= 5:
		all_team_items.append_array(rare_team_items)
	if GameManager.current_ante >= 8:
		all_team_items.append_array(epic_team_items)
	
	var used_team_indices = []
	for i in range(min(items_per_category, all_team_items.size())):
		var index = randi() % all_team_items.size()
		# Avoid duplicates in same shop
		while used_team_indices.has(index):
			index = randi() % all_team_items.size()
		used_team_indices.append(index)
		var item_name = all_team_items[index]
		var rarity = _get_item_rarity("team", item_name)
		var price = _get_item_price("team", item_name, rarity)
		available_items.append(Item.new("Runner: " + item_name, "team", price, rarity))
	
	# Deck items (include rare items from ante 7+)
	var all_deck_items = deck_items.duplicate()
	if GameManager.current_ante >= 7:
		all_deck_items.append_array(rare_deck_items)
	
	var used_deck_indices = []
	for i in range(min(items_per_category, all_deck_items.size())):
		var index = randi() % all_deck_items.size()
		while used_deck_indices.has(index):
			index = randi() % all_deck_items.size()
		used_deck_indices.append(index)
		var item_name = all_deck_items[index]
		var rarity = _get_item_rarity("deck", item_name)
		var price = _get_item_price("deck", item_name, rarity)
		available_items.append(Item.new("Card: " + item_name, "deck", price, rarity))
	
	# Boost items (rarer, appear from ante 3+, include rare from ante 8+)
	if GameManager.current_ante >= 3:
		var all_boost_items = boost_items.duplicate()
		if GameManager.current_ante >= 8:
			all_boost_items.append_array(rare_boost_items)
		var index = randi() % all_boost_items.size()
		var item_name = all_boost_items[index]
		var rarity = _get_item_rarity("boosts", item_name)
		var price = _get_item_price("boosts", item_name, rarity)
		available_items.append(Item.new("Boost: " + item_name, "boosts", price, rarity))
	
	# Equipment items (include rare items from ante 6+)
	var all_equipment_items = equipment_items.duplicate()
	if GameManager.current_ante >= 6:
		all_equipment_items.append_array(rare_equipment_items)
	
	var used_equipment_indices = []
	for i in range(min(items_per_category, all_equipment_items.size())):
		var index = randi() % all_equipment_items.size()
		while used_equipment_indices.has(index):
			index = randi() % all_equipment_items.size()
		used_equipment_indices.append(index)
		var item_name = all_equipment_items[index]
		var rarity = _get_item_rarity("equipment", item_name)
		var price = _get_item_price("equipment", item_name, rarity)
		available_items.append(Item.new("Equipment: " + item_name, "equipment", price, rarity))
	
	# Restore global RNG state
	randomize()

func _display_available_items() -> void:
	# Clear existing item buttons
	_clear_containers()
	
	# Group items by category
	var team_items_list: Array[Item] = []
	var deck_items_list: Array[Item] = []
	var boosts_items_list: Array[Item] = []
	var equipment_items_list: Array[Item] = []
	
	for item in available_items:
		match item.category:
			"team":
				team_items_list.append(item)
			"deck":
				deck_items_list.append(item)
			"boosts":
				boosts_items_list.append(item)
			"equipment":
				equipment_items_list.append(item)
	
	# Display items in their respective containers
	_display_items_in_container(team_container, team_items_list)
	_display_items_in_container(deck_container, deck_items_list)
	_display_items_in_container(boosts_container, boosts_items_list)
	_display_items_in_container(equipment_container, equipment_items_list)

func _check_inventory_limit(category: String) -> bool:
	# Check if inventory is full for this category
	match category:
		"deck":
			return GameManager.deck.size() >= MAX_DECK
		"boosts":
			return GameManager.jokers.size() >= MAX_BOOSTS
		"equipment":
			return GameManager.shop_inventory.size() >= MAX_EQUIPMENT
		"team":
			var team_size = GameManager.get_team_size()
			return (team_size.varsity >= 5 and team_size.jv >= 2)
	return false

func _get_rarity_name(rarity: ItemRarity) -> String:
	match rarity:
		ItemRarity.COMMON:
			return "Common"
		ItemRarity.RARE:
			return "Rare"
		ItemRarity.EPIC:
			return "Epic"
	return "Unknown"

func _get_rarity_color(rarity: ItemRarity) -> Color:
	match rarity:
		ItemRarity.COMMON:
			return Color(0.8, 0.8, 0.8)  # Gray
		ItemRarity.RARE:
			return Color(0.2, 0.6, 1.0)  # Blue
		ItemRarity.EPIC:
			return Color(0.9, 0.5, 0.1)  # Orange/Gold
	return Color.WHITE

func _get_card_texture(item_name: String, category: String) -> Texture2D:
	# Extract base name (remove prefix like "Runner: ", "Card: ", etc.)
	var base_name = item_name
	if ":" in item_name:
		base_name = item_name.split(":")[1].strip_edges()
	
	# Convert name to file path format (lowercase, spaces to underscores)
	var file_name = base_name.to_lower().replace(" ", "_")
	
	# Handle special cases for file names that don't match exactly
	var file_name_map = {
		"freshman_walk-on": "walkon_rnr",  # Handle the actual file name
		"the_closer": "closer",  # In case it's named differently
		"track_tourist": "track_tourist",
		"short-cutter": "short_cutter",
	}
	
	if file_name_map.has(file_name):
		file_name = file_name_map[file_name]
	
	# Build path based on category
	var image_path = ""
	match category:
		"team":
			image_path = "res://assets/art/cards/runners/%s.png" % file_name
		"deck":
			image_path = "res://assets/art/cards/deck/%s.png" % file_name
		"boosts":
			image_path = "res://assets/art/cards/boosts/%s.png" % file_name
		"equipment":
			image_path = "res://assets/art/cards/equipment/%s.png" % file_name
	
	# Try to load the texture
	if ResourceLoader.exists(image_path):
		return load(image_path) as Texture2D
	
	# Return null if image doesn't exist (will just show button without image)
	return null

func _display_items_in_container(container: VBoxContainer, items: Array[Item]) -> void:
	for item in items:
		# Create a container for the card image and button
		var item_container = VBoxContainer.new()
		item_container.custom_minimum_size = Vector2(200, 350)
		item_container.add_theme_constant_override("separation", 5)
		
		# Try to load card image
		var card_texture = _get_card_texture(item.name, item.category)
		if card_texture:
			var texture_rect = TextureRect.new()
			texture_rect.texture = card_texture
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			texture_rect.custom_minimum_size = Vector2(180, 250)
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			item_container.add_child(texture_rect)
		else:
			# If no image, add a placeholder or just show the button
			pass
		
		var button = Button.new()
		
		# Get item effect to display
		var effect = GameManager.get_item_effect(item.name, item.category)
		var effect_text = _format_effect_text(effect)
		
		# Check if player can afford
		var can_afford = GameManager.get_gold() >= item.price
		# Check if inventory is full
		var inventory_full = _check_inventory_limit(item.category)
		
		var price_text = "%d Gold" % item.price
		var rarity_text = "[%s]" % _get_rarity_name(item.rarity)
		
		if not can_afford:
			price_text = "[Not Enough Gold] " + price_text
		if inventory_full:
			price_text = "[Inventory Full] " + price_text
		
		# Simplify button text if we have an image
		if card_texture:
			button.text = rarity_text + "\n" + effect_text + "\n" + price_text + "\n(Select)"
		else:
			button.text = item.name + "\n" + rarity_text + "\n" + effect_text + "\n" + price_text + "\n(Select)"
		
		button.pressed.connect(_on_item_selected.bind(item))
		
		# Disable button if can't afford or inventory is full
		button.disabled = not can_afford or inventory_full
		
		# Style buttons based on category and rarity for visual distinction
		_style_item_button(button, item.category, can_afford and not inventory_full, item.rarity)
		
		item_container.add_child(button)
		container.add_child(item_container)

func _style_item_button(button: Button, category: String, can_afford: bool = true, rarity: ItemRarity = ItemRarity.COMMON) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.corner_radius_top_left = 5
	style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_right = 5
	style_normal.corner_radius_bottom_left = 5
	
	var style_hover = StyleBoxFlat.new()
	style_hover.corner_radius_top_left = 5
	style_hover.corner_radius_top_right = 5
	style_hover.corner_radius_bottom_right = 5
	style_hover.corner_radius_bottom_left = 5
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.corner_radius_top_left = 5
	style_pressed.corner_radius_top_right = 5
	style_pressed.corner_radius_bottom_right = 5
	style_pressed.corner_radius_bottom_left = 5
	
	var style_disabled = StyleBoxFlat.new()
	style_disabled.corner_radius_top_left = 5
	style_disabled.corner_radius_top_right = 5
	style_disabled.corner_radius_bottom_right = 5
	style_disabled.corner_radius_bottom_left = 5
	
	# Base colors by category
	var base_color = Color.WHITE
	match category:
		"team":
			base_color = Color(0.3, 0.5, 0.8)  # Blue
		"deck":
			base_color = Color(0.4, 0.7, 0.4)  # Green
		"boosts":
			base_color = Color(0.7, 0.4, 0.8)  # Purple
		"equipment":
			base_color = Color(0.9, 0.6, 0.3)  # Orange
	
	# Adjust color based on rarity
	match rarity:
		ItemRarity.RARE:
			base_color = base_color.lerp(Color(0.2, 0.6, 1.0), 0.3)  # Blend with blue
		ItemRarity.EPIC:
			base_color = base_color.lerp(Color(0.9, 0.5, 0.1), 0.4)  # Blend with gold/orange
		_:
			pass  # Common stays base color
	
	# Apply colors
	style_normal.bg_color = Color(base_color.r, base_color.g, base_color.b, 0.7)
	style_hover.bg_color = Color(base_color.r, base_color.g, base_color.b, 0.9)
	style_pressed.bg_color = Color(base_color.r * 0.8, base_color.g * 0.8, base_color.b * 0.8, 0.9)
	style_disabled.bg_color = Color(0.2, 0.2, 0.2, 0.5)  # Dark gray when disabled
	
	# Set font color based on rarity
	var font_color = _get_rarity_color(rarity)
	button.add_theme_color_override("font_color", font_color)
	if not can_afford:
		button.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6, 1))
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("disabled", style_disabled)


func _format_effect_text(effect: Dictionary) -> String:
	var parts: Array[String] = []
	
	if effect.speed > 0:
		parts.append("+%d Speed" % effect.speed)
	if effect.endurance > 0:
		parts.append("+%d Endurance" % effect.endurance)
	if effect.stamina > 0:
		parts.append("+%d Stamina" % effect.stamina)
	if effect.power > 0:
		parts.append("+%d Power" % effect.power)
	if effect.multiplier > 1.0:
		var percent = int((effect.multiplier - 1.0) * 100)
		parts.append("+%d%% Multiplier" % percent)
	
	if parts.is_empty():
		return "No effect"
	
	return ", ".join(parts)

func _clear_containers() -> void:
	for child in team_container.get_children():
		child.queue_free()
	for child in deck_container.get_children():
		child.queue_free()
	for child in boosts_container.get_children():
		child.queue_free()
	for child in equipment_container.get_children():
		child.queue_free()

func _on_item_selected(item: Item) -> void:
	# Check if player can afford the item
	if GameManager.get_gold() < item.price:
		print("Not enough gold! Need %d, have %d" % [item.price, GameManager.get_gold()])
		return
	
	# Check inventory limits
	if _check_inventory_limit(item.category):
		print("Inventory full for category: ", item.category)
		return
	
	# Spend gold
	if not GameManager.spend_gold(item.price):
		print("Failed to purchase item: ", item.name)
		return
	
	# Add item to appropriate GameManager array
	var added = false
	match item.category:
		"team":
			# Extract runner name from "Runner: Name" format
			var runner_name = item.name.split(":")[1].strip_edges() if ":" in item.name else item.name
			
			# Check if we already have this runner type in registry
			# (This prevents losing training history if you buy same runner twice)
			var existing_runner = null
			for runner in GameManager.varsity_team:
				if runner.name == runner_name:
					existing_runner = runner
					break
			if existing_runner == null:
				for runner in GameManager.jv_team:
					if runner.name == runner_name:
						existing_runner = runner
						break
			
			# If runner already exists on team, don't allow duplicate purchase
			if existing_runner != null:
				print("Runner %s is already on your team! Cannot purchase duplicate." % existing_runner.display_name)
				# Refund gold
				GameManager.earn_gold(item.price)
				return
			
			# Create new runner (no existing runner found)
			var runner = Runner.from_string(item.name)
			GameManager.register_runner(runner)
			print("Created new runner: %s" % runner.display_name)
			
			# Try to add to varsity first, then JV if varsity is full
			var team_size = GameManager.get_team_size()
			if team_size.varsity < 5:
				if GameManager.add_varsity_runner(runner):
					added = true
					print("Added to varsity: %s" % runner.display_name)
			elif team_size.jv < 2:
				if GameManager.add_jv_runner(runner):
					added = true
					print("Added to JV: %s" % runner.display_name)
			else:
				print("Team is full! Cannot add more runners.")
				# Refund gold if we couldn't add
				GameManager.earn_gold(item.price)
				return
		"deck":
			if GameManager.deck.size() < MAX_DECK:
				GameManager.deck.append(item.name)
				added = true
				print("Added to deck: ", item.name)
			else:
				print("Deck is full! Max %d cards." % MAX_DECK)
				GameManager.earn_gold(item.price)
				return
		"boosts":
			if GameManager.jokers.size() < MAX_BOOSTS:
				GameManager.jokers.append(item.name)
				added = true
				print("Added boost: ", item.name)
			else:
				print("Boosts are full! Max %d boosts." % MAX_BOOSTS)
				GameManager.earn_gold(item.price)
				return
		"equipment":
			if GameManager.shop_inventory.size() < MAX_EQUIPMENT:
				GameManager.shop_inventory.append(item.name)
				added = true
				print("Added equipment: ", item.name)
			else:
				print("Equipment is full! Max %d equipment." % MAX_EQUIPMENT)
				GameManager.earn_gold(item.price)
				return
	
	if not added:
		# Refund if we couldn't add for some reason
		GameManager.earn_gold(item.price)
		return
	
	# Remove item from available items by finding matching name and category
	for i in range(available_items.size()):
		if available_items[i].name == item.name and available_items[i].category == item.category:
			available_items.remove_at(i)
			break
	
	# Get win probability BEFORE purchase for debugging
	var win_prob_before = RaceLogic.calculate_win_probability_monte_carlo()
	var team_stats_before = _get_team_stats_summary()
	
	# Show purchase feedback
	_show_purchase_feedback("✓ Purchased: %s!" % item.name.split(":")[1] if ":" in item.name else item.name)
	
	# Update display (this will refresh gold and stats)
	_update_display()
	# Redisplay items (this will update button states based on new gold amount)
	_display_available_items()
	# Update training section if it exists
	if training_section != null:
		_update_training_display()
	
	# Get win probability AFTER purchase for debugging
	var win_prob_after = RaceLogic.calculate_win_probability_monte_carlo()
	var team_stats_after = _get_team_stats_summary()
	
	# Log shop item impact
	_log_shop_item_impact(item, win_prob_before, win_prob_after, team_stats_before, team_stats_after)

func _get_team_stats_summary() -> Dictionary:
	# Calculate total team stats for debugging
	var total_speed = 0
	var total_endurance = 0
	var total_stamina = 0
	var total_power = 0
	
	for runner in GameManager.varsity_team:
		# Use get_item_effect to see what race calculations actually use
		var effect = GameManager.get_item_effect(runner, "team")
		total_speed += effect.speed
		total_endurance += effect.endurance
		total_stamina += effect.stamina
		total_power += effect.power
	
	return {
		"speed": total_speed,
		"endurance": total_endurance,
		"stamina": total_stamina,
		"power": total_power,
		"total": total_speed + total_endurance + total_stamina + total_power
	}

func _log_shop_item_impact(item: Item, win_prob_before: float, win_prob_after: float,
		team_stats_before: Dictionary, team_stats_after: Dictionary) -> void:
	
	var separator = "============================================================"
	print("\n" + separator)
	print("[SHOP ITEM IMPACT DEBUG]")
	print(separator)
	
	var item_name = item.name
	if ":" in item.name:
		item_name = item.name.split(":")[1].strip_edges()
	
	print("Item: %s (%s)" % [item_name, item.category])
	print("Price: %d Gold" % item.price)
	print("")
	
	# Get item effect
	var effect = GameManager.get_item_effect(item.name, item.category)
	var stat_gain = effect.speed + effect.endurance + effect.stamina + effect.power
	
	print("ITEM STAT BONUS:")
	print("  Speed:    +%d" % effect.speed)
	print("  Endurance: +%d" % effect.endurance)
	print("  Stamina:   +%d" % effect.stamina)
	print("  Power:     +%d" % effect.power)
	print("  Total:     +%d stats" % stat_gain)
	print("")
	
	# Team stat changes
	print("TEAM STAT CHANGES (Varsity Total):")
	print("  Speed:    %d → %d (%+d)" % [team_stats_before.speed, team_stats_after.speed, team_stats_after.speed - team_stats_before.speed])
	print("  Endurance: %d → %d (%+d)" % [team_stats_before.endurance, team_stats_after.endurance, team_stats_after.endurance - team_stats_before.endurance])
	print("  Stamina:   %d → %d (%+d)" % [team_stats_before.stamina, team_stats_after.stamina, team_stats_after.stamina - team_stats_before.stamina])
	print("  Power:     %d → %d (%+d)" % [team_stats_before.power, team_stats_after.power, team_stats_after.power - team_stats_before.power])
	print("  Total:     %d → %d (%+d)" % [team_stats_before.total, team_stats_after.total, team_stats_after.total - team_stats_before.total])
	print("")
	
	# Win probability changes
	var win_prob_change = win_prob_after - win_prob_before
	var win_prob_change_pct = 0.0
	if win_prob_before > 0:
		win_prob_change_pct = (win_prob_change / win_prob_before) * 100.0
	
	print("WIN PROBABILITY IMPACT:")
	print("  Before: %.2f%%" % win_prob_before)
	print("  After:  %.2f%%" % win_prob_after)
	print("  Change: %+.2f%% (%+.2f%%)" % [win_prob_change, win_prob_change_pct])
	print("")
	
	# Explain why shop items are more effective
	print("WHY SHOP ITEMS ARE MORE EFFECTIVE THAN TRAINING:")
	if item.category == "equipment" or item.category == "deck":
		var runners_affected = GameManager.varsity_team.size()
		var effective_stat_gain = stat_gain * runners_affected
		print("  ✓ Applies to ALL %d runners = +%d effective stats" % [runners_affected, effective_stat_gain])
		print("  ✓ Training only affects 1 runner = +%d stats" % stat_gain)
		print("  ✓ Shop items are %.1fx more effective per purchase!" % (float(effective_stat_gain) / stat_gain))
	else:
		print("  ✓ %s items provide team-wide bonuses" % item.category)
		print("  ✓ Training only affects individual runners")
	print("")
	
	# Opponent scaling
	var player_avg_strength_before = _calculate_avg_team_strength(team_stats_before)
	var player_avg_strength_after = _calculate_avg_team_strength(team_stats_after)
	var ante = GameManager.current_ante
	var difficulty_multiplier = 1.0 + (pow(ante, 1.1) * 0.20)
	var base_target_ratio = 1.10
	var target_ratio = base_target_ratio - (ante * 0.03)
	target_ratio = max(target_ratio, 0.85)
	
	var opponent_target_before = player_avg_strength_before * target_ratio
	var opponent_target_after = player_avg_strength_after * target_ratio
	
	print("OPPONENT SCALING:")
	print("  Player Avg Strength: %.2f → %.2f" % [player_avg_strength_before, player_avg_strength_after])
	print("  Opponent Target:      %.2f → %.2f" % [opponent_target_before, opponent_target_after])
	print("  Difficulty Multiplier (Ante %d): %.2fx" % [ante, difficulty_multiplier])
	print("")
	print("  Note: Opponents ONLY scale with ante (not with player strength),")
	print("        so shop items give you a real advantage!")
	
	print(separator)
	print("")

func _calculate_avg_team_strength(team_stats: Dictionary) -> float:
	# Calculate average team strength using the same formula as RaceLogic
	var speed_score = team_stats.speed * 0.4
	var power_score = team_stats.power * 0.3
	var endurance_score = team_stats.endurance * 0.2
	var stamina_score = team_stats.stamina * 0.1
	var raw_stat_total = speed_score + power_score + endurance_score + stamina_score
	var base_strength = 15.0 / (1.0 + raw_stat_total / 10.0)
	return base_strength

func _show_purchase_feedback(message: String) -> void:
	purchase_feedback_label.text = message
	purchase_feedback_label.visible = true
	purchase_feedback_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	
	# Animate fade in/out
	var tween = create_tween()
	tween.tween_property(purchase_feedback_label, "modulate:a", 1.0, 0.2)
	await get_tree().create_timer(1.5).timeout
	tween = create_tween()
	tween.tween_property(purchase_feedback_label, "modulate:a", 0.0, 0.3)
	await tween.finished
	purchase_feedback_label.visible = false
	purchase_feedback_label.modulate.a = 1.0

func _setup_training_section() -> void:
	# Create Training section after Equipment section
	var main_container = equipment_container.get_parent().get_parent()  # VBoxContainer
	var equipment_section = equipment_container.get_parent()  # EquipmentSection
	
	# Create Training section
	training_section = VBoxContainer.new()
	training_section.name = "TrainingSection"
	
	# Training header
	var training_header = Label.new()
	training_header.text = "--- TRAINING ---"
	training_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	training_section.add_child(training_header)
	
	# Training points label
	training_points_label = Label.new()
	training_points_label.name = "TrainingPointsLabel"
	training_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	training_points_label.add_theme_font_size_override("font_size", 24)
	training_section.add_child(training_points_label)
	
	# Selected runner label
	var selected_runner_label = Label.new()
	selected_runner_label.name = "SelectedRunnerLabel"
	selected_runner_label.text = "Selected: None"
	selected_runner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	training_section.add_child(selected_runner_label)
	
	# Runners container
	var runners_label = Label.new()
	runners_label.text = "Select Runner:"
	runners_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	training_section.add_child(runners_label)
	
	training_runners_container = VBoxContainer.new()
	training_runners_container.name = "TrainingRunnersContainer"
	training_section.add_child(training_runners_container)
	
	# Workouts container
	var workouts_label = Label.new()
	workouts_label.text = "Select Workout:"
	workouts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	training_section.add_child(workouts_label)
	
	training_workouts_container = HFlowContainer.new()
	training_workouts_container.name = "TrainingWorkoutsContainer"
	training_section.add_child(training_workouts_container)
	
	# Training feedback label
	training_feedback_label = Label.new()
	training_feedback_label.name = "TrainingFeedbackLabel"
	training_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	training_feedback_label.visible = false
	training_section.add_child(training_feedback_label)
	
	# Insert Training section after Equipment section
	var equipment_index = main_container.get_children().find(equipment_section)
	if equipment_index >= 0:
		main_container.add_child(training_section)
		main_container.move_child(training_section, equipment_index + 1)
	
	# Update training display
	_update_training_display()

func _update_training_display() -> void:
	if training_points_label == null:
		return
	
	var points = GameManager.get_training_points()
	training_points_label.text = "🏋️ Training Points: %d" % points
	training_points_label.add_theme_color_override("font_color", Color(0.3, 0.7, 0.9))
	
	# Display runners
	_display_training_runners()
	
	# Display workouts
	_display_training_workouts()

func _display_training_runners() -> void:
	if training_runners_container == null:
		return
	
	# Clear existing
	for child in training_runners_container.get_children():
		child.queue_free()
	
	# Display varsity runners
	var varsity_header = Label.new()
	varsity_header.text = "VARSITY:"
	varsity_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	training_runners_container.add_child(varsity_header)
	
	for runner in GameManager.varsity_team:
		_create_training_runner_button(runner, true)
	
	# Display JV runners if any
	if GameManager.jv_team.size() > 0:
		var jv_header = Label.new()
		jv_header.text = "JV:"
		jv_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		jv_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		training_runners_container.add_child(jv_header)
		
		for runner in GameManager.jv_team:
			_create_training_runner_button(runner, false)

func _create_training_runner_button(runner: Runner, is_varsity: bool) -> void:
	var button = Button.new()
	var stats = runner.get_display_stats()
	var injury_status = runner.get_injury_status()
	
	var button_text = runner.name
	if is_varsity:
		button_text = "⭐ " + button_text
	
	button_text += "\nSpd:%d End:%d Sta:%d Pow:%d" % [
		stats.current.speed, stats.current.endurance,
		stats.current.stamina, stats.current.power
	]
	
	if injury_status.is_injured:
		button_text += "\n⚠️ Injured (%.0f%%)" % injury_status.meter
	else:
		button_text += "\n✓ Healthy"
	
	button.text = button_text
	button.custom_minimum_size = Vector2(180, 100)
	
	# Style button
	var style_normal = StyleBoxFlat.new()
	style_normal.corner_radius_top_left = 5
	style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_right = 5
	style_normal.corner_radius_bottom_left = 5
	
	var base_color = Color(0.3, 0.5, 0.8) if is_varsity else Color(0.5, 0.5, 0.5)
	if selected_training_runner != null and selected_training_runner.get_id() == runner.get_id():
		base_color = Color(0.5, 0.8, 0.5)  # Highlight selected
	
	style_normal.bg_color = Color(base_color.r, base_color.g, base_color.b, 0.7)
	button.add_theme_stylebox_override("normal", style_normal)
	
	button.pressed.connect(_on_training_runner_selected.bind(runner))
	training_runners_container.add_child(button)

func _display_training_workouts() -> void:
	if training_workouts_container == null:
		return
	
	# Clear existing
	for child in training_workouts_container.get_children():
		child.queue_free()
	
	# Use same workout types as Training.gd
	var workout_types = {
		"speed": {"name": "Speed", "cost": 1, "description": "+Speed", "cost_type": "tp"},
		"endurance": {"name": "Endurance", "cost": 1, "description": "+Endurance", "cost_type": "tp"},
		"stamina": {"name": "Stamina", "cost": 1, "description": "+Stamina", "cost_type": "tp"},
		"power": {"name": "Power", "cost": 1, "description": "+Power", "cost_type": "tp"},
		"balanced": {"name": "Balanced", "cost": 1, "description": "+All", "cost_type": "tp"},
		"recovery": {"name": "Recovery", "cost": 1, "description": "Heal (1 TP)", "cost_type": "tp"},
		"recovery_gold": {"name": "Medical", "cost": 25, "description": "Heal (25 Gold)", "cost_type": "gold"},
		"recovery_premium": {"name": "Premium", "cost": 2, "description": "Major Heal (2 TP)", "cost_type": "tp"},
		"intensive": {"name": "Intensive", "cost": 2, "description": "High gain", "cost_type": "tp"}
	}
	
	for workout_type in workout_types.keys():
		var workout_data = workout_types[workout_type]
		_create_training_workout_button(workout_type, workout_data)

func _create_training_workout_button(workout_type: String, workout_data: Dictionary) -> void:
	var button = Button.new()
	var cost_type = workout_data.get("cost_type", "tp")
	var cost_text = ""
	if cost_type == "tp":
		cost_text = "%d TP" % workout_data.cost
	elif cost_type == "gold":
		cost_text = "%d Gold" % workout_data.cost
	
	button.text = workout_data.name + "\nCost: %s\n%s" % [cost_text, workout_data.description]
	button.custom_minimum_size = Vector2(120, 80)
	button.set_meta("workout_type", workout_type)
	
	# Style button
	var style_normal = StyleBoxFlat.new()
	style_normal.corner_radius_top_left = 5
	style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_right = 5
	style_normal.corner_radius_bottom_left = 5
	
	var base_color = Color(0.4, 0.7, 0.4)
	match workout_type:
		"speed":
			base_color = Color(0.9, 0.3, 0.3)
		"endurance":
			base_color = Color(0.3, 0.6, 0.9)
		"stamina":
			base_color = Color(0.9, 0.6, 0.3)
		"power":
			base_color = Color(0.7, 0.3, 0.9)
		"balanced":
			base_color = Color(0.5, 0.5, 0.5)
		"recovery":
			base_color = Color(0.3, 0.8, 0.5)
		"recovery_gold":
			base_color = Color(0.5, 0.8, 0.6)  # Slightly different green
		"recovery_premium":
			base_color = Color(0.2, 0.9, 0.7)  # Bright green
		"intensive":
			base_color = Color(0.9, 0.5, 0.1)
	
	style_normal.bg_color = Color(base_color.r, base_color.g, base_color.b, 0.7)
	button.add_theme_stylebox_override("normal", style_normal)
	
	# Disable if no runner selected or can't afford
	var can_afford = false
	if cost_type == "tp":
		can_afford = GameManager.get_training_points() >= workout_data.cost
	elif cost_type == "gold":
		can_afford = GameManager.get_gold() >= workout_data.cost
	
	button.disabled = selected_training_runner == null or not can_afford
	
	button.pressed.connect(_on_training_workout_selected.bind(workout_type))
	training_workouts_container.add_child(button)

func _on_training_runner_selected(runner: Runner) -> void:
	selected_training_runner = runner
	_update_training_display()
	
	# Update selected runner label
	if training_section != null:
		var selected_label = training_section.get_node_or_null("SelectedRunnerLabel")
		if selected_label != null:
			selected_label.text = "Selected: %s" % runner.name

func _on_training_workout_selected(workout_type: String) -> void:
	if selected_training_runner == null:
		_show_training_feedback("⚠️ Please select a runner first!", false)
		return
	
	# Workout types matching Training.gd
	var workout_types = {
		"speed": {"name": "Speed Training", "cost": 1, "base_gain": 5},
		"endurance": {"name": "Endurance Training", "cost": 1, "base_gain": 5},
		"stamina": {"name": "Stamina Training", "cost": 1, "base_gain": 5},
		"power": {"name": "Power Training", "cost": 1, "base_gain": 5},
		"balanced": {"name": "Balanced Training", "cost": 1, "base_gain": 3},
		"recovery": {"name": "Recovery Session", "cost": 1, "base_gain": 0},
		"intensive": {"name": "Intensive Training", "cost": 2, "base_gain": 8}
	}
	
	var workout_data = workout_types.get(workout_type, {})
	if workout_data.is_empty():
		_show_training_feedback("⚠️ Unknown workout type!", false)
		return
	
	var cost_type = workout_data.get("cost_type", "tp")
	var cost = workout_data.get("cost", 1)
	
	# Check affordability based on cost type
	if cost_type == "tp":
		if GameManager.get_training_points() < cost:
			_show_training_feedback("⚠️ Not enough training points! Need %d" % cost, false)
			return
	elif cost_type == "gold":
		if GameManager.get_gold() < cost:
			_show_training_feedback("⚠️ Not enough gold! Need %d" % cost, false)
			return
	
	# Apply training
	var base_gain = workout_data.get("base_gain", 2)
	var gains = selected_training_runner.apply_training(workout_type, base_gain)
	
	# Spend cost based on type
	if cost_type == "tp":
		GameManager.spend_training_points(cost)
	elif cost_type == "gold":
		GameManager.spend_gold(cost)
	
	# Show feedback
	var feedback_text = "✓ Training complete! "
	if workout_type == "recovery":
		var injury_status = selected_training_runner.get_injury_status()
		feedback_text += "Recovered injury. Current: %.1f%%" % injury_status.meter
	else:
		var gain_parts: Array[String] = []
		if gains.speed > 0:
			gain_parts.append("+%d Speed" % gains.speed)
		if gains.endurance > 0:
			gain_parts.append("+%d Endurance" % gains.endurance)
		if gains.stamina > 0:
			gain_parts.append("+%d Stamina" % gains.stamina)
		if gains.power > 0:
			gain_parts.append("+%d Power" % gains.power)
		
		if not gain_parts.is_empty():
			feedback_text += "Gains: " + ", ".join(gain_parts)
	
	_show_training_feedback(feedback_text, true)
	
	# Update displays
	_update_display()
	_update_training_display()

func _show_training_feedback(message: String, is_success: bool) -> void:
	if training_feedback_label == null:
		return
	
	training_feedback_label.text = message
	training_feedback_label.visible = true
	
	if is_success:
		training_feedback_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	else:
		training_feedback_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	
	# Auto-hide after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if training_feedback_label != null:
		training_feedback_label.visible = false

func _on_continue_pressed() -> void:
	# Return to Run scene (draft is handled before shop in Run.gd)
	get_tree().change_scene_to_file("res://scenes/run/Run.tscn")
