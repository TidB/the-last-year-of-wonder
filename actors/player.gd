extends CharacterBody3D

var MOUSE_SENSITIVITY = 0.05
const JUMP_SPEED = 3.0
const RUN_SPEED = 15 # Normally: 6.5
const WALK_SPEED = 4.5
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")
const LERP_SPEED = 10.0
var direction = Vector3.ZERO

var camera
var rotation_helper

var highlighted_obj

var current_dialogue = null

enum State {
	Nothing,
	ReadDescription,
	EndDescription 
}
var speech_state = State.Nothing
var ui
var interactable_text_to_read = null
signal ui_write_line(text)
signal ui_clear_line
signal advance

func get_camera_position():
	return $RotationHelper/Camera.global_position
	
func safe_highlighted_obj_check(obj):
	if not is_instance_valid(obj):
		highlighted_obj = null
		return false
	else:
		return true

func _ready():
	camera = $RotationHelper/Camera
	rotation_helper = $RotationHelper

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	process_input(delta)
	process_movement(delta)
	process_aim()

# Taken from https://www.youtube.com/watch?v=xIKErMgJ1Yk
func process_movement(delta):
	var current_speed = 0
	if Input.is_action_pressed("sprint"):
		current_speed = RUN_SPEED
	else:
		current_speed = WALK_SPEED
	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if Input.is_action_just_pressed("movement_jump") and is_on_floor():
		velocity.y = JUMP_SPEED

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("movement_left", "movement_right", "movement_forward", "movement_backward")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * LERP_SPEED)
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# TODO: Little cute bounce when landing on the ground?
	move_and_slide()

func process_input(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func process_aim():
	var size = get_viewport().size
	var from = $RotationHelper/Camera.project_ray_origin(size / 2)
	var to = from + $RotationHelper/Camera.project_ray_normal(size / 2) * 2.0
	
	# TODO: Replace this with the collisionobject3d's input event as mentionedin the docs?
	var space_state = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(from, to, 0b11)
	var result = space_state.intersect_ray(params)
	
	if result and result["collider"] and result["collider"].collision_layer != 0b1:
		if result["collider"] != highlighted_obj:
			if highlighted_obj:
				highlighted_obj.remove_highlight()
			
			if self.speech_state not in [State.ReadDescription, State.EndDescription]:
				highlighted_obj = result["collider"]
				highlighted_obj.highlight()  
	else:
		if safe_highlighted_obj_check(highlighted_obj):
			highlighted_obj.remove_highlight()
			highlighted_obj = null

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg_to_rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg_to_rad(event.relative.x * MOUSE_SENSITIVITY * -1))

		var camera_rot = rotation_helper.rotation
		camera_rot.x = deg_to_rad(clamp(rad_to_deg(camera_rot.x), -80, 80))
		rotation_helper.rotation = camera_rot
	elif event.is_action_pressed("interact"):
		process_interaction()
		update_highlight()
			
func process_interaction():
	if highlighted_obj:
		highlighted_obj.use(self.inventory.get(self.selected_inv_item) if self.inv_visible else null)

		# TODO: Does this make sense? It's currently a hack to allow advancing descriptions, but if there's ever
		# an object like a button that you can press multiple times, this doesn't make sense
		if highlighted_obj:
			highlighted_obj.remove_highlight()
			highlighted_obj = null
	else:
		process_speech()
			
func process_speech():
	if self.speech_state != State.Nothing:
		#if self.current_dialogue:
	#		self.current_dialogue.other.hide_line()
		if self.speech_state == State.EndDescription:
			self.ui_clear_line.emit()
			self.ui.display_dialogue(true)
			self.speech_state = State.Nothing
		else:
			if highlighted_obj:
				highlighted_obj.remove_highlight()
				highlighted_obj = null
			self.ui.display_dialogue(true)
			self.ui_write_line.emit(self.interactable_text_to_read)
			self.speech_state = State.EndDescription
	elif self.current_dialogue:
		var line = self.current_dialogue.get_current_line() # TODO: advancing the line should happen separately
		if line == null:
			self.ui_clear_line.emit()
			self.current_dialogue.other.clear_line()
		elif line[0] == self.current_dialogue.Action.PLAYER:
			self.ui_write_line.emit(line[1])
			self.current_dialogue.other.clear_line()
		elif line[0] == self.current_dialogue.Action.OTHER:
			self.current_dialogue.other.write_line(line[1])
			self.ui_clear_line.emit()
			
		#last_line = Time.get_ticks_msec()
		#var word_count = len(line[1].split(" "))
		#var reading_time = max(1.5, word_count / 225.0 * 60) / Global.TEXT_SPEED
#
		#print(word_count, " words, equals ", reading_time, " seconds")
		#timer.start(reading_time) 
	
	# TODO: Currently, we can advance the dialogue as long as we're in the dia's Area3D. It should
	# instead make sure we got some kind of line of sight or at least look at the general direction
	# of the label
	# Could be done with a shapecast instead of raycast - so we're not looking at a broader area of other, but we're looking with a broader view on a specific point
	
	#var params = PhysicsRayQueryParameters3D.create(from, to, 0b100)
	#var result = space_state.intersect_ray(params)
	#if result and result["collider"]:
#		result["collider"].interact()  # TODO: This and the part above are unsafe and should have a try/catch thingy

func entered_dialogue(dia_node):
	self.current_dialogue = dia_node
	self.ui.display_dialogue(true)
	process_speech()

func exited_dialogue(dia_node):
	self.speech_state = State.Nothing
	self.current_dialogue = null
	self.ui.display_dialogue(false)

func update_highlight():
	if is_instance_valid(highlighted_obj):
		highlighted_obj.highlight()
