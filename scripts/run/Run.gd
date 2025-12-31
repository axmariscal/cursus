extends Control

enum RaceState {
	IDLE,
	RACING,
	COMPLETED
}

var race_state: RaceState = RaceState.IDLE

# Header elements
@onready var header_hbox: HBoxContainer = $UI/MainContainer/MainVBox/HeaderBar/HeaderMargin/HeaderHBox
@onready var gold_label: Label = $UI/MainContainer/MainVBox/HeaderBar/HeaderMargin/HeaderHBox/GoldContainer/GoldLabel
@onready var race_type_label: Label = $UI/MainContainer/MainVBox/HeaderBar/HeaderMargin/HeaderHBox/CenterInfo/RaceTypeLabel
@onready var seed_label: Label = $UI/MainContainer/MainVBox/HeaderBar/HeaderMargin/HeaderHBox/CenterInfo/SeedLabel
@onready var ante_label: Label = $UI/MainContainer/MainVBox/HeaderBar/HeaderMargin/HeaderHBox/AnteContainer/AnteLabel

# Left column - Team Stats
@onready var left_col: VBoxContainer = $UI/MainContainer/MainVBox/ContentBody/LeftCol_Stats
@onready var speed_label: Label = $UI/MainContainer/MainVBox/ContentBody/LeftCol_Stats/SpeedContainer/SpeedRow/SpeedLabel
@onready var speed_delta: Label = $UI/MainContainer/MainVBox/ContentBody/LeftCol_Stats/SpeedContainer/SpeedRow/SpeedDelta
@onready var speed_bar: ProgressBar = $UI/MainContainer/MainVBox/ContentBody/LeftCol_Stats/SpeedContainer/SpeedBar
@onready var endurance_label: Label = $UI/MainContainer/MainVBox/ContentBody/LeftCol_Stats/EnduranceContainer/EnduranceRow/EnduranceLabel
@onready var endurance_delta: Label = $UI/MainContainer/MainVBox/ContentBody/LeftCol_Stats/EnduranceContainer/EnduranceRow/EnduranceDelta
@onready var endurance_bar: ProgressBar = $UI/MainContainer/MainVBox/ContentBody/LeftCol_Stats/EnduranceContainer/EnduranceBar
@onready var stamina_label: Label = $UI/MainContainer/MainVBox/ContentBody/LeftCol_Stats/StaminaContainer/StaminaRow/StaminaLabel
@onready var stamina_delta: Label = $UI/MainContainer/MainVBox/ContentBody/LeftCol_Stats/StaminaContainer/StaminaRow/StaminaDelta
@onready var stamina_bar: ProgressBar = $UI/MainContainer/MainVBox/ContentBody/LeftCol_Stats/StaminaContainer/StaminaBar
@onready var power_label: Label = $UI/MainContainer/MainVBox/ContentBody/LeftCol_Stats/PowerContainer/PowerRow/PowerLabel
@onready var power_delta: Label = $UI/MainContainer/MainVBox/ContentBody/LeftCol_Stats/PowerContainer/PowerRow/PowerDelta
@onready var power_bar: ProgressBar = $UI/MainContainer/MainVBox/ContentBody/LeftCol_Stats/PowerContainer/PowerBar
@onready var team_tray: HFlowContainer = $UI/MainContainer/MainVBox/ContentBody/LeftCol_Stats/TeamTray
@onready var team_info_label: Label = $UI/MainContainer/MainVBox/ContentBody/LeftCol_Stats/TeamInfoLabel
@onready var team_composition_label: Label = $UI/MainContainer/MainVBox/ContentBody/LeftCol_Stats/TeamCompositionLabel

# Middle column - Inventory
@onready var mid_col: VBoxContainer = $UI/MainContainer/MainVBox/ContentBody/MidCol_Inventory
@onready var inventory_vbox: VBoxContainer = $UI/MainContainer/MainVBox/ContentBody/MidCol_Inventory/InventoryScroll/InventoryVBox
@onready var varsity_runners_container: HFlowContainer = $UI/MainContainer/MainVBox/ContentBody/MidCol_Inventory/InventoryScroll/InventoryVBox/VarsitySection/VarsityRunnersContainer
@onready var jv_runners_container: HFlowContainer = $UI/MainContainer/MainVBox/ContentBody/MidCol_Inventory/InventoryScroll/InventoryVBox/JVSection/JVRunnersContainer
@onready var deck_grid: GridContainer = $UI/MainContainer/MainVBox/ContentBody/MidCol_Inventory/InventoryScroll/InventoryVBox/DeckSection/DeckGrid
@onready var boosts_container: HFlowContainer = $UI/MainContainer/MainVBox/ContentBody/MidCol_Inventory/InventoryScroll/InventoryVBox/BoostsSection/BoostsContainer
@onready var equipment_container: HFlowContainer = $UI/MainContainer/MainVBox/ContentBody/MidCol_Inventory/InventoryScroll/InventoryVBox/EquipmentSection/EquipmentContainer

# Right column - Action Hub
@onready var right_col: VBoxContainer = $UI/MainContainer/MainVBox/ContentBody/RightCol_Actions
@onready var win_probability_label: Label = $UI/MainContainer/MainVBox/ContentBody/RightCol_Actions/WinProbabilityLabel
@onready var gauge_container: Control = $UI/MainContainer/MainVBox/ContentBody/RightCol_Actions/GaugeContainer
@onready var success_glow: GPUParticles2D = $UI/MainContainer/MainVBox/ContentBody/RightCol_Actions/GaugeContainer/SuccessGlow
@onready var win_probability_gauge: TextureProgressBar = $UI/MainContainer/MainVBox/ContentBody/RightCol_Actions/GaugeContainer/WinProbabilityGauge
@onready var start_race_button: Button = $UI/MainContainer/MainVBox/ContentBody/RightCol_Actions/StartRaceButton
@onready var complete_race_button: Button = $UI/MainContainer/MainVBox/ContentBody/RightCol_Actions/CompleteRaceButton
@onready var continue_to_shop_button: Button = $UI/MainContainer/MainVBox/ContentBody/RightCol_Actions/ContinueToShopButton
@onready var view_team_button: Button = $UI/MainContainer/MainVBox/ContentBody/RightCol_Actions/ViewTeamButton
@onready var back_button: Button = $UI/MainContainer/MainVBox/ContentBody/RightCol_Actions/BackButton

