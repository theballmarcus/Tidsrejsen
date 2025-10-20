extends Control

@onready var money_label = $MoneyLabel
@onready var startWaveButton: Button = $StartWaveButton
@onready var nEnimiesLabel : Label = $EnimiesLeftLabel/nEnimiesLabel
@onready var change_levels_button : Control = $ChangeLevelButton
@onready var EnemiesLeftLabel=$EnimiesLeftLabel

@onready var nWavesLabel = $StartWaveButton/WavesCompletedLabel/nWaves
@onready var nEnemiesLabel = $StartWaveButton/EnemiesKilledLabel/nEnemies

@onready var settings_panel = $SettingsPanel
@onready var musicslider=$SettingsPanel/TextureRect/MusicSlider
@onready var volumeslider=$SettingsPanel/TextureRect/VolumeSlider

var EnemyScene = preload("res://assets/instances/Enemy.tscn")
var TurretScene = preload("res://assets/instances/Turret.tscn")

var row_enemy_counts := {}
var enemies_left = 0

var active_levels = []
var spawning = false

var background_child

func _ready():
	nEnimiesLabel.text = "0"
	nWavesLabel.text = str(Gamestate.waves_completed)
	nEnemiesLabel.text = str(Gamestate.enemies_killed)

	background_child = load(Gamestate.levels[Gamestate.current_level].scene).instantiate()
	add_child(background_child)
	move_child(background_child, 0)
	init_turrets()
	startWaveButton.connect("pressed", Callable(self, "create_wave"))
	change_levels_button.level_change.connect(_on_level_change)
	
	musicslider.min_value=0
	musicslider.max_value=1
	musicslider.step=0.01
	musicslider.value = Gamestate.musicLevel
	musicslider.connect("value_changed", Callable(self, "_on_slider_value_changed"))
	
	volumeslider.min_value = 0
	volumeslider.max_value = 1
	volumeslider.step = 0.01
	volumeslider.value = Gamestate.soundEffectLevel
	volumeslider.connect("value_changed", Callable(self, "_on_volume_slider_value_changed"))
	
	Sound.play_music(Gamestate.current_level)

func _process(delta):
	if Gamestate.game_running and Gamestate.health == 0:
		Sound.play_sound("Gameover")
		Gamestate.gameover = true
		Gamestate.game_running = false
		EnemiesLeftLabel.visible=false
		
	if Engine.get_frames_drawn() % Gamestate.frames_per_money == 0:
		if Gamestate.game_running == true:
			Gamestate.money = Gamestate.money + 1
		money_label.text = "$" + str(Gamestate.money)
		
	if enemies_left == 0 and Gamestate.game_running == true and spawning == false and Gamestate.gameover == false:
		Gamestate.levels[Gamestate.current_level].wave += 1
		Gamestate.game_running = false
		Gamestate.waves_completed += 1
		Gamestate.money += Gamestate.money_per_wave * Gamestate.waves_completed
		startWaveButton.disabled = false
		startWaveButton.visible = true
		nWavesLabel.text = str(Gamestate.waves_completed)
		nEnemiesLabel.text = str(Gamestate.enemies_killed)

func _on_level_change():
	if Gamestate.openTurretPanel != null:
		Gamestate.openTurretPanel.visible = false
	init_turrets()

	background_child.queue_free()
	background_child = load(Gamestate.levels[Gamestate.current_level].scene).instantiate()

	add_child(background_child)
	move_child(background_child, 0)
	
	Sound.play_music(Gamestate.current_level)

# Turret logic
func init_turrets():
	if not Gamestate.current_level in active_levels:
		var tCounter = 1
		for row in Gamestate.levels[Gamestate.current_level].allowed_rows:
			var t = TurretScene.instantiate()
			var yOffset = 0
			var xOffset = 0

			if Gamestate.levels[Gamestate.current_level].has('y_offset'):
				yOffset = Gamestate.levels[Gamestate.current_level].y_offset
			if Gamestate.levels[Gamestate.current_level].has('x_offset'):
				xOffset = Gamestate.levels[Gamestate.current_level].x_offset
			t.global_position = Vector2(100 + xOffset, yOffset + row * Gamestate.TILE_HEIGHT + Gamestate.TILE_HEIGHT / 2)
			t.turret_level = Gamestate.current_level
			t.turretNumber = tCounter
			tCounter += 1
			add_child(t)
			active_levels.append(Gamestate.current_level)
		
