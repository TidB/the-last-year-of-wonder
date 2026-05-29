extends Node3D

@export var char_name = "DEFAULT"

func _ready():
	add_to_group(Global.NPC_GROUP)
	$Helper.visible = false
	
func write_line(text):
	$Helper/Dialogue.text = text

func clear_line():
	$Helper/Dialogue.text = ""
	
func show_line():
	$Helper/Dialogue.visible = true
	
func hide_line():
	$Helper/Dialogue.visible = false
	
func dialogue_finished():
	$Helper/Dialogue.text = ""
	
func display_dialogue(value):
	#$Helper/Dialogue.text = ""
	$Helper.visible = value

func look_at_player(pos):
	pos.y = $Helper.global_position.y
	$Helper.look_at(pos)
