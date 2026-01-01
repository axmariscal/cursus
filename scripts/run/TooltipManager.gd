extends Node
class_name TooltipManager

# Tooltip system and hover handling

var hovered_item: Dictionary = {}

func create_tooltip_text(item_name: String, category: String, effect: Dictionary, sell_price: int) -> String:
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

func on_item_hovered(item_data: Dictionary, effect: Dictionary, stat_labels: Dictionary, stat_deltas: Dictionary) -> void:
	hovered_item = item_data
	show_stat_deltas(effect, stat_labels, stat_deltas)

func on_item_unhovered(stat_labels: Dictionary, stat_deltas: Dictionary) -> void:
	hovered_item = {}
	hide_stat_deltas(stat_labels, stat_deltas)

func show_stat_deltas(effect: Dictionary, stat_labels: Dictionary, stat_deltas: Dictionary) -> void:
	# Update stat labels to show potential changes
	var speed = GameManager.get_total_speed()
	var endurance = GameManager.get_total_endurance()
	var stamina = GameManager.get_total_stamina()
	var power = GameManager.get_total_power()
	
	if effect.speed != 0 and stat_labels.has("speed"):
		stat_labels.speed.text = "⚡ Speed: %d (%+d)" % [speed, effect.speed]
		stat_labels.speed.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3) if effect.speed > 0 else Color(0.8, 0.3, 0.3))
	if effect.endurance != 0 and stat_labels.has("endurance"):
		stat_labels.endurance.text = "🏔️ Endurance: %d (%+d)" % [endurance, effect.endurance]
		stat_labels.endurance.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3) if effect.endurance > 0 else Color(0.8, 0.3, 0.3))
	if effect.stamina != 0 and stat_labels.has("stamina"):
		stat_labels.stamina.text = "💪 Stamina: %d (%+d)" % [stamina, effect.stamina]
		stat_labels.stamina.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3) if effect.stamina > 0 else Color(0.8, 0.3, 0.3))
	if effect.power != 0 and stat_labels.has("power"):
		stat_labels.power.text = "🔥 Power: %d (%+d)" % [power, effect.power]
		stat_labels.power.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3) if effect.power > 0 else Color(0.8, 0.3, 0.3))

func hide_stat_deltas(stat_labels: Dictionary, stat_deltas: Dictionary) -> void:
	# Restore normal stat labels with dark grey text
	var dark_text_color = Color(0.3, 0.3, 0.3, 1.0)
	
	if stat_labels.has("speed"):
		stat_labels.speed.add_theme_color_override("font_color", dark_text_color)
		stat_labels.speed.text = "Speed: %d" % GameManager.get_total_speed()
	if stat_labels.has("endurance"):
		stat_labels.endurance.add_theme_color_override("font_color", dark_text_color)
		stat_labels.endurance.text = "Endurance: %d" % GameManager.get_total_endurance()
	if stat_labels.has("stamina"):
		stat_labels.stamina.add_theme_color_override("font_color", dark_text_color)
		stat_labels.stamina.text = "Stamina: %d" % GameManager.get_total_stamina()
	if stat_labels.has("power"):
		stat_labels.power.add_theme_color_override("font_color", dark_text_color)
		stat_labels.power.text = "Power: %d" % GameManager.get_total_power()

func format_effect_text(effect: Dictionary) -> String:
	var parts: Array[String] = []
	if effect.speed != 0: parts.append("Spd:%+d" % effect.speed)
	if effect.endurance != 0: parts.append("End:%+d" % effect.endurance)
	if effect.stamina != 0: parts.append("Sta:%+d" % effect.stamina)
	if effect.power != 0: parts.append("Pow:%+d" % effect.power)
	if effect.multiplier > 1.0:
		var percent = int((effect.multiplier - 1.0) * 100)
		parts.append("x%d%%" % percent)
	return ", ".join(parts) if not parts.is_empty() else "No effect"

