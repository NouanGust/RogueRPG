extends Node

signal input_mode_changed(is_keyboard: bool)

const KEY_SHEET: Texture2D = preload("res://Assets/2D/SimpleUI_Keyboard_thin_v2/SimpleUI_Keyboard_Thin_Unclicked.png")
const ADVENTURE_THEME: Theme = preload("res://Scenes/ui/adventure_theme.tres")
const CELL_SIZE := 18

const KEY_GRID := {
	"1": Vector2i(0, 0), "2": Vector2i(1, 0), "3": Vector2i(2, 0), "4": Vector2i(3, 0),
	"5": Vector2i(4, 0), "6": Vector2i(5, 0), "7": Vector2i(6, 0), "8": Vector2i(7, 0),
	"9": Vector2i(8, 0), "0": Vector2i(9, 0), "RETURN": Vector2i(12, 0),
	"A": Vector2i(0, 2), "B": Vector2i(1, 2), "C": Vector2i(2, 2), "D": Vector2i(3, 2),
	"E": Vector2i(4, 2), "F": Vector2i(5, 2), "G": Vector2i(6, 2), "H": Vector2i(7, 2),
	"I": Vector2i(8, 2), "J": Vector2i(9, 2), "K": Vector2i(10, 2), "L": Vector2i(11, 2),
	"M": Vector2i(12, 2),
	"N": Vector2i(0, 3), "O": Vector2i(1, 3), "P": Vector2i(2, 3), "Q": Vector2i(3, 3),
	"R": Vector2i(4, 3), "S": Vector2i(5, 3), "T": Vector2i(6, 3), "U": Vector2i(7, 3),
	"V": Vector2i(8, 3), "W": Vector2i(9, 3), "X": Vector2i(10, 3), "Y": Vector2i(11, 3),
	"Z": Vector2i(12, 3),
	"ESC": Vector2i(2, 4),
	"DOWN": Vector2i(8, 5), "UP": Vector2i(9, 5), "LEFT": Vector2i(10, 5), "RIGHT": Vector2i(11, 5),
	"ENTER": Vector2i(5, 6), "SPACE": Vector2i(7, 6),
}

var _keyboard_mode: bool = false
var _tooltip_layer: CanvasLayer
var _tooltip_panel: PanelContainer
var _tooltip_label: Label
var _tracked_focus: Control = null
var _key_tex_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_keyboard_tooltip()
	get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)

func _build_keyboard_tooltip() -> void:
	_tooltip_layer = CanvasLayer.new()
	_tooltip_layer.layer = 120
	add_child(_tooltip_layer)

	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.theme = ADVENTURE_THEME
	_tooltip_panel.theme_type_variation = &"TooltipPanel"
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ADVENTURE_THEME.has_stylebox("panel", "TooltipPanel"):
		_tooltip_panel.add_theme_stylebox_override("panel", ADVENTURE_THEME.get_stylebox("panel", "TooltipPanel"))
	_tooltip_panel.hide()
	_tooltip_layer.add_child(_tooltip_panel)

	_tooltip_label = Label.new()
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_label.custom_minimum_size = Vector2(180, 0)
	_tooltip_label.add_theme_font_size_override("font_size", 14)
	_tooltip_label.add_theme_color_override("font_color", Color(0.97, 0.94, 0.86, 1.0))
	_tooltip_panel.add_child(_tooltip_label)

func _process(_delta: float) -> void:
	if not _tooltip_panel.visible:
		return
	if not _keyboard_mode or _tracked_focus == null or not is_instance_valid(_tracked_focus) or not _tracked_focus.is_visible_in_tree():
		_hide_tooltip()
		return
	if _tracked_focus.tooltip_text.strip_edges().is_empty():
		_hide_tooltip()
		return
	_position_tooltip(_tracked_focus)

func is_keyboard_mode() -> bool:
	return _keyboard_mode

func _set_keyboard_mode(enabled: bool) -> void:
	if _keyboard_mode == enabled:
		return
	_keyboard_mode = enabled
	input_mode_changed.emit(_keyboard_mode)
	if not _keyboard_mode:
		_hide_tooltip()
		call_deferred("_release_non_text_focus")
	else:
		var owner := get_viewport().gui_get_focus_owner()
		if owner != null:
			_show_tooltip_for(owner)

func _release_non_text_focus() -> void:
	if _keyboard_mode:
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	var owner := viewport.gui_get_focus_owner()
	if owner != null and is_instance_valid(owner) and not (owner is LineEdit or owner is TextEdit):
		owner.release_focus()

