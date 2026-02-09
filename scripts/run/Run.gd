extends Control

# Main Run scene controller - coordinates UI, state, interactions, and styling

# Module instances
var run_state: RunState
var run_ui: RunUI
var run_styling: RunStyling
var tooltip_manager: TooltipManager
var card_interaction: CardInteraction

# Header elements
@onready var header_hbox: HBoxContainer = %HeaderHBox
@onready var gold_label: Label = %GoldLabel
@onready var race_type_label: Label = %RaceTypeLabel
@onready var seed_label: Label = %SeedLabel
@onready var ante_label: Label = %AnteLabel

# Left column - Team Stats
@onready var left_col: VBoxContainer = %LeftCol_Stats
@onready var speed_label: Label = %SpeedLabel
@onready var speed_delta: Label = %SpeedDelta
@onready var speed_bar: ProgressBar = %SpeedBar
@onready var endurance_label: Label = %EnduranceLabel
@onready var endurance_delta: Label = %EnduranceDelta
@onready var endurance_bar: ProgressBar = %EnduranceBar
@onready var stamina_label: Label = %StaminaLabel
@onready var stamina_delta: Label = %StaminaDelta
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var power_label: Label = %PowerLabel
@onready var power_delta: Label = %PowerDelta
@onready var power_bar: ProgressBar = %PowerBar
@onready var team_tray: HFlowContainer = %TeamTray
@onready var team_info_label: Label = %TeamInfoLabel
@onready var team_composition_label: Label = %TeamCompositionLabel

# Middle column - Inventory
@onready var mid_col: VBoxContainer = %MidCol_Inventory
@onready var inventory_vbox: VBoxContainer = %InventoryVBox
@onready var deck_grid: GridContainer = %DeckGrid
@onready var boosts_container: HFlowContainer = %BoostsContainer
@onready var equipment_container: HFlowContainer = %EquipmentContainer

# Right column - Action Hub
@onready var right_col: VBoxContainer = %RightCol_Actions
@onready var win_probability_label: Label = %WinProbabilityLabel
@onready var gauge_container: Control = %GaugeContainer
@onready var success_glow: GPUParticles2D = %SuccessGlow
@onready var win_probability_gauge: TextureProgressBar = %WinProbabilityGauge
@onready var start_race_button: Button = %StartRaceButton
@onready var complete_race_button: Button = %CompleteRaceButton
@onready var continue_to_shop_button: Button = %ContinueToShopButton
@onready var go_to_training_button: Button = %GoToTrainingButton
@onready var view_team_button: Button = %ViewTeamButton
@onready var save_run_button: Button = %SaveRunButton
@onready var back_button: Button = %BackButton

# Result panel
@onready var result_panel: Panel = %ResultPanel
@onready var result_label: Label = %ResultLabel
@onready var result_close_button: Button = %CloseButton

# Loading panel
@onready var loading_panel: Panel = %LoadingPanel
@onready var loading_label: Label = %LoadingLabel

# Tooltip
@onready var tooltip_panel: Panel = %TooltipPanel
@onready var tooltip_label: Label = %TooltipLabel

# Purchase feedback
@onready var purchase_feedback_label: Label = %PurchaseFeedbackLabel

# Breadcrumb
@onready var breadcrumb_label: Label = %BreadcrumbLabel

# Header bar reference for styling
@onready var header_bar: PanelContainer = %HeaderBar

var back_button_confirm_timer: float = 0.0
var back_button_waiting_confirm: bool = false

