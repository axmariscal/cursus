extends Control

# Simple item data structure
class Item:
	var name: String
	var category: String  # "team", "deck", "boosts", "equipment"
	
	func _init(item_name: String, item_category: String):
		name = item_name
		category = item_category

@onready var ante_label: Label = $UI/ScrollContainer/VBoxContainer/AnteLabel
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
		available_items.append(Item.new("Runner: " + item_name, "team"))
	
	# Deck items
	var used_deck_indices = []
	for i in range(min(items_per_category, deck_items.size())):
		var index = randi() % deck_items.size()
		while used_deck_indices.has(index):
			index = randi() % deck_items.size()
		used_deck_indices.append(index)
		var item_name = deck_items[index]
		available_items.append(Item.new("Card: " + item_name, "deck"))
	
	# Boost items (rarer, appear from ante 3+)
	if GameManager.current_ante >= 3:
		var index = randi() % boost_items.size()
		var item_name = boost_items[index]
		available_items.append(Item.new("Boost: " + item_name, "boosts"))
	
	# Equipment items
	var used_equipment_indices = []
	for i in range(min(items_per_category, equipment_items.size())):
		var index = randi() % equipment_items.size()
		while used_equipment_indices.has(index):
			index = randi() % equipment_items.size()
		used_equipment_indices.append(index)
		var item_name = equipment_items[index]
		available_items.append(Item.new("Equipment: " + item_name, "equipment"))
	
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
		
		button.text = item.name + "\n" + effect_text + "\n(Select)"
		button.pressed.connect(_on_item_selected.bind(item))
		
		# Style buttons based on category for visual distinction
		_style_item_button(button, item.category)
		
		container.add_child(button)

func _style_item_button(button: Button, category: String) -> void:
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
	
	match category:
		"team":
			# Runners: Blue background to distinguish from cards
			style_normal.bg_color = Color(0.3, 0.5, 0.8, 0.7)  # Light blue, semi-transparent
			style_hover.bg_color = Color(0.3, 0.5, 0.8, 0.9)
			style_pressed.bg_color = Color(0.2, 0.4, 0.7, 0.9)
			button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		"deck":
			# Cards: Green background
			style_normal.bg_color = Color(0.4, 0.7, 0.4, 0.7)  # Light green, semi-transparent
			style_hover.bg_color = Color(0.4, 0.7, 0.4, 0.9)
			style_pressed.bg_color = Color(0.3, 0.6, 0.3, 0.9)
			button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		"boosts":
			# Boosts: Purple background
			style_normal.bg_color = Color(0.7, 0.4, 0.8, 0.7)  # Light purple
			style_hover.bg_color = Color(0.7, 0.4, 0.8, 0.9)
			style_pressed.bg_color = Color(0.6, 0.3, 0.7, 0.9)
			button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		"equipment":
			# Equipment: Orange background
			style_normal.bg_color = Color(0.9, 0.6, 0.3, 0.7)  # Light orange
			style_hover.bg_color = Color(0.9, 0.6, 0.3, 0.9)
			style_pressed.bg_color = Color(0.8, 0.5, 0.2, 0.9)
			button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)


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
	
	# Update display
	_update_display()
	_display_available_items()

func _on_continue_pressed() -> void:
	# Return to Run scene
	get_tree().change_scene_to_file("res://scenes/run/Run.tscn")

