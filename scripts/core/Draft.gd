extends Control

# Draft scene - displays draft candidates and allows player to select one

@onready var division_label: Label = %DivisionLabel
@onready var ante_label: Label = %AnteLabel
@onready var instructions_label: Label = %InstructionsLabel
@onready var candidates_container: GridContainer = %CandidatesContainer
@onready var selected_candidate_panel: PanelContainer = %SelectedCandidatePanel
@onready var selected_name_label: Label = %SelectedNameLabel
@onready var selected_tier_label: Label = %SelectedTierLabel
@onready var selected_stats_label: Label = %SelectedStatsLabel
@onready var selected_growth_label: Label = %SelectedGrowthLabel
@onready var selected_description_label: Label = %SelectedDescriptionLabel
@onready var team_preview_label: Label = %TeamPreviewLabel
@onready var select_button: Button = %SelectButton
@onready var skip_button: Button = %SkipButton

# Draft state
var draft_candidates: Array[Runner] = []
var selected_candidate: Runner = null
var selected_runners: Array[Runner] = []  # Track all selected runners
var max_selections: int = 7  # 5 varsity + 2 JV

# Store starting team to restore if skipped
var starting_team_backup: Array[String] = []

func _ready() -> void:
	select_button.pressed.connect(_on_select_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	
	# Backup starting team if this is the initial draft (before first race)
	# This allows us to restore it if player skips
	if GameManager.current_ante == 1 and not GameManager.draft_completed:
		# Create typed array copy
		starting_team_backup.clear()
		for runner in GameManager.varsity_team:
			starting_team_backup.append(runner)
		GameManager.varsity_team.clear()
		GameManager.jv_team.clear()
		print("Cleared starting team for draft (backed up %d runners)" % starting_team_backup.size())
	
	_update_header()
	_generate_draft_candidates()
	
	# Wait for frame to ensure UI is fully ready
	await get_tree().process_frame
	_display_candidates()
	_update_team_preview()
	_update_selection_display()

func _update_header() -> void:
	division_label.text = "Division: %s" % GameManager.DIVISION_DATA[GameManager.current_division].get("name", "Unknown")
	ante_label.text = "Ante: %d" % GameManager.current_ante
	var remaining = max_selections - selected_runners.size()
	instructions_label.text = "Select up to %d runners for your team (%d remaining). Click 'Finish Draft' when done." % [max_selections, remaining]

func _generate_draft_candidates() -> void:
	# Use current division and seed for deterministic generation
	var draft_seed = GameManager.seed + GameManager.current_ante * 1000
	print("Generating draft candidates for division: ", GameManager.current_division, " with seed: ", draft_seed)
	draft_candidates = DraftManager.generate_candidates(
		GameManager.current_division,
		draft_seed
	)
	print("Generated %d draft candidates" % draft_candidates.size())
	if draft_candidates.is_empty():
		print("ERROR: No draft candidates generated! Check DraftManager.generate_candidates()")
	else:
		for i in range(draft_candidates.size()):
			var candidate = draft_candidates[i]
			print("  Candidate %d: %s (tier: %s)" % [i + 1, candidate.name, candidate.draft_tier])

func _display_candidates() -> void:
	# Clear existing candidates
	_clear_candidates()
	
	print("Displaying %d candidates in container" % draft_candidates.size())
	print("Container size flags: h=%d, v=%d" % [candidates_container.size_flags_horizontal, candidates_container.size_flags_vertical])
	
	# Display each candidate in a grid
	for candidate in draft_candidates:
		var candidate_card = _create_candidate_card(candidate)
		candidates_container.add_child(candidate_card)
		print("  Added card for: %s (size: %s)" % [candidate.name, candidate_card.custom_minimum_size])
	
	print("Total children in container: %d" % candidates_container.get_child_count())
	print("Container actual size: %s" % candidates_container.size)
	print("Container position: %s" % candidates_container.position)

func _create_candidate_card(candidate: Runner) -> Control:
	# Create panel for styling (outermost container)
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	style.border_color = Color(0.5, 0.5, 0.5, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", style)
	# Smaller card size to fit 5 across
	panel.custom_minimum_size = Vector2(180, 350)
	
	# Store candidate reference in metadata for later retrieval
	panel.set_meta("candidate", candidate)
	
	# Create margin container (smaller margins for compact layout)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	
	# Create main card container
	var card_container = VBoxContainer.new()
	card_container.add_theme_constant_override("separation", 4)
	card_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	margin.add_child(card_container)
	panel.add_child(margin)
	
	# Tier badge (colored header) - smaller font
	var tier_label = Label.new()
	tier_label.text = DraftManager.get_tier_display_name(candidate.draft_tier)
	var tier_color = DraftManager.get_tier_color(candidate.draft_tier)
	tier_label.add_theme_color_override("font_color", tier_color)
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.add_theme_font_size_override("font_size", 14)
	card_container.add_child(tier_label)
	
	# Runner name - smaller font, truncate if needed
	var name_label = Label.new()
	name_label.text = candidate.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.clip_contents = true
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_container.add_child(name_label)
	
	# Separator
	var separator = HSeparator.new()
	card_container.add_child(separator)
	
	# Stats display - more compact format
	var stats_label = Label.new()
	var stats = candidate.get_display_stats()
	stats_label.text = "Spd: %d\nEnd: %d\nSta: %d\nPow: %d" % [
		stats.current.speed,
		stats.current.endurance,
		stats.current.stamina,
		stats.current.power
	]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 12)
	card_container.add_child(stats_label)
	
	# Growth potential indicator - smaller
	var growth_label = Label.new()
	var growth_score = candidate.get_growth_score()
	growth_label.text = "Growth: %.1fx" % growth_score
	growth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	growth_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	growth_label.add_theme_font_size_override("font_size", 11)
	card_container.add_child(growth_label)
	
	# Tier description - smaller, more compact
	var desc_label = Label.new()
	desc_label.text = DraftManager.get_tier_description(candidate.draft_tier)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(160, 0)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 10)
	card_container.add_child(desc_label)
	
	# Select button - smaller (directly adds to selection)
	var select_btn = Button.new()
	select_btn.text = "Select"
	select_btn.custom_minimum_size = Vector2(0, 32)
	select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select_btn.add_theme_font_size_override("font_size", 12)
	select_btn.pressed.connect(_on_card_select_pressed.bind(candidate))
	card_container.add_child(select_btn)
	
	# Ensure panel can receive mouse input
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Make panel clickable to show preview
	panel.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_candidate_selected(candidate)
	)
	
	return panel

