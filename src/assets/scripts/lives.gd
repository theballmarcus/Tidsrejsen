extends Control

@onready var lifeObj : Area2D = $LifeArea

var maxLives = Gamestate.health

var tile_offset = 58
var lives = []

var last_life = maxLives

func _ready():
	lifeObj.visible = true
	for i in range(maxLives):
		var thisLife = lifeObj.duplicate()
		thisLife.position = Vector2(tile_offset * i, 0
		)
		add_child(thisLife)
		lives.append(thisLife)

func _process(delta: float) -> void:
	if last_life != Gamestate.health:
		var idx = 0
		for life in lives:
			if Gamestate.health < idx + 1:
				life.modulate = Color(1,0,0) 
				# var new_texture = preload("res://assets/graphics/images/Health_Dot.png")
				# var l = life.get_node('Life')
				# l.texture = new_texture
				# l.visible = false
			idx += 1
		
		last_life = Gamestate.health
