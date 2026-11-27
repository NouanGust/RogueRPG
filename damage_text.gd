extends Label

const DEFAULT_DAMAGE_COLOR := Color(1.0, 0.25, 0.25, 1.0)
const CRITICAL_DAMAGE_COLOR := Color(1.0, 0.15, 0.15, 1.0)
const HEAL_COLOR := Color(0.24, 0.96, 0.45, 1.0)
const MISS_COLOR := Color(0.82, 0.86, 0.94, 1.0)

func start(
	value: int,
	start_position: Vector2,
	is_critical: bool = false,
	custom_color: Color = Color(0, 0, 0, 0),
	prefix: String = ""
) -> void:
	var final_color := custom_color
	if final_color.a <= 0.0:
		final_color = CRITICAL_DAMAGE_COLOR if is_critical else DEFAULT_DAMAGE_COLOR
	await start_text("%s%d" % [prefix, value], start_position, final_color, 1.5 if is_critical else 1.0)

func start_heal(heal_value: int, start_position: Vector2) -> void:
	await start(heal_value, start_position, false, HEAL_COLOR, "+")

func start_miss(start_position: Vector2) -> void:
	await start_text("ERROU!", start_position, MISS_COLOR, 1.15)

func start_text(
	label_text: String,
	start_position: Vector2,
	final_color: Color,
	text_scale: float = 1.0
) -> void:
	text = label_text
	position = start_position - (size / 2.0)
	modulate = Color.WHITE
	add_theme_color_override("font_color", final_color)
	scale = Vector2.ONE * text_scale

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 50, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.65).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	await tween.finished
	queue_free()
