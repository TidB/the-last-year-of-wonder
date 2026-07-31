extends Area3D

const MINIMUM_WAIT = 700
var rng = RandomNumberGenerator.new()
	
enum Action {
	PLAYER,
	OTHER,
}

@export var dialogue_name = ''

var dialogue = []
var current_line_no = 0
var current_convo_id = null
var start_playing_random = false
var last_played_convo_id = null

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

func _ready():
	assert(dialogue_name, "Dialogue without name in level")

	add_to_group("dialogue")
	for child in self.get_children():
		if child.name in ['TriggerArea', 'Activity', 'Activity2']:  # TODO: Very terrible
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

	var current_convo = null

	for line in content.strip_edges().split("\n"):
		line = line.strip_edges()
		
		if not line:
			continue
		elif line.begins_with("#"):  # Comment
			continue
		elif line.begins_with("/"):
			#var action = line.split(" ")[1]
			current_convo = []
			self.dialogue.append(current_convo)
		else:
			var person_line = line.split(" ", true, 1)
			if len(person_line) < 2:
				printerr("invalid dialogue line: ", line)
				
			assert(current_convo != null, "Convo block without a leading slash")
			
			var action
			var speaker = null
			if person_line[0] == 'p':
				action = Action.PLAYER
			else:
				action = Action.OTHER
				speaker = person_line[0].to_lower()
				
				assert(speaker in others, "invalid dialogue person in line: " + str(person_line))
				
			current_convo.append({
				'action': action,
				'speaker': speaker,
				'line': person_line[1],
				})
	
	return dialogue
	
func get_current_line():
	if not self.dialogue:
		self.dialogue = parse_dialogue(dialogue_name)
		assert(len(self.dialogue) > 0, "Empty dialogue")
		self.current_convo_id = self._get_next_convo_id()
	
	self.current_line_no += 1
	if self.current_line_no > len(self.dialogue[self.current_convo_id]):
		self.current_convo_id = self._get_next_convo_id()
		return null

	return self.dialogue[self.current_convo_id][self.current_line_no-1]
	
func _get_next_convo_id():
	if self.current_convo_id == null:
		return 0
	else:
		if self.start_playing_random:
			self.last_played_convo_id = self.current_convo_id
			return random_except()
		else:
			if (self.current_convo_id + 1) >= len(self.dialogue):
				self.start_playing_random = true
				self.last_played_convo_id = self.current_convo_id
				return random_except()
			else:
				return self.current_convo_id + 1
				
func random_except():  # We don't wanna randomly select the same convo twice in a row
	while true:
		var idx = self.rng.randi_range(0, len(self.dialogue)-1)
		if (len(self.dialogue) < 2) or (idx != self.last_played_convo_id):
			return idx

# TODO: Currently, the convo ends, no text is shown, but the player can still click through the invisible dialogue
# Variant 1: The player has to step out of the dialogue to continue
# Variant 2: The next convo can happen directly after
# => Var 1 feels better
func interact():
	#print("interacted with!!")
	if self.overlaps_body(player):
		#print("and the player is inside me!!")
		if Time.get_ticks_msec() - last_line > MINIMUM_WAIT:
			emit_signal("advance")
			
func write_other(alias, line):
	self.others[alias].write_line(line)
	
func clear_all_others_except(alias = null):
	for other in self.others:
		if alias != other:
			self.others[other].clear_line()

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
	#print(dialogue_name, " body entered: ", body)
	self.current_line_no = 0
	$Activity.visible = true
	#player.set_active_dialogue_position(other.position + Vector3(0, 0.636, 0)) # Don't look at the middle, a bit above
	player.entered_dialogue(self)
	for other in others.values():
		other.display_dialogue(true)
	#ui.display_dialogue(true)
	#self.start()
	
func _on_body_exited_dialogue(body):
	#print(dialogue_name, " body exited: ", body)
	#player.set_active_dialogue_position(null)
	$Activity.visible = false
	player.exited_dialogue(self)
	for other in others.values():
		other.display_dialogue(false)
	#ui.display_dialogue(false)#
	
