extends Node3D

var explosions = []

const COLORS = [
	Color("ffb000"),
	Color("fe6100"),
	Color("dc267f"),
	Color("785ef0"),
	Color("648fff"),
]
var current_color = 0

func _ready():
	self.explosions = [$explosion2, $explosion3, $explosion4]
	
	#for explosion in explosions:
#		explosion.finished.connect(_on_explosion_finished)
		#explosion.restart()
	
	self.fire()

func fire():
	print(len(get_stack()))
	self.explosions.shuffle()

	for explosion in explosions:
		explosion.draw_pass_1.material.emission = COLORS[current_color]
		explosion.restart()
		await get_tree().create_timer(0.2).timeout
		
	self.current_color = (self.current_color + 1) % 5
	get_tree().create_timer(2.6).timeout.connect(self.fire)
