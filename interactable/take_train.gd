extends StaticBody3D

signal show_hint(id, label)
signal hide_hint

@export var id = "default id"
@export var label = "Default Label"

func _ready():
	assert(get_node_or_null("CollisionShape3D"), "TakeTrain objects need a collision shape")
	
	add_to_group(Global.INTERACTABLE_GROUP)
	
func highlight():
	emit_signal("show_hint", self.id, self.label)

func remove_highlight():
	emit_signal("hide_hint")

func use():
	print("should switch levels!")