func get_key_texture(key_name: String) -> AtlasTexture:
	var upper := key_name.to_upper().strip_edges()
	if _key_tex_cache.has(upper):
		return _key_tex_cache[upper]
	var cell: Vector2i = KEY_GRID.get(upper, Vector2i(5, 6))
	var atlas := AtlasTexture.new()
	atlas.atlas = KEY_SHEET
	atlas.region = Rect2(cell.x * CELL_SIZE, cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
	_key_tex_cache[upper] = atlas
	return atlas

func attach_key_hint(control: Control, key_name: String) -> TextureRect:
	if control == null:
		return null
	var existing := control.get_node_or_null("KeyHintIcon") as TextureRect
	if existing != null:
		existing.texture = get_key_texture(key_name)
		existing.visible = _keyboard_mode
		return existing

	var icon := TextureRect.new()
	icon.name = "KeyHintIcon"
	icon.texture = get_key_texture(key_name)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(22, 22)
	icon.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	icon.offset_left = -18.0
	icon.offset_right = 4.0
	icon.offset_top = -8.0
	icon.offset_bottom = 14.0
	icon.visible = _keyboard_mode
	control.add_child(icon)
	input_mode_changed.connect(func(kb: bool):
		if is_instance_valid(icon):
			icon.visible = kb)
	return icon

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		_set_keyboard_mode(false)
		if not mb.pressed:
			call_deferred("_release_non_text_focus")
		return
	if event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length_squared() > 9.0:
		_set_keyboard_mode(false)
		return

	if not (event is InputEventKey and event.pressed):
		return

	_set_keyboard_mode(true)

	var is_nav := (
		event.is_action_pressed("ui_up")
		or event.is_action_pressed("ui_down")
		or event.is_action_pressed("ui_left")
		or event.is_action_pressed("ui_right")
		or event.is_action_pressed("ui_focus_next")
		or event.is_action_pressed("ui_focus_prev")
	)
	var is_accept := event.is_action_pressed("ui_accept")

	if not is_nav and not is_accept:
		return

	var viewport := get_viewport()
	if viewport == null:
		return
	var owner := viewport.gui_get_focus_owner()
	if owner is LineEdit or owner is TextEdit:
		return

	var owner_valid = (
		owner != null
		and is_instance_valid(owner)
		and owner.is_visible_in_tree()
		and not (owner is BaseButton and owner.disabled)
	)

	if not owner_valid:
		var target := find_best_focus_target()
		if target != null:
			target.grab_focus()
			viewport.set_input_as_handled()

func _on_gui_focus_changed(control: Control) -> void:
	_tracked_focus = control
	if not _keyboard_mode or control == null:
		_hide_tooltip()
		return
	if control is BaseButton or control is Range:
		if AudioManager != null and AudioManager.has_method("play_ui_hover"):
			AudioManager.play_ui_hover()
	_show_tooltip_for(control)

func _show_tooltip_for(control: Control) -> void:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
		_hide_tooltip()
		return
	var tip := control.tooltip_text.strip_edges()
	if tip.is_empty():
		_hide_tooltip()
		return
	_tooltip_label.text = tip
	_tooltip_panel.reset_size()
	_tooltip_panel.show()
	_position_tooltip(control)

func _position_tooltip(control: Control) -> void:
	var rect := control.get_global_rect()
	var vp_size := get_viewport().get_visible_rect().size
	var tip_size := _tooltip_panel.get_combined_minimum_size()
	var pos := Vector2(rect.position.x + (rect.size.x - tip_size.x) * 0.5, rect.position.y - tip_size.y - 10.0)
	if pos.y < 12.0:
		pos.y = rect.end.y + 10.0
	pos.x = clampf(pos.x, 12.0, maxf(12.0, vp_size.x - tip_size.x - 12.0))
	pos.y = clampf(pos.y, 12.0, maxf(12.0, vp_size.y - tip_size.y - 12.0))
	_tooltip_panel.global_position = pos

func _hide_tooltip() -> void:
	if _tooltip_panel != null:
		_tooltip_panel.hide()

func find_best_focus_target() -> Control:
	var scene := get_tree().current_scene
	if scene == null:
		return null

	var candidates: Array[Control] = []
	_collect_focusable_controls(scene, candidates)
	if candidates.is_empty():
		return null

	var best: Control = candidates[candidates.size() - 1]
	var top_container := _find_top_modal_root(best)
	if top_container != null:
		for c in candidates:
			if top_container.is_ancestor_of(c) or c == top_container:
				return c
	return candidates[0]

func _collect_focusable_controls(node: Node, out: Array[Control]) -> void:
	if node is CanvasItem and not node.visible:
		return
	if node is Control:
		if _is_focusable_control(node):
			out.append(node)
	for child in node.get_children():
		_collect_focusable_controls(child, out)

func _is_focusable_control(ctrl: Control) -> bool:
	if not ctrl.is_visible_in_tree():
		return false
	if ctrl.focus_mode == Control.FOCUS_NONE:
		return false
	if ctrl is BaseButton:
		return not ctrl.disabled
	if ctrl is Range:
		return ctrl.editable
	return false

func _find_top_modal_root(ctrl: Control) -> Node:
	var cur: Node = ctrl
	while cur != null:
		if cur is CanvasLayer:
			return cur
		var parent := cur.get_parent()
		if parent is CanvasLayer:
			return cur
		cur = parent
	return null
