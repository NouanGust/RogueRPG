class_name AchievementsPanel
extends Control

signal closed

@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var list_container: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/AchievementsList
@onready var close_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
	hide()
	if close_button:
		close_button.pressed.connect(close_panel)

func open_panel() -> void:
	refresh()
	show()
	if close_button != null:
		close_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_panel()
		get_viewport().set_input_as_handled()

func close_panel() -> void:
	if AudioManager.has_method("play_ui_cancel"):
		AudioManager.play_ui_cancel()
	hide()
	closed.emit()

func refresh() -> void:
	if list_container == null:
		return
	for child in list_container.get_children():
		child.queue_free()

	var summary := AchievementManager.get_progress_summary()
	if title_label:
		title_label.text = "CONQUISTAS (%d / %d)" % [int(summary.get("unlocked", 0)), int(summary.get("total", 0))]

	for ach in AchievementManager.get_all_achievements():
		list_container.add_child(_build_card(ach))

func _build_card(ach: AchievementData) -> PanelContainer:
	var unlocked := AchievementManager.is_unlocked(ach.id)
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.content_margin_left = 14.0
	style.content_margin_top = 10.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 10.0
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	if unlocked:
		style.bg_color = Color(0.16, 0.24, 0.14, 0.94)
		style.border_color = Color(0.95, 0.78, 0.3, 1.0)
	else:
		style.bg_color = Color(0.1, 0.11, 0.15, 0.9)
		style.border_color = Color(0.36, 0.36, 0.42, 0.85)
	card.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	card.add_child(hbox)

	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(58, 58)
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = Color(0.08, 0.1, 0.12, 0.9) if unlocked else Color(0.05, 0.05, 0.08, 0.95)
	icon_style.border_color = Color(0.95, 0.78, 0.3, 0.9) if unlocked else Color(0.28, 0.28, 0.34, 0.8)
	icon_style.border_width_left = 1
	icon_style.border_width_top = 1
	icon_style.border_width_right = 1
	icon_style.border_width_bottom = 1
	icon_style.corner_radius_top_left = 6
	icon_style.corner_radius_top_right = 6
	icon_style.corner_radius_bottom_right = 6
	icon_style.corner_radius_bottom_left = 6
	icon_style.content_margin_left = 4.0
	icon_style.content_margin_top = 4.0
	icon_style.content_margin_right = 4.0
	icon_style.content_margin_bottom = 4.0
	icon_frame.add_theme_stylebox_override("panel", icon_style)
	hbox.add_child(icon_frame)

	var icon_rect := TextureRect.new()
	icon_rect.texture = ach.icon
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.modulate = Color(1.0, 1.0, 1.0, 1.0) if unlocked else Color(0.04, 0.04, 0.06, 0.95)
	icon_frame.add_child(icon_rect)

	var name_lbl := Label.new()
	name_lbl.text = ach.title
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0) if unlocked else Color(0.7, 0.72, 0.76, 1.0))
	hbox.add_child(name_lbl)

	var status_lbl := Label.new()
	status_lbl.text = "CONCLUÍDA" if unlocked else "BLOQUEADA"
	status_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status_lbl.add_theme_font_size_override("font_size", 13)
	status_lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.58, 1.0) if unlocked else Color(0.55, 0.55, 0.6, 1.0))
	hbox.add_child(status_lbl)

	return card
