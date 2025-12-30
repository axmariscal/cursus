extends Control

# Simple item data structure
class Item:
	var name: String
	var category: String  # "team", "deck", "boosts", "equipment"
	var price: int        # Gold cost
	
	func _init(item_name: String, item_category: String, item_price: int = 0):
		name = item_name
		category = item_category
		price = item_price

@onready var ante_label: Label = $UI/ScrollContainer/VBoxContainer/AnteLabel
@onready var gold_label: Label = $UI/ScrollContainer/VBoxContainer/GoldLabel
@onready var speed_label: Label = $UI/ScrollContainer/VBoxContainer/SpeedLabel
@onready var endurance_label: Label = $UI/ScrollContainer/VBoxContainer/EnduranceLabel
@onready var stamina_label: Label = $UI/ScrollContainer/VBoxContainer/StaminaLabel
@onready var power_label: Label = $UI/ScrollContainer/VBoxContainer/PowerLabel
@onready var team_count_label: Label = $UI/ScrollContainer/VBoxContainer/TeamCountLabel
@onready var deck_count_label: Label = $UI/ScrollContainer/VBoxContainer/DeckCountLabel
@onready var boosts_count_label: Label = $UI/ScrollContainer/VBoxContainer/BoostsCountLabel
@onready var equipment_count_label: Label = $UI/ScrollContainer/VBoxContainer/EquipmentCountLabel
@onready var team_container: VBoxContainer = $UI/ScrollContainer/VBoxContainer/TeamSection/TeamItemsContainer
@onready var deck_container: VBoxContainer = $UI/ScrollContainer/VBoxContainer/DeckSection/DeckItemsContainer
@onready var boosts_container: VBoxContainer = $UI/ScrollContainer/VBoxContainer/BoostsSection/BoostsItemsContainer
@onready var equipment_container: VBoxContainer = $UI/ScrollContainer/VBoxContainer/EquipmentSection/EquipmentItemsContainer
@onready var continue_button: Button = $UI/ScrollContainer/VBoxContainer/ContinueButton

var available_items: Array[Item] = []

# Simple item pools for each category
var team_items = ["Sprinter", "Endurance Runner", "Sprint Specialist", "Marathon Runner", "Speed Demon"]
var deck_items = ["Speed Boost", "Stamina Card", "Recovery Card", "Pace Card", "Finish Strong"]
var boost_items = ["Endurance", "Speed", "Recovery", "Pace", "Stamina"]
var equipment_items = ["Lightweight Shoes", "Energy Gel", "Training Program", "Recovery Kit", "Performance Monitor"]

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	_update_display()
	_generate_available_items()
	# Wait for frame to ensure UI is fully ready before displaying items
	await get_tree().process_frame
	_display_available_items()

func _update_display() -> void:
	ante_label.text = "Ante: %d" % GameManager.current_ante
	gold_label.text = "Gold: %d" % GameManager.get_gold()
	
	# Update stats
	speed_label.text = "Speed: %d" % GameManager.get_total_speed()
	endurance_label.text = "Endurance: %d" % GameManager.get_total_endurance()
	stamina_label.text = "Stamina: %d" % GameManager.get_total_stamina()
	power_label.text = "Power: %d" % GameManager.get_total_power()
	
	# Update inventory counts
	var team_size = GameManager.get_team_size()
	team_count_label.text = "Team: %d Varsity, %d JV" % [team_size.varsity, team_size.jv]
	deck_count_label.text = "Deck: %d" % GameManager.deck.size()
	boosts_count_label.text = "Boosts: %d" % GameManager.jokers.size()
	equipment_count_label.text = "Equipment: %d" % GameManager.shop_inventory.size()

func _get_item_price(category: String, base_name: String) -> int:
	# Base prices by category
	var base_price = 0
	match category:
		"team":
			base_price = 40  # Runners are expensive
			# Special runners cost more
			if base_name in ["Sprint Specialist", "Speed Demon", "Marathon Runner"]:
				base_price = 50
		"deck":
			base_price = 20  # Cards are moderate
		"boosts":
			base_price = 50  # Boosts are expensive (powerful)
		"equipment":
			base_price = 30  # Equipment is moderate
	
	# Scale price with ante (later antes = slightly more expensive)
	var ante_modifier = 1.0 + (GameManager.current_ante * 0.05)  # 5% increase per ante
	return int(base_price * ante_modifier)

