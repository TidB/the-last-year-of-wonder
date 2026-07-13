extends Control

const DISTORTION_DEFAULT = Transform2D(
	Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(0.0, 0.0)
	)
const DISTORTION_MAX = Transform2D(
	Vector2(1.0, 0.0), Vector2(4.0, 1.0), Vector2(0.0, 0.0)
	)

func _ready():
	self._on_set_distortion(0.0)
	
func _on_show_hint(id, action_text):		
	$CenterContainer/Hint.text = action_text

func _on_hide_hint():
	$CenterContainer/Hint.text = ""

func _on_set_distortion(ratio):
	$CenterContainer/Hint.label_settings.font.variation_transform = DISTORTION_DEFAULT.interpolate_with(DISTORTION_MAX, ratio)
