extends Control

@onready var level_up_button = $ChangeUpButton
@onready var level_down_button = $ChangeDownButton
@onready var level_label = $LevelLabel

signal level_change

func _ready():
	level_up_button.pressed.connect(_on_level_up)
	level_down_button.pressed.connect(_on_level_down)
	level_label.text = Gamestate.current_level
	update_buttons()

func _on_level_up():	
	var next_level_key = find_next_level(true)
	if next_level_key != "":
		level_label.text = next_level_key
		Gamestate.current_level = next_level_key
		update_buttons()
		emit_signal("level_change")

func _on_level_down():
	var next_level_key = find_next_level(false)
	if next_level_key != "":
		level_label.text = next_level_key
		Gamestate.current_level = next_level_key
		update_buttons()
		emit_signal("level_change")

func find_next_level(up = true):
	var current_year = Gamestate.levels[Gamestate.current_level].year
	var next_level_key: String = ""
	var smallest_year_diff = INF
	
	for key in Gamestate.levels.keys():
		var level_year = Gamestate.levels[key].year
		if up == true:
			if level_year > current_year:
				var diff = level_year - current_year
				if diff < smallest_year_diff:
					smallest_year_diff = diff
					next_level_key = key
		else:
			if level_year < current_year:
				var diff = abs(level_year) - abs(current_year)
				if diff < smallest_year_diff:
					smallest_year_diff = diff
					next_level_key = key
	return next_level_key
	
func _process(delta: float) -> void:
	update_buttons()

func update_buttons():
	# Disable button when at mxa or minimum
	if Gamestate.game_running == true:
		level_up_button.disabled = true
		level_down_button.disabled = true
	else:
		var next_level = find_next_level(true)
		if next_level == "":
			level_up_button.disabled = true
		else:
			if Gamestate.levels[next_level].required_waves <= Gamestate.waves_completed:
				level_up_button.disabled = false
			else:
				level_up_button.disabled = true
		level_down_button.disabled = Gamestate.levels[Gamestate.current_level].year <= Gamestate.MinYear

	if level_up_button.disabled:
		level_up_button.modulate = Color(0.5, 0.5, 0.5,0)  # Gray
	else:
		level_up_button.modulate = Color(1, 1, 1)  # Normal

	if level_down_button.disabled:
		level_down_button.modulate = Color(0.5, 0.5, 0.5,0)
	else:
		level_down_button.modulate = Color(1, 1, 1)