func _on_candidate_selected(candidate: Runner) -> void:
	# Just highlight and show info (for hover/click preview)
	selected_candidate = candidate
	_update_selection_display()
	_update_card_highlights()

func _on_card_select_pressed(candidate: Runner) -> void:
	# Directly add to selection when clicking card button
	if selected_runners.has(candidate):
		_show_selection_feedback("Already selected!", true)
		return
	
	if selected_runners.size() >= max_selections:
		_show_selection_feedback("Maximum %d runners selected!" % max_selections, true)
		return
	
	# Add to selected list
	selected_runners.append(candidate)
	
	# Update UI
	_update_header()
	_update_team_preview()
	_update_card_highlights()
	
	# Show success feedback
	_show_selection_feedback("✓ Selected %s (%d/%d)" % [candidate.name, selected_runners.size(), max_selections])
	
	# Clear current selection preview
	selected_candidate = null
	_update_selection_display()

func _update_card_highlights() -> void:
	# Update visual state of all cards
	for child in candidates_container.get_children():
		if child is PanelContainer:
			var panel = child as PanelContainer
			var style = panel.get_theme_stylebox("panel", "PanelContainer")
			if style is StyleBoxFlat:
				var card_candidate = panel.get_meta("candidate", null)
				var is_selected = selected_runners.has(card_candidate)
				var is_currently_selected = selected_candidate != null and card_candidate == selected_candidate
				
				if is_selected:
					# Highlight already selected (green)
					style.border_color = Color(0.3, 0.9, 0.3, 1.0)
					style.border_width_left = 4
					style.border_width_top = 4
					style.border_width_right = 4
					style.border_width_bottom = 4
				elif is_currently_selected:
					# Highlight currently selected (yellow)
					style.border_color = Color(1.0, 0.8, 0.0, 1.0)
					style.border_width_left = 4
					style.border_width_top = 4
					style.border_width_right = 4
					style.border_width_bottom = 4
				else:
					# Normal border
					style.border_color = Color(0.5, 0.5, 0.5, 1.0)
					style.border_width_left = 2
					style.border_width_top = 2
					style.border_width_right = 2
					style.border_width_bottom = 2

