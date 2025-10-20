extends Control

@onready var button: Button = $Button
@onready var rewind_time_label: Label = $RewindTimeLabel
@onready var clock_background=$ClockRewind/ClockBackground
@onready var clock_arrow=$ClockRewind/Rotation/ClockArrow
@onready var rotation_arrow=$ClockRewind/Rotation

var max_rewind_time := Gamestate.max_rewind_time
var rewind_time := max_rewind_time
var is_button_held := false
var speed=7
var rewindSound

func _ready():
	button.connect("button_down", Callable(self, "_on_button_down"))
	button.connect("button_up", Callable(self, "_on_button_up"))
	_update_button_state()
	clock_background.visible=false
	clock_arrow.visible=false

func _process(delta):
	_update_button_state()
	
	if Gamestate.game_running:
		if is_button_held:
			rewind_time -= delta
			if rewind_time <= 0:
				rewind_time = 0
				_force_release()
		else:
			if Engine.get_frames_drawn() % Gamestate.frames_per_rewind_recharge == 0:
				rewind_time += delta
				if rewind_time > max_rewind_time:
					rewind_time = max_rewind_time
	if button.disabled:
		rewind_time_label.visible = false
	else:
		rewind_time_label.visible = true
		if rewind_time_label:
			rewind_time_label.text = "⏪ %.1f / %.1f" % [rewind_time, max_rewind_time]
	rotation_arrow.rotation -= speed * delta

func _on_button_down():
	if rewind_time > 0 and Gamestate.game_running:
		is_button_held = true
		Gamestate.is_rewinding = true
		print("Rewinding started")
		clock_background.visible=true
		clock_arrow.visible=true
		rewindSound = Sound.play_sound("Rewind")

func _on_button_up():
	is_button_held = false
	Gamestate.is_rewinding = false
	print("Rewinding stopped")
	clock_background.visible=false
	clock_arrow.visible=false
	if rewindSound.is_playing():
		rewindSound.stop()

func _force_release():
	if is_button_held:
		print("Rewind time exhausted!")
		_on_button_up()

func _update_button_state():
	if Gamestate.game_running:
		button.disabled = false
		button.modulate = Color(1, 1, 1)
	else:
		button.disabled = true
		button.modulate = Color(0.5, 0.5, 0.5,0)