# Result panel
@onready var result_panel: Panel = $UI/ResultPanel
@onready var result_label: Label = $UI/ResultPanel/VBoxContainer/ResultLabel
@onready var result_close_button: Button = $UI/ResultPanel/VBoxContainer/CloseButton

# Loading panel
@onready var loading_panel: Panel = $UI/LoadingPanel
@onready var loading_label: Label = $UI/LoadingPanel/LoadingLabel

# Tooltip
@onready var tooltip_panel: Panel = $UI/TooltipPanel
@onready var tooltip_label: Label = $UI/TooltipPanel/TooltipLabel

# Purchase feedback
@onready var purchase_feedback_label: Label = $UI/PurchaseFeedbackLabel

# Breadcrumb
@onready var breadcrumb_label: Label = $UI/MainContainer/MainVBox/FooterSpace/BreadcrumbLabel

var previous_ante: int = 1
var last_race_result: Dictionary = {}
var hovered_item: Dictionary = {}  # Store hovered item info for tooltip
var current_display_prob: float = 0.0
var previous_probability: float = 0.0
var back_button_confirm_timer: float = 0.0
var back_button_waiting_confirm: bool = false
var danger_pulse_tween: Tween = null

# Team tray selection state tracking
var selected_team_card: VBoxContainer = null  # Currently selected card container
var selected_team_card_data: Dictionary = {}  # Data for selected card
var team_tray_sell_button: Button = null  # Sell button that appears when card is selected

func _ready() -> void:
	# Connect buttons
	back_button.pressed.connect(_on_back_button_pressed)
	start_race_button.pressed.connect(_on_start_race_pressed)
	complete_race_button.pressed.connect(_on_complete_race_pressed)
	continue_to_shop_button.pressed.connect(_on_continue_to_shop_pressed)
	view_team_button.pressed.connect(_on_view_team_pressed)
	result_close_button.pressed.connect(_on_result_close_pressed)
	
	# Setup keyboard shortcuts
	_setup_keyboard_shortcuts()
	
	# Setup Action Hub layout first
	right_col.add_theme_constant_override("separation", 15)
	right_col.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Style panels
	_style_panels()
	
	# Style text labels with dark colors for readability
	_style_text_labels()
	
	# Hide tooltip initially
	tooltip_panel.visible = false
	purchase_feedback_label.visible = false
	
	# Setup particle system for success glow
	_setup_particle_system()
	
	# Start a new run if one isn't active
	if not GameManager.run_active:
		GameManager.start_new_run()
	
	# Initialize race state
	_set_race_state(RaceState.IDLE)
	
	# Update display with current run state
	_update_display()
	
	# Initialize win probability display (after _update_display sets initial values)
	var initial_prob = _calculate_win_probability()
	current_display_prob = initial_prob
	previous_probability = initial_prob
	# Set initial value without animation
	win_probability_gauge.value = initial_prob
	set_label_text(initial_prob)
	win_probability_gauge.tint_progress = _get_color_for_prob(initial_prob)
	_update_label_color(initial_prob)

func _setup_keyboard_shortcuts() -> void:
	# ESC to go back
	pass  # Will handle in _input()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC key
		_on_back_button_pressed()

func _style_panels() -> void:
	# Style header bar - lighter to match background
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.949, 0.918, 0.843, 0.8)  # Match background with slight transparency
	header_style.border_color = Color(0.5, 0.5, 0.5, 0.6)
	header_style.border_width_left = 1
	header_style.border_width_top = 1
	header_style.border_width_right = 1
	header_style.border_width_bottom = 2
	header_style.corner_radius_top_left = 3
	header_style.corner_radius_top_right = 3
	header_style.corner_radius_bottom_right = 3
	header_style.corner_radius_bottom_left = 3
	$UI/MainContainer/MainVBox/HeaderBar.add_theme_stylebox_override("panel", header_style)
	
	# Style progress bars
	_style_progress_bar(speed_bar, Color(0.2, 0.6, 0.9))
	_style_progress_bar(endurance_bar, Color(0.4, 0.7, 0.4))
	_style_progress_bar(stamina_bar, Color(0.9, 0.6, 0.3))
	_style_progress_bar(power_bar, Color(0.9, 0.4, 0.2))
	# Win probability gauge is now a TextureProgressBar, styled separately
	_setup_win_probability_gauge()
	
	# Style buttons
	_style_action_button(start_race_button, Color(0.3, 0.8, 0.4))  # Green
	_style_action_button(complete_race_button, Color(0.5, 0.5, 0.5))  # Grey
	_style_action_button(continue_to_shop_button, Color(0.2, 0.6, 0.9))  # Blue
	_style_action_button(view_team_button, Color(0.2, 0.6, 0.9))  # Blue
	_style_action_button(back_button, Color(0.8, 0.3, 0.3))  # Red
	_style_action_button(result_close_button, Color(0.6, 0.6, 0.6))  # Grey

func _style_progress_bar(bar: ProgressBar, fill_color: Color) -> void:
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.3, 0.3, 0.3, 0.5)
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_right = 3
	bg_style.corner_radius_bottom_left = 3
	bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_right = 3
	fill_style.corner_radius_bottom_left = 3
	bar.add_theme_stylebox_override("fill", fill_style)

