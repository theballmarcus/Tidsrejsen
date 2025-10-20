 
extends Node

const MAX_PLAYERS = 16

var sounds = {
	"MenuButtonPressed": preload("res://assets/audio/MenuButtonPressed.mp3"),
	"EnemyDamaged": preload("res://assets/audio/EnemyDamaged.mp3"),
	"Gameover": preload("res://assets/audio/Gameover.mp3"),
	"Rewind": preload("res://assets/audio/Rewind.mp3"),
	"TurretBuild": preload("res://assets/audio/TurretBuild.mp3"),
	"TurretDamaged": preload("res://assets/audio/TurretDamaged.mp3"),
	"TurretLevelUp": preload ("res://assets/audio/TurretLevelUp.mp3"),
	"TurretLaser": preload ("res://assets/audio/Turrets_laser.mp3"),
	"WaveWon": preload ("res://assets/audio/WaveWon.mp3"),
}

var backgroundSounds = {
	"MusicMenu": preload ("res://assets/audio/suspense-sci-fi-underscore-music-loop-300215.mp3"),
	"Dinosaurtiden": preload ("res://assets/audio/BaggrundJunglen.mp3"),
	"Det Gamle Egypten": preload ("res://assets/audio/BaggrundOerken.mp3"),
	"Den Moderne Tid": preload ("res://assets/audio/BaggrundNutiden.mp3"),
	"Fremtiden": preload ("res://assets/audio/BaggrundFremtid.mp3"),
}

var players: Array
var backgroundMusic

func _ready():
	for i in MAX_PLAYERS:
		var player = AudioStreamPlayer.new()
		add_child(player)
		players.append(player)
	backgroundMusic = AudioStreamPlayer.new()
	add_child(backgroundMusic)
	
func play_sound(sound_name: String):
	if not sounds.has(sound_name):
		push_warning("Sound not found: %s" % sound_name)
		return
	var sound = sounds[sound_name]

	for player in players:
		if not player.playing:
			player.stream = sound
			player.volume_db = linear_to_db(Gamestate.soundEffectLevel)
			player.play()
			return player
	push_warning("All audio players busy, couldn't play: %s" % sound_name)

func play_music(sound_name: String="MusicMenu"):
	backgroundMusic.stream = backgroundSounds[sound_name]
	backgroundMusic.play()
	
func _process(delta: float) -> void:
	backgroundMusic.volume_db = linear_to_db(Gamestate.musicLevel)
	
func linear_to_db(value):
	if value <= 0:
		return -80  
	return 20 * log(value)
