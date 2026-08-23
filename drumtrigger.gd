extends StaticBody3D

func _ready():
	assert(get_node_or_null("CollisionShape3D"), "Drummer trigger object needs a collision shape")
	
	add_to_group(Global.LOOKABLE_GROUP)
