extends GPUParticles3D

func _ready():
	#self.finished.connect(_on_explosion_finished)
	pass
	
func _on_explosion_finished():
	await get_tree().create_timer(0.1).timeout # Workaround, without this godot doesn't fire the signal after the first restart
	self.restart()
