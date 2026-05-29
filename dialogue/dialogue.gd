extends Area3D

const MINIMUM_WAIT = 700
	
enum Action {
	PLAYER,
	OTHER,
	#FADE
}

@export var dialogue_name = ''
# @export var people: Array[Node] TODO: Not needed for now, we'll just assume every dialogue is between the parent of this node and the player for now

var dialogue = null
var current_line_no = 0

signal advance
signal show(text)
signal hide
signal finished

var player
#var ui  # Used for the player's lines
var other
var last_line = Time.get_ticks_msec()
var timer
var loop = 0
#var gradient = load("res://bg_gradient.tres").gradient
#var blink_timer
var bright = true

func _ready():
	assert(dialogue_name, "Dialogue without name in level")

	add_to_group("dialogue")
	other = $".."
	# TODO: Add warning if two dialogues overlap? In the current concept, it's unwanted as you could advance two dialogues at once
	timer = Timer.new()
	add_child(timer)
	#blink_timer = Timer.new()
	#blink_timer.connect("timeout", self, "_on_blink_timer_timeout")
	#add_child(blink_timer)
	self.body_entered.connect(_on_body_entered_dialogue)
	self.body_exited.connect(_on_body_exited_dialogue)
	
#func set_ui(u):
#	ui = u
	
func set_player(p):
	player = p
		
func parse_dialogue(name):
	var file = FileAccess.open("res://dialogue/" + name.to_lower() + ".txt", FileAccess.READ)
	var content = file.get_as_text()
	file = null
	
	var dialogue = {}
	#for t in Global.TIME_CONFIG:
	#	dialogue[str(t['offset'])] = []
	
	var current_time = str(0)
	dialogue[current_time] = []
	var last_cond = null
	var condition = []
	for line in content.strip_edges().split("\n"):
		line = line.strip_edges()
		if line.is_empty():
			condition = []
			last_cond = null
		elif line.begins_with("#"):
			continue
			#current_time = line.split(" ")[1]
		elif line.begins_with("/"):
			var action = line.split(" ")[1]
#			if action == "FADE":
#				dialogue[current_time].append([Action.FADE])
		elif line.begins_with("="):
			if not last_cond == null:
				condition = [last_cond, 1]
			else:
				var args = line.split(" ")
				condition = [args[1], 0]
				last_cond = args[1]
		else:
			var person_line = line.split(" ", true, 1)
			if len(person_line) < 2:
				printerr("invalid dialogue line: ", line)
			
			var action
			if person_line[0] == 'o':
				action = Action.OTHER
			elif person_line[0] == 'p':
				action = Action.PLAYER
			else:
				printerr("invalid dialogue person in line: ", person_line)
			dialogue[current_time].append([action, person_line[1], condition])
	
	return dialogue
	
func get_current_line():
	if not self.dialogue:
		self.dialogue = parse_dialogue(dialogue_name)
	
	self.current_line_no += 1
	if self.current_line_no > len(self.dialogue['0']):
		return null

	return self.dialogue['0'][self.current_line_no-1]

#func play():
	##var time = Global.TIME_CONFIG[Global.current_time]['offset']
	#var time = 0
	#for line in self.dialogue[str(time)]:
		#if line[0] in [Action.PLAYER, Action.OTHER]:
			##var condition = line[2]
			##if condition:
				##if condition[0] in Global.choices:
					##if Global.choices[condition[0]] != condition[1]:
						##continue
				##else:
					##print("Choice '", condition[0], "' not defined!")
					##continue
				#
			#last_line = Time.get_ticks_msec()
			#if line[0] == Action.PLAYER:
				##ui.write_line(line[1])
				#other.clear_line()
			#elif line[0] == Action.OTHER:
				#other.write_line(line[1])
				##ui.clear_line()
			##emit_signal("show", line[1])
##
##			last_line = Time.get_ticks_msec()
##
			## TODO: Min wait time
##			var word_count = len(line[1].split(" "))
##			var reading_time = max(1.5, word_count / 225.0 * 60) / Global.TEXT_SPEED
##
##			print(word_count, " words, equals ", reading_time, " seconds")
##			timer.start(reading_time) 
			#await self.advance  # TODO: It works in practice, but seems wonky when considering re-triggering
			#
			##ui.clear_line()
			#other.clear_line()
	#
	##ui.clear_line()
	#other.clear_line()
#
##		elif line[0] == Action.FADE:
##			$TweenFade.interpolate_property($Fade, "color", Color(0, 0, 0, 0), Color(0, 0, 0, 1), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
##			$TweenFade.start()
##
##			await $TweenFade.tween_completed
##
##			$TweenFade.interpolate_property($Fade, "color", Color(0, 0, 0, 1), Color(0, 0, 0, 0), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
##			$TweenFade.start()
##
##			timer.start(1)
##			await timer.timeout
	#
##	$TweenFade.interpolate_property($Fade, "color", Color(0, 0, 0, 0), Color(0, 0, 0, 1), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
##	$TweenFade.start()
##
##	await $TweenFade.tween_completed
	#
	##timer.start(1)
	##await timer.timeout
		
func interact():
	#print("interacted with!!")
	if self.overlaps_body(player):
		#print("and the player is inside me!!")
		if Time.get_ticks_msec() - last_line > MINIMUM_WAIT:
			emit_signal("advance")

#func _on_blink_timer_timeout():
#	if bright:
#		$Values/ProdLabel.add_color_override("font_color", Color(1, 1, 1))
#	else:
#		$Values/ProdLabel.add_color_override("font_color", Color(0.8, 0.8, 0.8))
#	bright = !bright

func _on_body_entered_dialogue(body):
	# When this happens: show the latest dialogue that makes sense, similar to CosmoD
	# Usually reset it to the last repeatable puzzle intro, but don't advance yet (only when clicked on *and* body is still there)
	# TODO: Ideally, we might want to make some 'cinematic' adjustments so we can have some kind of playable cutscene instead
	# 		of totally separated little repeatable snippets
	print(dialogue_name, " body entered: ", body)
	self.current_line_no = 0
	#player.set_active_dialogue_position(other.position + Vector3(0, 0.636, 0)) # Don't look at the middle, a bit above
	player.entered_dialogue(self)
	other.display_dialogue(true)
	#ui.display_dialogue(true)
	#self.start()
	
func _on_body_exited_dialogue(body):
	print(dialogue_name, " body exited: ", body)
	#player.set_active_dialogue_position(null)
	player.exited_dialogue(self)
	other.display_dialogue(false)
	#ui.display_dialogue(false)#
	