func _style_action_button(button: Button, color: Color) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = color
	style_normal.corner_radius_top_left = 5
	style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_right = 5
	style_normal.corner_radius_bottom_left = 5
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = color.lightened(0.15)
	style_hover.corner_radius_top_left = 5
	style_hover.corner_radius_top_right = 5
	style_hover.corner_radius_bottom_right = 5
	style_hover.corner_radius_bottom_left = 5
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = color.darkened(0.2)
	style_pressed.corner_radius_top_left = 5
	style_pressed.corner_radius_top_right = 5
	style_pressed.corner_radius_bottom_right = 5
	style_pressed.corner_radius_bottom_left = 5
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	# Style tooltip
	var tooltip_style = StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	tooltip_style.border_color = Color(0.5, 0.5, 0.5, 1.0)
	tooltip_style.border_width_left = 2
	tooltip_style.border_width_top = 2
	tooltip_style.border_width_right = 2
	tooltip_style.border_width_bottom = 2
	tooltip_style.corner_radius_top_left = 5
	tooltip_style.corner_radius_top_right = 5
	tooltip_style.corner_radius_bottom_right = 5
	tooltip_style.corner_radius_bottom_left = 5
	tooltip_panel.add_theme_stylebox_override("panel", tooltip_style)
	
	# Style result panel
	var result_style = StyleBoxFlat.new()
	result_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	result_style.border_color = Color(0.5, 0.5, 0.5, 1.0)
	result_style.border_width_left = 3
	result_style.border_width_top = 3
	result_style.border_width_right = 3
	result_style.border_width_bottom = 3
	result_style.corner_radius_top_left = 8
	result_style.corner_radius_top_right = 8
	result_style.corner_radius_bottom_right = 8
	result_style.corner_radius_bottom_left = 8
	result_panel.add_theme_stylebox_override("panel", result_style)

func _style_text_labels() -> void:
	# Dark grey color for text on light backgrounds
	var dark_text_color = Color(0.3, 0.3, 0.3, 1.0)  # Dark grey
	var medium_dark_color = Color(0.4, 0.4, 0.4, 1.0)  # Medium dark grey
	
	# Header labels
	ante_label.add_theme_color_override("font_color", dark_text_color)
	seed_label.add_theme_color_override("font_color", dark_text_color)
	breadcrumb_label.add_theme_color_override("font_color", medium_dark_color)
	
	# Stats labels
	speed_label.add_theme_color_override("font_color", dark_text_color)
	endurance_label.add_theme_color_override("font_color", dark_text_color)
	stamina_label.add_theme_color_override("font_color", dark_text_color)
	power_label.add_theme_color_override("font_color", dark_text_color)
	
	# Team info labels
	team_info_label.add_theme_color_override("font_color", dark_text_color)
	team_composition_label.add_theme_color_override("font_color", dark_text_color)
	
	# Action hub labels
	win_probability_label.add_theme_color_override("font_color", dark_text_color)
	
	# Panel headers
	var stats_header = left_col.get_node_or_null("StatsHeader")
	if stats_header:
		stats_header.add_theme_color_override("font_color", dark_text_color)
	
	var inventory_header = mid_col.get_node_or_null("InventoryHeader")
	if inventory_header:
		inventory_header.add_theme_color_override("font_color", dark_text_color)
	
	var action_header = right_col.get_node_or_null("ActionHeader")
	if action_header:
		action_header.add_theme_color_override("font_color", dark_text_color)
	
	# Section headers in inventory
	var varsity_header = inventory_vbox.get_node_or_null("VarsitySection/VarsityHeader")
	if varsity_header:
		varsity_header.add_theme_color_override("font_color", dark_text_color)
	
	var jv_header = inventory_vbox.get_node_or_null("JVSection/JVHeader")
	if jv_header:
		jv_header.add_theme_color_override("font_color", dark_text_color)
	
	var deck_header = inventory_vbox.get_node_or_null("DeckSection/DeckHeader")
	if deck_header:
		deck_header.add_theme_color_override("font_color", dark_text_color)
	
	var boosts_header = inventory_vbox.get_node_or_null("BoostsSection/BoostsHeader")
	if boosts_header:
		boosts_header.add_theme_color_override("font_color", dark_text_color)
	
	var equipment_header = inventory_vbox.get_node_or_null("EquipmentSection/EquipmentHeader")
	if equipment_header:
		equipment_header.add_theme_color_override("font_color", dark_text_color)
	
	# Delta labels (green for bonuses)
	speed_delta.add_theme_color_override("font_color", Color(0.2, 0.7, 0.2))
	endurance_delta.add_theme_color_override("font_color", Color(0.2, 0.7, 0.2))
	stamina_delta.add_theme_color_override("font_color", Color(0.2, 0.7, 0.2))
	power_delta.add_theme_color_override("font_color", Color(0.2, 0.7, 0.2))
	
	# Tooltip text (light text on dark background)
	tooltip_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	# Result label (light text on dark background)
	result_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _update_display() -> void:
	# Update header
	ante_label.text = "🏆 Ante: %d/%d" % [GameManager.current_ante, GameManager.max_ante]
	race_type_label.text = "Race: %s" % GameManager.get_race_type_name()
	_style_race_type_label()
	seed_label.text = "Seed: %d" % GameManager.seed
	gold_label.text = "💰 Gold: %d" % GameManager.get_gold()
	gold_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	
	# Update stats with progress bars and deltas
	var speed = GameManager.get_total_speed()
	var endurance = GameManager.get_total_endurance()
	var stamina = GameManager.get_total_stamina()
	var power = GameManager.get_total_power()
	
	# Calculate JV bonuses (25% of JV stats)
	var jv_speed_bonus = 0
	var jv_endurance_bonus = 0
	var jv_stamina_bonus = 0
	var jv_power_bonus = 0
	
	for runner in GameManager.jv_team:
		var effect = GameManager.get_item_effect(runner, "team")
		jv_speed_bonus += int(effect.speed * 0.25)
		jv_endurance_bonus += int(effect.endurance * 0.25)
		jv_stamina_bonus += int(effect.stamina * 0.25)
		jv_power_bonus += int(effect.power * 0.25)
	
	speed_label.text = "Speed: %d" % speed
	speed_delta.text = "+%d" % jv_speed_bonus if jv_speed_bonus > 0 else ""
	speed_bar.value = speed
	
	endurance_label.text = "Endurance: %d" % endurance
	endurance_delta.text = "+%d" % jv_endurance_bonus if jv_endurance_bonus > 0 else ""
	endurance_bar.value = endurance
	
	stamina_label.text = "Stamina: %d" % stamina
	stamina_delta.text = "+%d" % jv_stamina_bonus if jv_stamina_bonus > 0 else ""
	stamina_bar.value = stamina
	
	power_label.text = "Power: %d" % power
	power_delta.text = "+%d" % jv_power_bonus if jv_power_bonus > 0 else ""
	power_bar.value = power
	
	# Update team info
	var team_size = GameManager.get_team_size()
	team_info_label.text = "Team: %d Varsity, %d JV" % [team_size.varsity, team_size.jv]
	
	# Update team composition breakdown
	_update_team_composition()
	
	# Update win probability with smooth animation
	var new_probability = _calculate_win_probability()
	update_probability_display(new_probability)
	
	# Update breadcrumb
	breadcrumb_label.text = "Main > Run"
	
	# Display inventory and team tray
	_display_inventory()
	_display_team_tray()

