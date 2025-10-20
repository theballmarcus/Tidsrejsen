extends Node2D

var EnemyScene = preload("res://assets/instances/Enemy.tscn")
var TurretScene = preload("res://assets/instances/Turret.tscn")

var TILE_WIDTH = 48
var TILE_HEIGHT = 48
var SCREEN_WIDTH = 768
var TILES_X = 16
var TILES_Y = 9

var MIN_SPAWN_DELAY = 0.3
var MAX_SPAWN_DELAY = 0.4

var allowed_spawn_rows = [1, 2, 4, 6, 7]

var row_enemy_counts := {}

func _ready():
	for row in allowed_spawn_rows:
		row_enemy_counts[row] = 0
	
	spawn_wave(20)
	for row in allowed_spawn_rows:
		var t = TurretScene.instantiate()
		t.global_position = Vector2(100, row * TILE_HEIGHT + TILE_HEIGHT / 2)
		add_child(t)

func spawn_wave(n):
	for i in range(n):
		spawn_enemy()
		var delay = randf_range(MIN_SPAWN_DELAY, MAX_SPAWN_DELAY)
		await get_tree().create_timer(delay).timeout

func spawn_enemy():
	var min_count = row_enemy_counts.values().min()
	var candidate_rows = []

	for row in allowed_spawn_rows:
		if row_enemy_counts[row] == min_count:
			candidate_rows.append(row)

	var chosen_row = candidate_rows[randi() % candidate_rows.size()]

	var y_pos = chosen_row * TILE_HEIGHT + TILE_HEIGHT / 2

	var enemy = EnemyScene.instantiate()
	enemy.global_position = Vector2(SCREEN_WIDTH, y_pos)

	enemy.set_meta("row_index", chosen_row)

	if enemy.has_signal("enemy_died"):
		enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))

	add_child(enemy)

	row_enemy_counts[chosen_row] += 1

func _on_enemy_died(enemy):
	var row = enemy.get_meta("row_index")
	if row_enemy_counts.has(row):
		row_enemy_counts[row] = max(0, row_enemy_counts[row] - 1)