func _ready() -> void:
	# Initialize modules
	run_state = RunState.new()
	add_child(run_state)
	
	run_ui = RunUI.new()
	add_child(run_ui)
	
	run_styling = RunStyling.new()
	add_child(run_styling)
	
	tooltip_manager = TooltipManager.new()
	add_child(tooltip_manager)
	
	card_interaction = CardInteraction.new()
	add_child(card_interaction)
	
	# Setup UI module with references
	_setup_ui_module()
	
	# Connect buttons
	back_button.pressed.connect(_on_back_button_pressed)
	start_race_button.pressed.connect(_on_start_race_pressed)
	complete_race_button.pressed.connect(_on_complete_race_pressed)
	continue_to_shop_button.pressed.connect(_on_continue_to_shop_pressed)
	go_to_training_button.pressed.connect(_on_go_to_training_pressed)
	view_team_button.pressed.connect(_on_view_team_pressed)
	save_run_button.pressed.connect(_on_save_run_pressed)
	result_close_button.pressed.connect(_on_result_close_pressed)
	
	# Connect card interaction signals
	card_interaction.sell_requested.connect(_on_sell_item_pressed)
	
	# Setup keyboard shortcuts
	_setup_keyboard_shortcuts()
	
	# Setup Action Hub layout first
	right_col.add_theme_constant_override("separation", 15)
	right_col.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Style panels
	run_styling.style_panels(header_bar, tooltip_panel, result_panel)
	
	# Style progress bars
	run_styling.style_progress_bar(speed_bar, Color(0.2, 0.6, 0.9))
	run_styling.style_progress_bar(endurance_bar, Color(0.4, 0.7, 0.4))
	run_styling.style_progress_bar(stamina_bar, Color(0.9, 0.6, 0.3))
	run_styling.style_progress_bar(power_bar, Color(0.9, 0.4, 0.2))
	
	# Style buttons
	run_styling.style_action_button(start_race_button, Color(0.3, 0.8, 0.4))  # Green
	run_styling.style_action_button(complete_race_button, Color(0.5, 0.5, 0.5))  # Grey
	run_styling.style_shop_button(continue_to_shop_button, false)  # Start as gray/inactive
	run_styling.style_action_button(go_to_training_button, Color(0.3, 0.7, 0.9))  # Blue (inactive initially)
	run_styling.style_action_button(view_team_button, Color(0.2, 0.6, 0.9))  # Blue
	run_styling.style_action_button(save_run_button, Color(0.5, 0.7, 0.9))  # Light blue
	run_styling.style_action_button(back_button, Color(0.8, 0.3, 0.3))  # Red
	run_styling.style_action_button(result_close_button, Color(0.6, 0.6, 0.6))  # Grey
	
	# Style text labels
	_style_text_labels()
	
	# Hide tooltip initially
	tooltip_panel.visible = false
	purchase_feedback_label.visible = false
	
	# Setup particle system for success glow
	run_ui.setup_particle_system()
	
	# Setup win probability gauge
	run_ui.setup_win_probability_gauge()
	
	# Start a new run if one isn't active
	if not GameManager.run_active:
		GameManager.start_new_run()
	
	# Initialize race state
	run_state.set_race_state(RunState.RaceState.IDLE)
	
	# Update display with current run state
	_update_display()
	
	# Initialize win probability display (after _update_display sets initial values)
	var initial_prob = run_state.calculate_win_probability()
	run_ui.current_display_prob = initial_prob
	run_ui.previous_probability = initial_prob
	# Set initial value without animation
	win_probability_gauge.value = initial_prob
	run_ui.set_label_text(initial_prob)
	win_probability_gauge.tint_progress = run_styling.get_color_for_prob(initial_prob)
	run_ui.update_label_color(initial_prob, run_styling)
	
	# Ensure selected card stays raised - check periodically
	card_interaction.ensure_selected_card_raised()

func _setup_ui_module() -> void:
	# Setup UI module with all necessary references
	run_ui.header_labels = {
		"ante": ante_label,
		"race_type": race_type_label,
		"seed": seed_label,
		"gold": gold_label
	}
	
	run_ui.stat_labels = {
		"speed": speed_label,
		"endurance": endurance_label,
		"stamina": stamina_label,
		"power": power_label
	}
	
	run_ui.stat_deltas = {
		"speed": speed_delta,
		"endurance": endurance_delta,
		"stamina": stamina_delta,
		"power": power_delta
	}
	
	run_ui.stat_bars = {
		"speed": speed_bar,
		"endurance": endurance_bar,
		"stamina": stamina_bar,
		"power": power_bar
	}
	
	run_ui.team_labels = {
		"info": team_info_label,
		"composition": team_composition_label
	}
	
	run_ui.action_labels = {
		"win_probability": win_probability_label
	}
	
	run_ui.inventory_containers = {
		"deck": deck_grid,
		"boosts": boosts_container,
		"equipment": equipment_container
	}
	
	run_ui.team_tray = team_tray
	run_ui.win_probability_gauge = win_probability_gauge
	run_ui.win_probability_label = win_probability_label
	run_ui.gauge_container = gauge_container
	run_ui.success_glow = success_glow
	run_ui.result_panel = result_panel
	run_ui.result_label = result_label
	run_ui.loading_panel = loading_panel
	run_ui.loading_label = loading_label
	run_ui.purchase_feedback_label = purchase_feedback_label
	run_ui.breadcrumb_label = breadcrumb_label