func _update_team_composition() -> void:
	# Count runner types by archetype
	var front_runner_count = 0  # Speed/Power focused
	var stayer_count = 0  # Endurance/Stamina focused
	var kicker_count = 0  # Speed/Stamina focused
	var all_around_count = 0  # Balanced
	
	# Front Runner archetypes (Speed/Power)
	var front_runner_types = ["Hill Specialist", "The Closer", "Track Tourist", "Elite V-State Harrier", "Caffeine Fiend"]
	# Stayer archetypes (Endurance/Stamina)
	var stayer_types = ["Steady State Runner", "Ghost of the Woods"]
	# Kicker archetypes (Speed/Stamina)
	var kicker_types = ["Short-Cutter"]
	# All-Around types
	var all_around_types = ["Tempo Runner", "Freshman Walk-on", "All-Terrain Captain", "The Legend", "JV Legend"]
	
	for runner in GameManager.varsity_team:
		var base_name = runner.split(":")[1].strip_edges() if ":" in runner else runner
		if base_name in front_runner_types:
			front_runner_count += 1
		elif base_name in stayer_types:
			stayer_count += 1
		elif base_name in kicker_types:
			kicker_count += 1
		elif base_name in all_around_types:
			all_around_count += 1
	
	for runner in GameManager.jv_team:
		var base_name = runner.split(":")[1].strip_edges() if ":" in runner else runner
		if base_name in front_runner_types:
			front_runner_count += 1
		elif base_name in stayer_types:
			stayer_count += 1
		elif base_name in kicker_types:
			kicker_count += 1
		elif base_name in all_around_types:
			all_around_count += 1
	
	var composition_parts = []
	if front_runner_count > 0:
		composition_parts.append("%d Front Runners" % front_runner_count)
	if stayer_count > 0:
		composition_parts.append("%d Stayers" % stayer_count)
	if kicker_count > 0:
		composition_parts.append("%d Kickers" % kicker_count)
	if all_around_count > 0:
		composition_parts.append("%d All-Around" % all_around_count)
	
	if composition_parts.is_empty():
		team_composition_label.text = "No runners"
	else:
		team_composition_label.text = "Composition: " + ", ".join(composition_parts)

func _calculate_win_probability() -> float:
	# Calculate win probability based on stats vs ante difficulty
	var player_strength = (GameManager.get_total_speed() + GameManager.get_total_endurance() + GameManager.get_total_stamina() + GameManager.get_total_power()) / 4.0
	var opponent_strength = 50 + (GameManager.current_ante * 10)
	return clamp((player_strength / opponent_strength) * 100, 0, 100)

func _setup_win_probability_gauge() -> void:
	# Setup the TextureProgressBar for radial display
	# Set pivot for scaling effects (will be set properly after layout)
	await get_tree().process_frame
	win_probability_gauge.pivot_offset = win_probability_gauge.size / 2

func _setup_particle_system() -> void:
	# Configure the success glow particle system
	success_glow.visible = false
	success_glow.emitting = false
	# Set particle color to green using modulate
	success_glow.modulate = Color(0.3, 0.8, 0.4, 1.0)  # Green tint
	# Configure particle behavior
	var material = ParticleProcessMaterial.new()
	material.gravity = Vector3(0, -50, 0)
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 100.0
	material.angular_velocity_min = -180.0
	material.angular_velocity_max = 180.0
	material.scale_min = 0.5
	material.scale_max = 1.0
	success_glow.process_material = material

func update_probability_display(new_val: float) -> void:
	var duration = 0.6  # Seconds
	var prob_increase = new_val - previous_probability
	
	# 1. Create a Tween for the Gauge and the Number
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	# Animate the gauge fill
	tween.tween_property(win_probability_gauge, "value", new_val, duration)
	
	# Animate the number text (using a custom method to lerp the value)
	tween.tween_method(set_label_text, current_display_prob, new_val, duration)
	
	# 2. Add a "Squash and Stretch" effect to the gauge for impact
	var scale_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	win_probability_gauge.pivot_offset = win_probability_gauge.size / 2
	scale_tween.tween_property(win_probability_gauge, "scale", Vector2(1.1, 1.1), 0.1)
	scale_tween.tween_property(win_probability_gauge, "scale", Vector2(1.0, 1.0), 0.3)
	
	# 3. Dynamic Color Shifting
	tween.tween_property(win_probability_gauge, "tint_progress", _get_color_for_prob(new_val), duration)
	
	# 4. Success Glow Effect (if probability increased significantly)
	if prob_increase >= 10.0:
		_trigger_success_glow()
	
	# 5. Danger Shake and Pulsing (if probability is dangerously low)
	if new_val < 30.0:
		_trigger_danger_effects()
	else:
		_stop_danger_effects()
	
	# Update label color based on probability
	_update_label_color(new_val)
	
	current_display_prob = new_val
	previous_probability = new_val

