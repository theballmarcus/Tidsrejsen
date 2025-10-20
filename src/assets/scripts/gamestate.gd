extends Node

# Game tweaking flags
# ===== PLAYER ===== #
var max_health := 5
var health := max_health
var max_rewind_time := 5.0
# ===== MONEY ===== #
var frames_per_money = 20 				# How many frames need to pass before a coin is given
var starting_money := 150				# Amount of starting money
var money := starting_money
var money_per_enemy = 5
var money_per_wave = 10
# ===== ENEMIES ===== #
var MIN_SPAWN_DELAY = 0.8				# enemy minimum spawn delay
var MAX_SPAWN_DELAY = 1.4				# enemy maximum spawn delay
var enemy_max_health: float = 2.0
var enemy_move_speed: float = 55
# ===== TURRET ===== #
var frames_per_rewind_recharge = 10
# ===== BULLETS ===== #
var bullet_damage : float = 1.0
var bullet_speed : float = 400.0

# Global flags
var game_running := false
var is_rewinding := false
var gameover := false

var waves_completed := 0
var enemies_killed := 0

var TILE_WIDTH = 48
var TILE_HEIGHT = 48
var SCREEN_WIDTH = 768
var TILES_X = 16
var TILES_Y = 9

var levels = {
	"Dinosaurtiden" : {
		"year" : -1*10**8,
		"scene" : "res://scenes/game/Dinosaurtiden.tscn",
		"allowed_rows" : [3, 4, 5, 6],
		"wave" : 0,
		"y_offset" : 0,
		"x_offset" : 0,
		"required_waves" : 0,
		"extra_enemy_health" : 0,
		"extra_money_bonnie_factor" : 1
	},
	"Det Gamle Egypten" : {
		"year" : -3000,
		"scene" : "res://scenes/game/Det_Gamle_Egypten.tscn",
		"allowed_rows" : [4, 5, 6, 7],
		"wave" : 0,
		"y_offset" : 0,
		"x_offset" : 0,
		"required_waves" : 1,
		"extra_enemy_health" : bullet_damage,
		"extra_money_bonnie_factor" : 1.8
	},
	"Den Moderne Tid" : {
		"year" : 2025,
		"scene" : "res://scenes/game/DenModerneTid.tscn",
		"allowed_rows" : [3, 4, 5, 6],
		"wave" : 0,
		"y_offset" : 20,
		"x_offset" : 10,
		"required_waves" : 4,
		"extra_enemy_health" : bullet_damage * 2,
		"extra_money_bonnie_factor" : 2.6
	},
	"Fremtiden" : {
		"year" : 5000,
		"scene" : "res://scenes/game/Fremtiden.tscn",
		"allowed_rows" : [3, 4, 5, 6, 7],
		"wave" : 0,
		"y_offset" : -5,
		"x_offset" : -35,
		"required_waves" : 7,
		"extra_enemy_health" : bullet_damage * 3,
		"extra_money_bonnie_factor" : 2.4
	}
} 

var turret_states = {
	0 : {
		"price" : 0,
		"shoot_time" : 0,
		"damage" : 0,
		"text_color" : Color(0,0,0)
	},
	1 : {
		"price" : 100,
		"shoot_time" : 1.5,
		"damage" : 30,
		"text_color" : Color(0.6, 1.0, 0.6)
	},
	2 : {
		"price" : 150,
		"shoot_time" : 1.0,
		"damage" : 30,
		"text_color" : Color(0.9, 0.9, 0.4)

	},
	3 : {
		"price" : 250,
		"shoot_time" : 0.6,
		"damage" : 30,
		"text_color" : Color(1.0, 0.6, 0.2)

	},
	4 : {
		"price" : 500,
		"shoot_time" : 0.4,
		"damage" : 30,
		"text_color" : Color(1.0, 0.3, 0.1)
	},
	5 : {
		"price" : 1500,
		"shoot_time" : 0.1,
		"damage" : 30,
		"text_color" : Color(1.0, 0.0, 0.0)
	}
}

var current_level = "Dinosaurtiden"; # start level

var MinYear = 0
var MaxYear = 0

var soundEffectLevel :float= 0.05
var musicLevel :float= 0.05

# Turretpanel
var openTurretPanel

func _ready():
	for i in levels:
		if MinYear == 0 or levels[i].year < MinYear:
			MinYear = levels[i].year
		if MaxYear == 0 or levels[i].year > MaxYear:
			MaxYear = levels[i].year

# Balancing function - how many enemies do we want to spawn?
func calculateNumberOfEnemies():
	var enemyCount = 5 + Gamestate.levels[Gamestate.current_level].wave * 4
	return enemyCount

func calculateTimebetweenEnemies() -> float:
	var a = 2.3 
	var b = 0.25 
	var wave = float(Gamestate.levels[Gamestate.current_level].wave)

	var time_between = a * exp(-b * wave)
	time_between += randf_range(-0.2, 0.2)
	return clamp(time_between, 0.1, 5.0)

func restart():
	waves_completed = 0
	enemies_killed = 0
	health = max_health
	game_running = false
	is_rewinding = false
	gameover = false
	current_level = "Dinosaurtiden"
	money = starting_money
	for l in levels:
		if levels[l].has("active_rows"):
			levels[l].erase("active_rows")
			levels[l].wave = 0