func _style_text_labels() -> void:
	# Style text labels with dark colors for readability
	var labels_dict = {
		"header": [ante_label, seed_label],
		"stats": [speed_label, endurance_label, stamina_label, power_label],
		"team_info": [team_info_label, team_composition_label],
		"action_hub": [win_probability_label],
		"breadcrumb": [breadcrumb_label],
		"delta": [speed_delta, endurance_delta, stamina_delta, power_delta],
		"tooltip": [tooltip_label],
		"result": [result_label]
	}
	run_styling.style_text_labels(labels_dict)
	
	# Gold label special color
	gold_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))

func _setup_keyboard_shortcuts() -> void:
	# ESC to go back
	pass  # Will handle in _input()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC key
		_on_back_button_pressed()
	
	# Handle clicking outside team tray to deselect (but not on other cards or UI elements)
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			# Only deselect if clicking on empty space (not on cards, buttons, or other UI)
			var click_pos = mouse_event.position
			var tray_rect = Rect2(team_tray.global_position, team_tray.size)
			
			# Check if click was outside team tray
			if not tray_rect.has_point(click_pos):
				# Also check if click was on the sell button (don't deselect if clicking sell)
				if card_interaction.team_tray_sell_button != null and card_interaction.team_tray_sell_button.visible:
					var button_rect = Rect2(card_interaction.team_tray_sell_button.global_position, card_interaction.team_tray_sell_button.size)
					if button_rect.has_point(click_pos):
						return  # Click was on sell button, let it handle it
				
				# Check if click was on any interactive UI element (buttons, inventory, etc.)
				if not _is_click_on_interactive_element(click_pos):
					# Click was on empty space - deselect the card
					card_interaction.deselect_team_card()

func _is_click_on_interactive_element(click_pos: Vector2) -> bool:
	# Check if the click position is over any interactive UI element
	# This prevents deselection when clicking on buttons, inventory items, etc.
	
	# Check action buttons in right column
	var right_col_rect = Rect2(right_col.global_position, right_col.size)
	if right_col_rect.has_point(click_pos):
		return true
	
	# Check inventory area (middle column)
	var mid_col_rect = Rect2(mid_col.global_position, mid_col.size)
	if mid_col_rect.has_point(click_pos):
		return true
	
	# Check header area (might have buttons)
	var header_rect = Rect2(header_hbox.global_position, header_hbox.size)
	if header_rect.has_point(click_pos):
		return true
	
	# Check result panel if visible
	if result_panel.visible:
		var result_rect = Rect2(result_panel.global_position, result_panel.size)
		if result_rect.has_point(click_pos):
			return true
	
	return false

func _update_display() -> void:
	# Update display using UI module
	run_ui.update_display(
		run_state,
		run_styling,
		tooltip_manager,
		card_interaction,
		_get_sell_price,
		_get_card_texture_for_tray,
		tooltip_manager.create_tooltip_text,
		_on_sell_item_pressed
	)

func _set_race_state(new_state: RunState.RaceState) -> void:
	run_state.set_race_state(new_state)
	
	match new_state:
		RunState.RaceState.IDLE:
			run_ui.clear_result_display()
			start_race_button.disabled = false
			complete_race_button.disabled = true
			continue_to_shop_button.visible = true
			continue_to_shop_button.disabled = true
			go_to_training_button.visible = true
			go_to_training_button.disabled = true
			run_styling.style_shop_button(continue_to_shop_button, false)  # Gray when inactive
			run_styling.style_action_button(go_to_training_button, Color(0.3, 0.7, 0.9))  # Blue when inactive
		RunState.RaceState.RACING:
			run_ui.clear_result_display()
			start_race_button.disabled = true
			complete_race_button.disabled = false
			continue_to_shop_button.visible = true
			continue_to_shop_button.disabled = true
			go_to_training_button.visible = true
			go_to_training_button.disabled = true
			run_styling.style_shop_button(continue_to_shop_button, false)  # Gray when inactive
			run_styling.style_action_button(go_to_training_button, Color(0.3, 0.7, 0.9))  # Blue when inactive
		RunState.RaceState.COMPLETED:
			start_race_button.disabled = false
			complete_race_button.disabled = true
			continue_to_shop_button.visible = true
			go_to_training_button.visible = true
			# Enable both buttons after any race completion (win or lose)
			var won = false
			if not run_state.last_race_result.is_empty():
				won = run_state.last_race_result.get("won", false)
			# Always enable both buttons after race completion
			continue_to_shop_button.disabled = false
			go_to_training_button.disabled = false
			if won:
				run_styling.style_shop_button(continue_to_shop_button, true)  # Blue when won
				run_styling.style_action_button(go_to_training_button, Color(0.3, 0.8, 0.4))  # Green when won
			else:
				run_styling.style_shop_button(continue_to_shop_button, true)  # Blue when lost (still allow shopping)
				run_styling.style_action_button(go_to_training_button, Color(0.3, 0.7, 0.9))  # Blue when lost