func set_label_text(value: float) -> void:
	win_probability_label.text = "Win Probability: %d%%" % int(round(value))

func _get_color_for_prob(val: float) -> Color:
	if val < 40:
		return Color.html("#e64d4d")  # Red
	elif val < 70:
		return Color.html("#e6bc4d")  # Yellow/Orange
	else:
		return Color.html("#69b378")  # Green

func _trigger_success_glow() -> void:
	# Create particle effect for success
	success_glow.visible = true
	success_glow.restart()
	success_glow.emitting = true
	
	# Hide after animation completes
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(func(): success_glow.visible = false)

func _trigger_danger_effects() -> void:
	# Shake the gauge container
	var shake_tween = create_tween()
	var shake_amount = 5.0
	var original_pos = gauge_container.position
	
	# Create a shake pattern
	for i in range(8):
		var offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		shake_tween.tween_property(gauge_container, "position", original_pos + offset, 0.05)
		shake_tween.tween_property(gauge_container, "position", original_pos, 0.05)
	
	# Pulsing animation for the label (only if not already pulsing)
	if not danger_pulse_tween or not danger_pulse_tween.is_valid():
		if danger_pulse_tween:
			danger_pulse_tween.kill()
		
		danger_pulse_tween = create_tween().set_loops()
		danger_pulse_tween.tween_property(win_probability_label, "modulate:a", 0.5, 0.5)
		danger_pulse_tween.tween_property(win_probability_label, "modulate:a", 1.0, 0.5)

func _stop_danger_effects() -> void:
	# Stop pulsing
	if danger_pulse_tween:
		danger_pulse_tween.kill()
		danger_pulse_tween = null
	
	# Reset label alpha
	win_probability_label.modulate.a = 1.0
	
	# Reset container position
	var reset_tween = create_tween()
	reset_tween.tween_property(gauge_container, "position", Vector2.ZERO, 0.2)

func _update_label_color(prob: float) -> void:
	if prob < 30:
		win_probability_label.add_theme_color_override("font_color", Color.html("#e64d4d"))  # Red
	elif prob < 50:
		win_probability_label.add_theme_color_override("font_color", Color.html("#e6bc4d"))  # Yellow
	else:
		win_probability_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1.0))  # Dark grey

func _style_race_type_label() -> void:
	# Use dark grey for all race types to match the design
	var dark_text_color = Color(0.3, 0.3, 0.3, 1.0)
	race_type_label.add_theme_color_override("font_color", dark_text_color)

func _set_race_state(new_state: RaceState) -> void:
	race_state = new_state
	
	match race_state:
		RaceState.IDLE:
			_clear_result_display()
			start_race_button.disabled = false
			complete_race_button.disabled = true
			continue_to_shop_button.visible = false
		RaceState.RACING:
			_clear_result_display()
			start_race_button.disabled = true
			complete_race_button.disabled = false
			continue_to_shop_button.visible = false
		RaceState.COMPLETED:
			start_race_button.disabled = false
			complete_race_button.disabled = true
			if last_race_result.has("won") and last_race_result.won:
				continue_to_shop_button.visible = true
			else:
				continue_to_shop_button.visible = false

func _clear_result_display() -> void:
	result_label.text = ""
	result_panel.visible = false
	continue_to_shop_button.visible = false

func _show_result_display(message: String) -> void:
	result_label.text = message
	result_panel.visible = true
	result_close_button.visible = true

func _on_result_close_pressed() -> void:
	_clear_result_display()
	# If race was completed and won, show continue to shop button
	if race_state == RaceState.COMPLETED and last_race_result.has("won") and last_race_result.won:
		continue_to_shop_button.visible = true

func _on_start_race_pressed() -> void:
	if race_state == RaceState.IDLE or race_state == RaceState.COMPLETED:
		if GameManager.varsity_team.size() < 5:
			_show_result_display("❌ Cannot Start Race!\n\nYou need 5 varsity runners.\nCurrent: %d\n\nGo to Shop to recruit more runners." % GameManager.varsity_team.size())
			_set_race_state(RaceState.IDLE)
			return
		
		previous_ante = GameManager.current_ante
		_set_race_state(RaceState.RACING)
		print("Race started for Ante ", GameManager.current_ante)

