extends Area3D

const MINIMUM_WAIT = 700
	
enum Action {
	PLAYER,
	OTHER,
}

@export var dialogue_name = ''

var dialogue = null
var current_line_no = 0

signal advance
signal show(text)
signal hide
signal finished

var player
#var ui  # Used for the player's lines
var others = {}
var last_line = Time.get_ticks_msec()
var timer
var loop = 0
var bright = true

func _ready():
	assert(dialogue_name, "Dialogue without name in level")

	add_to_group("dialogue")
	for child in self.get_children():
		if child.name == 'TriggerArea':  # TODO: Very terrible
			continue

		var alias = child.name.left(1).to_lower()
		assert(alias not in self.others, "Multiple dialogue children start with the same letter")
		self.others[alias] = child
	
	timer = Timer.new()
	add_child(timer)
	
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

	for line in content.strip_edges().split("\n"):
		line = line.strip_edges()

		if line.begins_with("#"):
			continue
			#current_time = line.split(" ")[1]
		elif line.begins_with("/"):
			var action = line.split(" ")[1]
		else:
			var person_line = line.split(" ", true, 1)
			if len(person_line) < 2:
				printerr("invalid dialogue line: ", line)
			
			var action
			var speaker = null
			if person_line[0] == 'p':
				action = Action.PLAYER
			else:
				action = Action.OTHER
				speaker = person_line[0].to_lower()
				
				assert(speaker in others, "invalid dialogue person in line: " + str(person_line))
			dialogue[current_time].append({
				'action': action,
				'speaker': speaker,
				'line': person_line[1],
				})
	
	return dialogue
	
func get_current_line():
	if not self.dialogue:
		self.dialogue = parse_dialogue(dialogue_name)
	
	self.current_line_no += 1
	if self.current_line_no > len(self.dialogue['0']):
		return null

	return self.dialogue['0'][self.current_line_no-1]
		
func interact():
	#print("interacted with!!")
	if self.overlaps_body(player):
		#print("and the player is inside me!!")
		if Time.get_ticks_msec() - last_line > MINIMUM_WAIT:
			emit_signal("advance")
			
func write_other(alias, line):
	self.others[alias].write_line(line)
	
func clear_other(alias):
	if alias == null:
		for other in self.others.values():
			other.clear_line()
	else:
		self.others[alias].clear_line()

func _on_body_entered_dialogue(body):
	# When this happens: show the latest dialogue that makes sense, similar to CosmoD
	# Usually reset it to the last repeatable puzzle intro, but don't advance yet (only when clicked on *and* body is still there)
	# TODO: Ideally, we might want to make some 'cinematic' adjustments so we can have some kind of playable cutscene instead
	# 		of totally separated little repeatable snippets
	print(dialogue_name, " body entered: ", body)
	self.current_line_no = 0
	#player.set_active_dialogue_position(other.position + Vector3(0, 0.636, 0)) # Don't look at the middle, a bit above
	player.entered_dialogue(self)
	for other in others.values():
		other.display_dialogue(true)
	#ui.display_dialogue(true)
	#self.start()
	
func _on_body_exited_dialogue(body):
	print(dialogue_name, " body exited: ", body)
	#player.set_active_dialogue_position(null)
	player.exited_dialogue(self)
	for other in others.values():
		other.display_dialogue(false)
	#ui.display_dialogue(false)#
	