func _update_selection_display() -> void:
	# Update main select button based on selections
	if selected_runners.size() > 0:
		select_button.text = "Finish Draft (%d/%d)" % [selected_runners.size(), max_selections]
		select_button.disabled = false
	else:
		select_button.text = "Select Runner"
		select_button.disabled = true
	
	if selected_candidate == null:
		selected_candidate_panel.visible = false
		return
	
	selected_candidate_panel.visible = true
	
	# Check if already selected
	var already_selected = selected_runners.has(selected_candidate)
	if already_selected:
		select_button.text = "Already Selected"
		select_button.disabled = true
	elif selected_runners.size() >= max_selections:
		select_button.text = "Maximum Reached"
		select_button.disabled = true
	else:
		select_button.text = "Select Runner"
		select_button.disabled = false
	
	# Update selected candidate info
	selected_name_label.text = selected_candidate.name
	selected_tier_label.text = DraftManager.get_tier_display_name(selected_candidate.draft_tier)
	var tier_color = DraftManager.get_tier_color(selected_candidate.draft_tier)
	selected_tier_label.add_theme_color_override("font_color", tier_color)
	
	var stats = selected_candidate.get_display_stats()
	selected_stats_label.text = "Speed: %d | Endurance: %d | Stamina: %d | Power: %d" % [
		stats.current.speed,
		stats.current.endurance,
		stats.current.stamina,
		stats.current.power
	]
	
	var growth_score = selected_candidate.get_growth_score()
	selected_growth_label.text = "Growth Potential: %.1fx average" % growth_score
	
	selected_description_label.text = DraftManager.get_tier_description(selected_candidate.draft_tier)

func _update_team_preview() -> void:
	var team_size = GameManager.get_team_size()
	var varsity_count = team_size.varsity + selected_runners.size()  # Preview with selected
	var jv_count = team_size.jv
	var preview_text = "Draft Selections: %d/%d selected" % [selected_runners.size(), max_selections]
	
	if selected_runners.size() > 0:
		preview_text += "\nSelected: "
		var names = []
		for runner in selected_runners:
			names.append(runner.name)
		preview_text += ", ".join(names)
	
	team_preview_label.text = preview_text

func _on_select_pressed() -> void:
	# Finish draft button - add all selected runners to team and continue
	if selected_runners.size() == 0:
		_show_selection_feedback("Select at least one runner, or click Skip to continue without drafting.", true)
		return
	
	_finish_draft()

func _on_skip_pressed() -> void:
	# Skip draft - finish with whatever has been selected (or restore starting team)
	if selected_runners.size() > 0:
		_finish_draft()
	else:
		# No selections - restore starting team if we have a backup
		if starting_team_backup.size() > 0:
			GameManager.varsity_team.clear()
			for runner in starting_team_backup:
				GameManager.varsity_team.append(runner)
			print("Restored starting team (%d runners)" % GameManager.varsity_team.size())
		# Mark draft as completed so it doesn't show again
		GameManager.draft_completed = true
		print("Draft skipped! draft_completed flag set to: %s" % GameManager.draft_completed)
		_continue_after_draft()

func _finish_draft() -> void:
	# Add all selected runners to team (varsity first, then JV)
	var team_size = GameManager.get_team_size()
	
	for runner in selected_runners:
		var runner_string = runner.display_name
		if team_size.varsity < 5:
			if GameManager.add_varsity_runner(runner_string):
				team_size.varsity += 1
				print("Added %s to varsity" % runner.name)
		elif team_size.jv < 2:
			if GameManager.add_jv_runner(runner_string):
				team_size.jv += 1
				print("Added %s to JV" % runner.name)
		else:
			print("Warning: Could not add %s - team is full" % runner.name)
	
	# Mark draft as completed so it doesn't show again
	GameManager.draft_completed = true
	print("Draft completed! draft_completed flag set to: %s" % GameManager.draft_completed)
	
	# Transition directly to Run scene
	_continue_after_draft()

func _continue_after_draft() -> void:
	# Transition directly to Run scene (draft → game flow)
	get_tree().change_scene_to_file("res://scenes/run/Run.tscn")

func _clear_candidates() -> void:
	for child in candidates_container.get_children():
		child.queue_free()

func _show_selection_feedback(message: String, is_error: bool = false) -> void:
	# Create a temporary feedback label
	var feedback = Label.new()
	feedback.text = message
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.add_theme_font_size_override("font_size", 20)
	if is_error:
		feedback.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		feedback.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	
	feedback.anchors_preset = Control.PRESET_CENTER
	feedback.position = Vector2(-150, -50)
	feedback.size = Vector2(300, 100)
	add_child(feedback)
	
	# Animate and remove
	var tween = create_tween()
	tween.tween_property(feedback, "modulate:a", 0.0, 0.5)
	tween.tween_callback(feedback.queue_free)
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(feedback):
		feedback.queue_free()