func _on_complete_race_pressed() -> void:
	if race_state == RaceState.RACING:
		var completed_ante = GameManager.current_ante
		
		if GameManager.varsity_team.size() < 5:
			_show_result_display("❌ Cannot race!\n\nYou need 5 varsity runners.\nCurrent: %d" % GameManager.varsity_team.size())
			_set_race_state(RaceState.IDLE)
			return
		
		var race_result = GameManager.simulate_race()
		
		var result_message = ""
		var race_type_name = GameManager.get_race_type_name(race_result.race_type)
		result_message += "--- %s ---\n\n" % race_type_name
		
		if race_result.won:
			result_message += "✓ VICTORY!\n\n"
			GameManager.advance_ante()
			var gold_reward = GameManager.calculate_race_reward()
			GameManager.earn_gold(gold_reward)
			result_message += "Gold Earned: +%d\n\n" % gold_reward
		else:
			result_message += "✗ DEFEAT\n\n"
			GameManager.run_active = false
		
		result_message += "--- RACE RESULTS ---\n\n"
		result_message += "Total Teams: %d\n" % (race_result.team_scores.size())
		result_message += "Your Placement: %d%s\n\n" % [race_result.player_placement, _get_position_suffix(race_result.player_placement)]
		
		result_message += "Top Team Scores:\n"
		for i in range(min(3, race_result.team_scores.size())):
			var team_res = race_result.team_scores[i]
			var team_name = "Team %d" % (team_res.team_index + 1)
			if team_res.has("is_player") and team_res.is_player:
				team_name = "You"
			result_message += "  %d%s: %s (Score: %d)\n" % [i + 1, _get_position_suffix(i + 1), team_name, team_res.score]
		
		result_message += "\nYour Top 5 Finishes:\n"
		for i in range(min(5, race_result.player_positions.size())):
			var pos = race_result.player_positions[i]
			var suffix = _get_position_suffix(pos)
			result_message += "  %d%s place\n" % [pos, suffix]
		
		result_message += "\n"
		
		if race_result.won:
			result_message += "Ante %d → Ante %d\n" % [completed_ante, GameManager.current_ante]
		else:
			result_message += "Run Ended at Ante %d" % completed_ante
		
		last_race_result = race_result
		_show_result_display(result_message)
		_update_display()
		_set_race_state(RaceState.COMPLETED)
		
		# Removed auto-return to main menu - player can now view results as long as they want
		# They can manually return using the back button or ESC key

func _get_position_suffix(position: int) -> String:
	match position:
		1, 21, 31, 41, 51, 61, 71, 81, 91:
			return "st"
		2, 22, 32, 42, 52, 62, 72, 82, 92:
			return "nd"
		3, 23, 33, 43, 53, 63, 73, 83, 93:
			return "rd"
		_:
			return "th"

func _on_continue_to_shop_pressed() -> void:
	_show_loading_screen("Loading Shop...")
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/core/ShopScene.tscn")

func _on_view_team_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/core/TeamManagement.tscn")

func _show_loading_screen(message: String) -> void:
	loading_label.text = message
	loading_panel.visible = true
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	loading_panel.add_theme_stylebox_override("panel", style)

func _hide_loading_screen() -> void:
	loading_panel.visible = false

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

func _display_team_tray() -> void:
	# Clear existing team tray icons
	for child in team_tray.get_children(): child.queue_free()
	
	# Display Varsity runners (5 slots)
	for i in range(5):
		var container = VBoxContainer.new()
		container.custom_minimum_size = Vector2(120, 160)
		container.add_theme_constant_override("separation", 2)
		
		if i < GameManager.varsity_team.size():
			var runner_name = GameManager.varsity_team[i]
			var base_name = runner_name.split(":")[1].strip_edges() if ":" in runner_name else runner_name
			
			# Get runner effect for hover functionality
			var effect = GameManager.get_item_effect(runner_name, "team")
			var item_data = {"name": runner_name, "category": "team", "index": i, "is_varsity": true}
			
			# Try to load card image
			var card_texture = _get_card_texture_for_tray(runner_name, "team")
			if card_texture:
				var texture_rect = TextureRect.new()
				texture_rect.texture = card_texture
				texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				texture_rect.custom_minimum_size = Vector2(110, 140)
				texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let mouse events pass through to container
				container.add_child(texture_rect)
			
			# Add label with slot number
			var label = Label.new()
			label.text = "V%d" % [i + 1]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			label.add_theme_font_size_override("font_size", 12)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let mouse events pass through to container
			container.add_child(label)
			
			# Create tooltip
			var tooltip = _create_tooltip_text(runner_name, "team", effect, 0)  # No sell price in tray
			container.tooltip_text = tooltip
			
			# Connect hover events for stat deltas
			container.mouse_entered.connect(_on_item_hovered.bind(item_data, effect))
			container.mouse_exited.connect(_on_item_unhovered)
			
			# Connect click handler for card selection
			container.gui_input.connect(_on_team_tray_card_clicked.bind(item_data, container))
			
			_style_team_tray_container(container, true)
		else:
			# Empty slot
			var label = Label.new()
			label.text = "V%d\nEmpty" % [i + 1]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			container.add_child(label)
			_style_team_tray_container(container, true, true)
		
		team_tray.call_deferred("add_child", container)
	
	# Display JV runners (2 slots)
	for i in range(2):
		var container = VBoxContainer.new()
		container.custom_minimum_size = Vector2(120, 160)
		container.add_theme_constant_override("separation", 2)
		
		if i < GameManager.jv_team.size():
			var runner_name = GameManager.jv_team[i]
			var base_name = runner_name.split(":")[1].strip_edges() if ":" in runner_name else runner_name
			
			# Get runner effect for hover functionality
			var effect = GameManager.get_item_effect(runner_name, "team")
			var item_data = {"name": runner_name, "category": "team", "index": i, "is_varsity": false}
			
			# Try to load card image
			var card_texture = _get_card_texture_for_tray(runner_name, "team")
			if card_texture:
				var texture_rect = TextureRect.new()
				texture_rect.texture = card_texture
				texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				texture_rect.custom_minimum_size = Vector2(110, 140)
				texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let mouse events pass through to container
				container.add_child(texture_rect)
			
			# Add label with slot number
			var label = Label.new()
			label.text = "JV%d" % [i + 1]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			label.add_theme_font_size_override("font_size", 12)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let mouse events pass through to container
			container.add_child(label)
			
			# Create tooltip
			var tooltip = _create_tooltip_text(runner_name, "team", effect, 0)  # No sell price in tray
			container.tooltip_text = tooltip
			
			# Connect hover events for stat deltas
			container.mouse_entered.connect(_on_item_hovered.bind(item_data, effect))
			container.mouse_exited.connect(_on_item_unhovered)
			
			# Connect click handler for card selection
			container.gui_input.connect(_on_team_tray_card_clicked.bind(item_data, container))
			
			_style_team_tray_container(container, false)
		else:
			# Empty slot
			var label = Label.new()
			label.text = "JV%d\nEmpty" % [i + 1]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			container.add_child(label)
			_style_team_tray_container(container, false, true)
		
		team_tray.call_deferred("add_child", container)