func _generate_available_items() -> void:
	available_items.clear()
	
	# Use seed for deterministic generation
	seed(GameManager.seed + GameManager.current_ante * 1000)
	
	# Generate 2-3 items per category based on ante level
	var items_per_category = 2 + (GameManager.current_ante / 5)
	
	# Team items
	var used_team_indices = []
	for i in range(min(items_per_category, team_items.size())):
		var index = randi() % team_items.size()
		# Avoid duplicates in same shop
		while used_team_indices.has(index):
			index = randi() % team_items.size()
		used_team_indices.append(index)
		var item_name = team_items[index]
		var price = _get_item_price("team", item_name)
		available_items.append(Item.new("Runner: " + item_name, "team", price))
	
	# Deck items
	var used_deck_indices = []
	for i in range(min(items_per_category, deck_items.size())):
		var index = randi() % deck_items.size()
		while used_deck_indices.has(index):
			index = randi() % deck_items.size()
		used_deck_indices.append(index)
		var item_name = deck_items[index]
		var price = _get_item_price("deck", item_name)
		available_items.append(Item.new("Card: " + item_name, "deck", price))
	
	# Boost items (rarer, appear from ante 3+)
	if GameManager.current_ante >= 3:
		var index = randi() % boost_items.size()
		var item_name = boost_items[index]
		var price = _get_item_price("boosts", item_name)
		available_items.append(Item.new("Boost: " + item_name, "boosts", price))
	
	# Equipment items
	var used_equipment_indices = []
	for i in range(min(items_per_category, equipment_items.size())):
		var index = randi() % equipment_items.size()
		while used_equipment_indices.has(index):
			index = randi() % equipment_items.size()
		used_equipment_indices.append(index)
		var item_name = equipment_items[index]
		var price = _get_item_price("equipment", item_name)
		available_items.append(Item.new("Equipment: " + item_name, "equipment", price))
	
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

func _display_items_in_container(container: VBoxContainer, items: Array[Item]) -> void:
	for item in items:
		var button = Button.new()
		
		# Get item effect to display
		var effect = GameManager.get_item_effect(item.name, item.category)
		var effect_text = _format_effect_text(effect)
		
		# Check if player can afford
		var can_afford = GameManager.get_gold() >= item.price
		var price_text = "%d Gold" % item.price
		if not can_afford:
			price_text = "[Not Enough Gold] " + price_text
		
		button.text = item.name + "\n" + effect_text + "\n" + price_text + "\n(Select)"
		button.pressed.connect(_on_item_selected.bind(item))
		
		# Disable button if can't afford
		button.disabled = not can_afford
		
		# Style buttons based on category for visual distinction
		_style_item_button(button, item.category, can_afford)
		
		container.add_child(button)

func _style_item_button(button: Button, category: String, can_afford: bool = true) -> void:
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
	
	match category:
		"team":
			# Runners: Blue background to distinguish from cards
			style_normal.bg_color = Color(0.3, 0.5, 0.8, 0.7)  # Light blue, semi-transparent
			style_hover.bg_color = Color(0.3, 0.5, 0.8, 0.9)
			style_pressed.bg_color = Color(0.2, 0.4, 0.7, 0.9)
			style_disabled.bg_color = Color(0.2, 0.2, 0.3, 0.5)  # Dark gray when can't afford
			button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			if not can_afford:
				button.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6, 1))
		"deck":
			# Cards: Green background
			style_normal.bg_color = Color(0.4, 0.7, 0.4, 0.7)  # Light green, semi-transparent
			style_hover.bg_color = Color(0.4, 0.7, 0.4, 0.9)
			style_pressed.bg_color = Color(0.3, 0.6, 0.3, 0.9)
			style_disabled.bg_color = Color(0.2, 0.3, 0.2, 0.5)
			button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			if not can_afford:
				button.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6, 1))
		"boosts":
			# Boosts: Purple background
			style_normal.bg_color = Color(0.7, 0.4, 0.8, 0.7)  # Light purple
			style_hover.bg_color = Color(0.7, 0.4, 0.8, 0.9)
			style_pressed.bg_color = Color(0.6, 0.3, 0.7, 0.9)
			style_disabled.bg_color = Color(0.3, 0.2, 0.3, 0.5)
			button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			if not can_afford:
				button.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6, 1))
		"equipment":
			# Equipment: Orange background
			style_normal.bg_color = Color(0.9, 0.6, 0.3, 0.7)  # Light orange
			style_hover.bg_color = Color(0.9, 0.6, 0.3, 0.9)
			style_pressed.bg_color = Color(0.8, 0.5, 0.2, 0.9)
			style_disabled.bg_color = Color(0.3, 0.2, 0.1, 0.5)
			button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
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
	
	# Spend gold
	if not GameManager.spend_gold(item.price):
		print("Failed to purchase item: ", item.name)
		return
	
	# Add item to appropriate GameManager array
	match item.category:
		"team":
			# Try to add to varsity first, then JV if varsity is full
			var team_size = GameManager.get_team_size()
			if team_size.varsity < 5:
				if GameManager.add_varsity_runner(item.name):
					print("Added to varsity: ", item.name)
			elif team_size.jv < 2:
				if GameManager.add_jv_runner(item.name):
					print("Added to JV: ", item.name)
			else:
				print("Team is full! Cannot add more runners.")
				return  # Don't remove item if we couldn't add it
		"deck":
			GameManager.deck.append(item.name)
			print("Added to deck: ", item.name)
		"boosts":
			GameManager.jokers.append(item.name)
			print("Added boost: ", item.name)
		"equipment":
			GameManager.shop_inventory.append(item.name)
			print("Added equipment: ", item.name)
	
	# Remove item from available items by finding matching name and category
	for i in range(available_items.size()):
		if available_items[i].name == item.name and available_items[i].category == item.category:
			available_items.remove_at(i)
			break
	
	# Update display (this will refresh gold and stats)
	_update_display()
	# Redisplay items (this will update button states based on new gold amount)
	_display_available_items()

func _on_continue_pressed() -> void:
	# Return to Run scene
	get_tree().change_scene_to_file("res://scenes/run/Run.tscn")