# Enemy logic
func spawn_wave(n):
	var min_row = Gamestate.levels[Gamestate.current_level].allowed_rows.min()
	if (Gamestate.levels[Gamestate.current_level].wave) < len(Gamestate.levels[Gamestate.current_level].allowed_rows):
		if not Gamestate.levels[Gamestate.current_level].has('active_rows'):
			Gamestate.levels[Gamestate.current_level].active_rows = [min_row + randi() % len(Gamestate.levels[Gamestate.current_level].allowed_rows)]
		else:
			var foundUnique = false
			var q = 0
			while foundUnique == false:
				q = randi() % len(Gamestate.levels[Gamestate.current_level].allowed_rows)
				if min_row + q not in Gamestate.levels[Gamestate.current_level].active_rows:
					Gamestate.levels[Gamestate.current_level].active_rows.append(min_row + q)
					foundUnique = true 

	for row in Gamestate.levels[Gamestate.current_level].active_rows:
		row_enemy_counts[row] = 0 # init dict to avoid errors
	
	spawning = true
	enemies_left = n
	for i in range(n):
		spawn_enemy()
		var delay = Gamestate.calculateTimebetweenEnemies()
		await get_tree().create_timer(delay).timeout
	spawning = false

func spawn_enemy():
	if not Gamestate.game_running:
		return
	# Find the row with the lowest number of enemies
	var min_count = row_enemy_counts.values().min()
	var candidate_rows = []
	
	for row in Gamestate.levels[Gamestate.current_level].active_rows:
		if row_enemy_counts[row] == min_count:
			candidate_rows.append(row)
	
	# Bug fix in case of race condition
	if candidate_rows.size() == 0:
		if candidate_rows.size() == 0:
			# Fallback: include all rows with the min count (e.g., in case of race condition)
			for row in Gamestate.levels[Gamestate.current_level].active_rows:
				if row_enemy_counts[row] == min_count:
					candidate_rows.append(row)
	
	# Choose a row randomly from least-used
	var chosen_row = candidate_rows[randi() % candidate_rows.size()]
	var y_pos = chosen_row * Gamestate.TILE_HEIGHT + Gamestate.TILE_HEIGHT / 2

	# Spawn the enemy
	var enemy = EnemyScene.instantiate()
	enemy.global_position = Vector2(Gamestate.SCREEN_WIDTH, y_pos + Gamestate.levels[Gamestate.current_level].y_offset)
	enemy.thisRow = chosen_row
	enemy.enemy_die.connect(_on_enemy_died)
	enemy.enemy_revive.connect(_on_enemy_revive)

	add_child(enemy)
	nEnimiesLabel.text = str(enemies_left)
	
	row_enemy_counts[chosen_row] += 1
	
func _on_enemy_died():
	enemies_left -= 1
	Gamestate.enemies_killed += 1
	nEnimiesLabel.text = str(enemies_left)

func _on_enemy_revive():
	enemies_left += 1
	Gamestate.enemies_killed -= 1
	nEnimiesLabel.text = str(enemies_left)

# Wave logic
func create_wave():
	Gamestate.game_running = true
	startWaveButton.disabled = true
	startWaveButton.visible = false
	
	# Spawn more enemies the lpnger the game goes
	spawn_wave(Gamestate.calculateNumberOfEnemies())

func _on_slider_value_changed(value): 
	Gamestate.musicLevel = value
	
func _on_volume_slider_value_changed(value): 
	Gamestate.soundEffectLevel = value

func linear_to_db(value):
	if value <= 0:
		return -80  # praktisk "mute"
	return 20 * log(value)

func _on_settings_button_pressed():
	settings_panel.visible = true
	Sound.play_sound("MenuButtonPressed")

func _on_back_button_pressed():
	settings_panel.visible = false
	Sound.play_sound("MenuButtonPressed")

func _on_ok_button_pressed() -> void:
	settings_panel.visible=false
	Sound.play_sound("MenuButtonPressed")