func _on_result_close_pressed() -> void:
	run_ui.clear_result_display()
	# Update button state based on race completion
	# Enable both buttons after any race completion (win or lose)
	if run_state.get_race_state() == RunState.RaceState.COMPLETED:
		continue_to_shop_button.visible = true
		continue_to_shop_button.disabled = false
		go_to_training_button.visible = true
		go_to_training_button.disabled = false
		var won = false
		if not run_state.last_race_result.is_empty():
			won = run_state.last_race_result.get("won", false)
		run_styling.style_shop_button(continue_to_shop_button, true)  # Always enable shopping
		if won:
			run_styling.style_action_button(go_to_training_button, Color(0.3, 0.8, 0.4))  # Green when won
		else:
			run_styling.style_action_button(go_to_training_button, Color(0.3, 0.7, 0.9))  # Blue when lost

func _on_start_race_pressed() -> void:
	var current_state = run_state.get_race_state()
	if current_state == RunState.RaceState.IDLE or current_state == RunState.RaceState.COMPLETED:
		if not run_state.can_start_race():
			run_ui.show_result_display("❌ Cannot Start Race!\n\nYou need 5 varsity runners.\nCurrent: %d\n\nGo to Shop to recruit more runners." % GameManager.varsity_team.size())
			_set_race_state(RunState.RaceState.IDLE)
			return
		
		if run_state.start_race():
			_set_race_state(RunState.RaceState.RACING)

func _on_complete_race_pressed() -> void:
	if run_state.get_race_state() == RunState.RaceState.RACING:
		if not run_state.can_start_race():
			run_ui.show_result_display("❌ Cannot race!\n\nYou need 5 varsity runners.\nCurrent: %d" % GameManager.varsity_team.size())
			_set_race_state(RunState.RaceState.IDLE)
			return
		
		var race_result = run_state.complete_race()
		
		if race_result.is_empty():
			return
		
		# Permadeath: if 3 losses in a row, end run and show Run Failed screen (Phase 4.1)
		if not race_result.get("won", false) and GameManager.is_run_failed():
			GameManager.end_run("consecutive_losses")
			get_tree().change_scene_to_file("res://scenes/core/RunFailedScene.tscn")
			return
		
		var result_message = run_state.get_result_message(race_result)
		
		# Update display first to show new gold
		_update_display()
		# Set race state (this will enable shop button if won)
		# Note: complete_race() already sets the state to COMPLETED, but we call this
		# to ensure UI is properly updated
		_set_race_state(RunState.RaceState.COMPLETED)
		# Enable both buttons after any race completion (win or lose)
		# Players should be able to train and shop to improve their team regardless of outcome
		continue_to_shop_button.visible = true
		continue_to_shop_button.disabled = false
		go_to_training_button.visible = true
		go_to_training_button.disabled = false
		var won = race_result.get("won", false)
		run_styling.style_shop_button(continue_to_shop_button, true)  # Always enable shopping
		if won:
			run_styling.style_action_button(go_to_training_button, Color(0.3, 0.8, 0.4))  # Green when won
		else:
			run_styling.style_action_button(go_to_training_button, Color(0.3, 0.7, 0.9))  # Blue when lost
		# Show result display after state is set
		run_ui.show_result_display(result_message)

func _on_go_to_training_pressed() -> void:
	# Deselect card when navigating
	card_interaction.deselect_team_card()
	
	# Check if draft should appear first (only at ante 1)
	if _should_show_draft():
		run_ui.show_loading_screen("Loading Draft...")
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/core/DraftScene.tscn")
	else:
		# Go directly to Training
		run_ui.show_loading_screen("Loading Training...")
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/core/TrainingScene.tscn")

func _on_continue_to_shop_pressed() -> void:
	# Deselect card when navigating
	card_interaction.deselect_team_card()
	
	# Check if draft should appear first (only at ante 1)
	if _should_show_draft():
		run_ui.show_loading_screen("Loading Draft...")
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/core/DraftScene.tscn")
	else:
		# Go directly to Shop (can be accessed independently)
		run_ui.show_loading_screen("Loading Shop...")
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/core/ShopScene.tscn")

