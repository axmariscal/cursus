extends Control

# Simple item data structure
class Item:
	var name: String
	var category: String  # "team", "deck", "jokers", "equipment"
	
	func _init(item_name: String, item_category: String):
		name = item_name
		category = item_category

@onready var ante_label: Label = $UI/ScrollContainer/VBoxContainer/AnteLabel
@onready var team_count_label: Label = $UI/ScrollContainer/VBoxContainer/TeamCountLabel
@onready var deck_count_label: Label = $UI/ScrollContainer/VBoxContainer/DeckCountLabel
@onready var jokers_count_label: Label = $UI/ScrollContainer/VBoxContainer/JokersCountLabel
@onready var equipment_count_label: Label = $UI/ScrollContainer/VBoxContainer/EquipmentCountLabel
@onready var team_container: VBoxContainer = $UI/ScrollContainer/VBoxContainer/TeamSection/TeamItemsContainer
@onready var deck_container: VBoxContainer = $UI/ScrollContainer/VBoxContainer/DeckSection/DeckItemsContainer
@onready var jokers_container: VBoxContainer = $UI/ScrollContainer/VBoxContainer/JokersSection/JokersItemsContainer
@onready var equipment_container: VBoxContainer = $UI/ScrollContainer/VBoxContainer/EquipmentSection/EquipmentItemsContainer
@onready var continue_button: Button = $UI/ScrollContainer/VBoxContainer/ContinueButton

var available_items: Array[Item] = []

# Simple item pools for each category
var team_items = ["Sprinter", "Endurance Runner", "Sprint Specialist", "Marathon Runner", "Speed Demon"]
var deck_items = ["Speed Boost", "Stamina Card", "Recovery Card", "Pace Card", "Finish Strong"]
var joker_items = ["Endurance", "Speed", "Recovery", "Pace", "Stamina"]
var equipment_items = ["Lightweight Shoes", "Energy Gel", "Training Program", "Recovery Kit", "Performance Monitor"]

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	_update_display()
	_generate_available_items()
	_display_available_items()

func _update_display() -> void:
	ante_label.text = "Ante: %d" % GameManager.current_ante
	team_count_label.text = "Team: %d" % GameManager.team.size()
	deck_count_label.text = "Deck: %d" % GameManager.deck.size()
	jokers_count_label.text = "Jokers: %d" % GameManager.jokers.size()
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
	
	# Joker items (rarer, appear from ante 3+)
	if GameManager.current_ante >= 3:
		var index = randi() % joker_items.size()
		var item_name = joker_items[index]
		available_items.append(Item.new("Joker: " + item_name, "jokers"))
	
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
	var jokers_items_list: Array[Item] = []
	var equipment_items_list: Array[Item] = []
	
	for item in available_items:
		match item.category:
			"team":
				team_items_list.append(item)
			"deck":
				deck_items_list.append(item)
			"jokers":
				jokers_items_list.append(item)
			"equipment":
				equipment_items_list.append(item)
	
	# Display items in their respective containers
	_display_items_in_container(team_container, team_items_list)
	_display_items_in_container(deck_container, deck_items_list)
	_display_items_in_container(jokers_container, jokers_items_list)
	_display_items_in_container(equipment_container, equipment_items_list)

func _display_items_in_container(container: VBoxContainer, items: Array[Item]) -> void:
	for item in items:
		var button = Button.new()
		button.text = item.name + " (Select)"
		button.pressed.connect(_on_item_selected.bind(item))
		container.add_child(button)

func _clear_containers() -> void:
	for child in team_container.get_children():
		child.queue_free()
	for child in deck_container.get_children():
		child.queue_free()
	for child in jokers_container.get_children():
		child.queue_free()
	for child in equipment_container.get_children():
		child.queue_free()

func _on_item_selected(item: Item) -> void:
	# Add item to appropriate GameManager array
	match item.category:
		"team":
			GameManager.team.append(item.name)
			print("Added to team: ", item.name)
		"deck":
			GameManager.deck.append(item.name)
			print("Added to deck: ", item.name)
		"jokers":
			GameManager.jokers.append(item.name)
			print("Added joker: ", item.name)
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

