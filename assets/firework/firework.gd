extends Node3D

var explosions = []

const COLORS = [
	Color("ffb000"),
	Color("fe6100"),
	Color("dc267f"),
	Color("785ef0"),  # Might skip this one for Protanopia?
	Color("648fff"),
]
var current_color = 0

const SOLUTION_PATTERN = []

func _ready():
	self.explosions = self.get_children()
	
	self.fire()

func fire():
	self.explosions.shuffle()

	for explosion in explosions:
		explosion.draw_pass_1.material.emission = COLORS[current_color]
		explosion.restart()
		await get_tree().create_timer(0.2).timeout
		
	self.current_color = (self.current_color + 1) % 5
	get_tree().create_timer(2.5).timeout.connect(self.fire)
