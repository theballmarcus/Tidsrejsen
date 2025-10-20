extends Control

@onready var settings_panel = $SettingsPanel
@onready var info_panel=$InfoPanel
@onready var logo = $Logo
@onready var settings_button = $SettingsButton
@onready var musicslider = $SettingsPanel/TextureRect/MusicSlider
@onready var volumeslider = $SettingsPanel/TextureRect/VolumeSlider

func _ready():
	Gamestate.restart()
	
	settings_panel.visible = false
	musicslider.min_value=0
	musicslider.max_value=1
	musicslider.step=0.05
	musicslider.value = Gamestate.musicLevel  # Start med fuld lyd
	musicslider.connect("value_changed", Callable(self, "_on_slider_value_changed"))
	
	volumeslider.min_value = 0
	volumeslider.max_value = 1
	volumeslider.step = 0.05
	volumeslider.value = Gamestate.soundEffectLevel
	volumeslider.connect("value_changed", Callable(self, "_on_volume_slider_value_changed"))
	
	Sound.play_music()
	
func _on_slider_value_changed(value): 
	Gamestate.musicLevel = value
	
func _on_volume_slider_value_changed(value): 
	Gamestate.soundEffectLevel = value

func _on_settings_button_pressed():
	settings_panel.visible=not settings_panel.visible
	Sound.play_sound("MenuButtonPressed")
	
func _on_back_button_pressed():
	settings_panel.visible=false
	settings_button.visible=true
	Sound.play_sound("MenuButtonPressed")

func _on_ok_button_pressed() -> void:
	settings_panel.visible=false
	settings_button.visible=true
	Sound.play_sound("MenuButtonPressed")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
	
func _on_start_button_pressed() -> void:
	await Sound.play_sound("MenuButtonPressed").finished
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")
	
func _on_info_button_pressed() -> void:
	info_panel.visible=not info_panel.visible
	Sound.play_sound("MenuButtonPressed")

func _on_ok_2_button_pressed() -> void:
	info_panel.visible=false
	Sound.play_sound("MenuButtonPressed")
