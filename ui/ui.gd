extends Control

func _on_show_hint(action_text, item_name):		
	$CenterContainer/Hint.text = action_text

func _on_hide_hint():
	$CenterContainer/Hint.text = ""