func _style_team_tray_container(container: VBoxContainer, is_varsity: bool, is_empty: bool = false) -> void:
	# Ensure container can receive mouse events for hover
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Add a subtle background color to the container using a ColorRect
	var bg = ColorRect.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let clicks pass through
	bg.z_index = -1  # Behind other elements
	
	if is_empty:
		bg.color = Color(0.5, 0.5, 0.5, 0.2)
	else:
		if is_varsity:
			bg.color = Color(0.2, 0.5, 0.8, 0.2)  # Light blue for varsity
		else:
			bg.color = Color(0.6, 0.4, 0.8, 0.2)  # Light purple for JV
	
	# Make bg fill the container
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	container.add_child(bg)
	container.move_child(bg, 0)  # Move to back

func _display_inventory() -> void:
	# Clear existing items
	for child in deck_grid.get_children(): child.queue_free()
	for child in boosts_container.get_children(): child.queue_free()
	for child in equipment_container.get_children(): child.queue_free()

	# Display Deck Items in Grid (4 columns)
	for i in range(GameManager.deck.size()):
		var item_name = GameManager.deck[i]
		var item_data = {"name": item_name, "category": "deck", "index": i}
		var button = _create_inventory_item_button(item_data)
		deck_grid.call_deferred("add_child", button)

	# Display Boosts
	for i in range(GameManager.jokers.size()):
		var item_name = GameManager.jokers[i]
		var item_data = {"name": item_name, "category": "boosts", "index": i}
		var button = _create_inventory_item_button(item_data)
		boosts_container.call_deferred("add_child", button)

	# Display Equipment
	for i in range(GameManager.shop_inventory.size()):
		var item_name = GameManager.shop_inventory[i]
		var item_data = {"name": item_name, "category": "equipment", "index": i}
		var button = _create_inventory_item_button(item_data)
		equipment_container.call_deferred("add_child", button)

func _create_inventory_item_button(item_data: Dictionary) -> Button:
	var button = Button.new()
	var item_name = item_data.name
	var category = item_data.category
	var index = item_data.index
	var is_varsity = item_data.get("is_varsity", false)

	var effect = GameManager.get_item_effect(item_name, category)
	var effect_text = _format_effect_text(effect)
	var sell_price = _get_sell_price(item_name, category)

	var prefix = ""
	if category == "team":
		prefix = "V%d: " % (index + 1) if is_varsity else "JV%d: " % (index + 1)
	
	# Get icon for category
	var icon = _get_category_icon(category)
	button.text = "%s%s\n%s\n💰 Sell: %d" % [icon, prefix, item_name.split(":")[1] if ":" in item_name else item_name, sell_price]
	button.custom_minimum_size = Vector2(120, 100)
	
	# Create tooltip
	var tooltip = _create_tooltip_text(item_name, category, effect, sell_price)
	button.tooltip_text = tooltip
	
	# Connect hover events for enhanced tooltip
	button.mouse_entered.connect(_on_item_hovered.bind(item_data, effect))
	button.mouse_exited.connect(_on_item_unhovered)
	
	# Connect click to sell
	button.pressed.connect(_on_sell_item_pressed.bind(item_data))
	
	# Disable sell button for varsity runners if team size is 5
	if category == "team" and is_varsity and GameManager.varsity_team.size() <= 5:
		button.disabled = true
		button.tooltip_text += "\n\n⚠️ Cannot sell: Must have at least 5 varsity runners."
	
	_style_item_button(button, category)
	return button

func _get_category_icon(category: String) -> String:
	match category:
		"team": return "🏃 "
		"deck": return "🃏 "
		"boosts": return "⚡ "
		"equipment": return "🎒 "
	return ""

func _create_tooltip_text(item_name: String, category: String, effect: Dictionary, sell_price: int) -> String:
	var tooltip = item_name + "\n"
	tooltip += "Category: %s\n" % category.capitalize()
	tooltip += "\nEffects:\n"
	
	if effect.speed != 0:
		tooltip += "  Speed: %+d\n" % effect.speed
	if effect.endurance != 0:
		tooltip += "  Endurance: %+d\n" % effect.endurance
	if effect.stamina != 0:
		tooltip += "  Stamina: %+d\n" % effect.stamina
	if effect.power != 0:
		tooltip += "  Power: %+d\n" % effect.power
	if effect.multiplier > 1.0:
		var percent = int((effect.multiplier - 1.0) * 100)
		tooltip += "  Multiplier: +%d%%\n" % percent
	
	if sell_price > 0:
		tooltip += "\nSell Price: %d Gold" % sell_price
	return tooltip

func _on_item_hovered(item_data: Dictionary, effect: Dictionary) -> void:
	hovered_item = item_data
	# Show stat deltas in main stats
	_show_stat_deltas(effect)

func _on_item_unhovered() -> void:
	hovered_item = {}
	_hide_stat_deltas()

func _on_team_tray_card_clicked(event: InputEvent, item_data: Dictionary, container: VBoxContainer) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_select_team_card(container, item_data)

func _select_team_card(container: VBoxContainer, item_data: Dictionary) -> void:
	# TODO: Implement full selection logic in Step 3
	# For now, just store the selection
	selected_team_card = container
	selected_team_card_data = item_data
	print("Selected card: ", item_data)

