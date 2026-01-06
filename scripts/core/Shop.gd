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
			# Try to add to varsity first, then JV if varsity is full
			var team_size = GameManager.get_team_size()
			if team_size.varsity < 5:
				if GameManager.add_varsity_runner(item.name):
					added = true
					print("Added to varsity: ", item.name)
			elif team_size.jv < 2:
				if GameManager.add_jv_runner(item.name):
					added = true
					print("Added to JV: ", item.name)
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
	
	# Show purchase feedback
	_show_purchase_feedback("✓ Purchased: %s!" % item.name.split(":")[1] if ":" in item.name else item.name)
	
	# Update display (this will refresh gold and stats)
	_update_display()
	# Redisplay items (this will update button states based on new gold amount)
	_display_available_items()

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

func _on_continue_pressed() -> void:
	# Return to Run scene
	get_tree().change_scene_to_file("res://scenes/run/Run.tscn")
