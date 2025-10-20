extends Control

@onready var thisNode = $this
@onready var nWavesLabel = $WavesCompletedLabel/nWaves
@onready var nEnimiesLabel = $EnemiesKilledLabel/nEnemies
@onready var menuButton = $MenuButton
@onready var startWaveButton: Button = $StartWaveButton
@onready var restartButton : Button = $RestartButton

var thisVisible = false

func _ready() -> void:
	self.visible = false
	menuButton.connect("pressed", Callable(self, "_on_menu_pressed"))
	restartButton.connect("pressed", Callable(self, "_on_restart_pressed"))
	
func _process(delta: float) -> void:
	if Gamestate.gameover == true and thisVisible == false:
		nWavesLabel.text = str(Gamestate.waves_completed)
		nEnimiesLabel.text = str(Gamestate.enemies_killed)
		self.visible = true

func _on_menu_pressed():
	Sound.play_sound("MenuButtonPressed")
	get_tree().change_scene_to_file("res://assets/instances/MainMenu.tscn")
	
func _on_restart_pressed():
	Sound.play_sound("MenuButtonPressed")
	Gamestate.restart()
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")