func _should_show_draft() -> bool:
	# Only show draft ONCE at the very start (ante 1) if not already completed
	# Never show at any other ante (ante 2, 3, 4, etc.)
	
	# Explicit check: ONLY show if ante is exactly 1 AND draft hasn't been completed
	if GameManager.current_ante != 1:
		# Not at ante 1, so never show draft
		return false
	
	# We're at ante 1, but check if draft was already completed
	if GameManager.draft_completed:
		# Draft already completed, don't show again
		return false
	
	# At ante 1 and draft not completed - show it
	return true

func _on_view_team_pressed() -> void:
	# Deselect card when navigating to team management
	card_interaction.deselect_team_card()
	get_tree().change_scene_to_file("res://scenes/core/TeamManagement.tscn")

func _on_save_run_pressed() -> void:
	# Show save slot selection dialog
	# For now, save to slot 1 (can be enhanced later with slot selection UI)
	if GameManager.save_run(1):
		run_ui.show_purchase_feedback("✓ Run saved to slot 1!", true)
	else:
		run_ui.show_purchase_feedback("❌ Failed to save run", false)

func _on_back_button_pressed() -> void:
	if not back_button_waiting_confirm:
		# First press - ask for confirmation
		back_button.text = "Are you sure?"
		back_button_waiting_confirm = true
		back_button_confirm_timer = 2.0
		
		# Reset after 2 seconds if not pressed again
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(_reset_back_button)
	else:
		# Second press - actually go back
		# Deselect card when navigating to main menu
		card_interaction.deselect_team_card()
		get_tree().change_scene_to_file("res://scenes/core/Main.tscn")

func _reset_back_button() -> void:
	if back_button_waiting_confirm:
		back_button.text = "BACK TO MENU"
		back_button_waiting_confirm = false

func _get_card_texture_for_tray(item_name: String, category: String) -> Texture2D:
	# Extract base name (remove prefix like "Runner: ", "Card: ", etc.)
	var base_name = item_name
	if ":" in item_name:
		base_name = item_name.split(":")[1].strip_edges()
	
	# Convert name to file path format (lowercase, spaces to underscores)
	var file_name = base_name.to_lower().replace(" ", "_")
	
	# Handle special cases for file names that don't match exactly
	var file_name_map = {
		"freshman_walk-on": "walkon_rnr",
		"the_closer": "closer_rnr",
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
	
	# Return null if image doesn't exist
	return null

func _get_sell_price(_item_name: String, category: String) -> int:
	var base_price = 0
	match category:
		"team": base_price = 40
		"deck": base_price = 20
		"boosts": base_price = 50
		"equipment": base_price = 30
	return int(base_price * 0.5)

func _on_sell_item_pressed(item_data: Dictionary) -> void:
	var item_name = item_data.name
	var category = item_data.category
	var index = item_data.index
	var is_varsity = item_data.get("is_varsity", false)
	var sell_price = _get_sell_price(item_name, category)
	
	# Special check for varsity runners
	if category == "team" and is_varsity and GameManager.varsity_team.size() <= 5:
		run_ui.show_purchase_feedback("⚠️ Cannot sell: Need at least 5 varsity runners!", false)
		return
	
	var sold_successfully = false
	match category:
		"team":
			if is_varsity:
				if GameManager.varsity_team.size() > 5 and index >= 0 and index < GameManager.varsity_team.size():
					GameManager.remove_varsity_runner(index)
					sold_successfully = true
			else:
				if index >= 0 and index < GameManager.jv_team.size():
					GameManager.remove_jv_runner(index)
					sold_successfully = true
		"deck":
			if index >= 0 and index < GameManager.deck.size():
				GameManager.deck.remove_at(index)
				sold_successfully = true
		"boosts":
			if index >= 0 and index < GameManager.jokers.size():
				GameManager.jokers.remove_at(index)
				sold_successfully = true
		"equipment":
			if index >= 0 and index < GameManager.shop_inventory.size():
				GameManager.shop_inventory.remove_at(index)
				sold_successfully = true
	
	if sold_successfully:
		GameManager.earn_gold(sell_price)
		run_ui.show_purchase_feedback("✓ Sold for %d Gold!" % sell_price, true)
		_update_display()
		# Update win probability with animation after selling
		var new_prob = run_state.calculate_win_probability()
		run_ui.update_probability_display(new_prob, run_styling)
	else:
		run_ui.show_purchase_feedback("❌ Failed to sell item", false)
