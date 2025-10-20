extends Node2D

@onready var Clock = $ClockBackground    # baggrund (cirkel)
@onready var Clock_Arrow = $ClockArrow      # viser (sprite eller texture)

var speed = 3.0   # hvor hurtigt viseren roterer baglæns

func show_clock():
	visible = true
	# evt. tilføj en tween for at "poppe" det frem
	var tween = create_tween()
	scale = Vector2(0.0, 0.0)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BOUNCE)

func _process(delta):
	if visible:
		# roter viseren baglæns
		Clock_Arrow.rotation -= speed * delta