func _show_stat_deltas(effect: Dictionary) -> void:
	# Update stat labels to show potential changes
	var speed = GameManager.get_total_speed()
	var endurance = GameManager.get_total_endurance()
	var stamina = GameManager.get_total_stamina()
	var power = GameManager.get_total_power()
	
	if effect.speed != 0:
		speed_label.text = "⚡ Speed: %d (%+d)" % [speed, effect.speed]
		speed_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3) if effect.speed > 0 else Color(0.8, 0.3, 0.3))
	if effect.endurance != 0:
		endurance_label.text = "🏔️ Endurance: %d (%+d)" % [endurance, effect.endurance]
		endurance_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3) if effect.endurance > 0 else Color(0.8, 0.3, 0.3))
	if effect.stamina != 0:
		stamina_label.text = "💪 Stamina: %d (%+d)" % [stamina, effect.stamina]
		stamina_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3) if effect.stamina > 0 else Color(0.8, 0.3, 0.3))
	if effect.power != 0:
		power_label.text = "🔥 Power: %d (%+d)" % [power, effect.power]
		power_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3) if effect.power > 0 else Color(0.8, 0.3, 0.3))

func _hide_stat_deltas() -> void:
	# Restore normal stat labels with dark grey text
	var dark_text_color = Color(0.3, 0.3, 0.3, 1.0)
	speed_label.add_theme_color_override("font_color", dark_text_color)
	endurance_label.add_theme_color_override("font_color", dark_text_color)
	stamina_label.add_theme_color_override("font_color", dark_text_color)
	power_label.add_theme_color_override("font_color", dark_text_color)
	# Then update the display to refresh the text
	_update_display()

func _format_effect_text(effect: Dictionary) -> String:
	var parts: Array[String] = []
	if effect.speed != 0: parts.append("Spd:%+d" % effect.speed)
	if effect.endurance != 0: parts.append("End:%+d" % effect.endurance)
	if effect.stamina != 0: parts.append("Sta:%+d" % effect.stamina)
	if effect.power != 0: parts.append("Pow:%+d" % effect.power)
	if effect.multiplier > 1.0:
		var percent = int((effect.multiplier - 1.0) * 100)
		parts.append("x%d%%" % percent)
	return ", ".join(parts) if not parts.is_empty() else "No effect"

func _get_sell_price(item_name: String, category: String) -> int:
	var base_price = 0
	match category:
		"team": base_price = 40
		"deck": base_price = 20
		"boosts": base_price = 50
		"equipment": base_price = 30
	return int(base_price * 0.5)

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
			style_normal.bg_color = Color(0.3, 0.5, 0.8, 0.7)
			style_hover.bg_color = Color(0.3, 0.5, 0.8, 0.95)
			style_pressed.bg_color = Color(0.2, 0.4, 0.7, 0.9)
			button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		"deck":
			style_normal.bg_color = Color(0.4, 0.7, 0.4, 0.7)
			style_hover.bg_color = Color(0.4, 0.7, 0.4, 0.95)
			style_pressed.bg_color = Color(0.3, 0.6, 0.3, 0.9)
			button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		"boosts":
			style_normal.bg_color = Color(0.7, 0.4, 0.8, 0.7)
			style_hover.bg_color = Color(0.7, 0.4, 0.8, 0.95)
			style_pressed.bg_color = Color(0.6, 0.3, 0.7, 0.9)
			button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		"equipment":
			style_normal.bg_color = Color(0.9, 0.6, 0.3, 0.7)
			style_hover.bg_color = Color(0.9, 0.6, 0.3, 0.95)
			style_pressed.bg_color = Color(0.8, 0.5, 0.2, 0.9)
			button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	
	# Add hover animation
	var hover_tween: Tween = null
	button.mouse_entered.connect(func():
		if hover_tween:
			hover_tween.kill()
		hover_tween = create_tween()
		hover_tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	)
	button.mouse_exited.connect(func():
		if hover_tween:
			hover_tween.kill()
		hover_tween = create_tween()
		hover_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
	)

func _on_sell_item_pressed(item_data: Dictionary) -> void:
	var item_name = item_data.name
	var category = item_data.category
	var index = item_data.index
	var is_varsity = item_data.get("is_varsity", false)
	var sell_price = _get_sell_price(item_name, category)
	
	# Special check for varsity runners
	if category == "team" and is_varsity and GameManager.varsity_team.size() <= 5:
		_show_purchase_feedback("⚠️ Cannot sell: Need at least 5 varsity runners!", false)
		return
	
	var sold_successfully = false
	match category:
		"team":
			if is_varsity:
				if GameManager.varsity_team.size() > 5:
					GameManager.remove_varsity_runner(index)
					sold_successfully = true
			else:
				GameManager.remove_jv_runner(index)
				sold_successfully = true
		"deck":
			GameManager.deck.remove_at(index)
			sold_successfully = true
		"boosts":
			GameManager.jokers.remove_at(index)
			sold_successfully = true
		"equipment":
			GameManager.shop_inventory.remove_at(index)
			sold_successfully = true
	
	if sold_successfully:
		GameManager.earn_gold(sell_price)
		_show_purchase_feedback("✓ Sold for %d Gold!" % sell_price, true)
		_update_display()
		# Update win probability with animation after selling
		var new_prob = _calculate_win_probability()
		update_probability_display(new_prob)
	else:
		_show_purchase_feedback("❌ Failed to sell item", false)

func _show_purchase_feedback(message: String, is_success: bool) -> void:
	purchase_feedback_label.text = message
	purchase_feedback_label.visible = true
	if is_success:
		purchase_feedback_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	else:
		purchase_feedback_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	
	# Animate fade in/out
	var tween = create_tween()
	tween.tween_property(purchase_feedback_label, "modulate:a", 1.0, 0.2)
	await get_tree().create_timer(1.5).timeout
	tween = create_tween()
	tween.tween_property(purchase_feedback_label, "modulate:a", 0.0, 0.3)
	await tween.finished
	purchase_feedback_label.visible = false
	purchase_feedback_label.modulate.a = 1.0
