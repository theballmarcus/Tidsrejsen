extends CharacterBody2D

# === Parametre ===
var max_health = Gamestate.enemy_max_health + Gamestate.levels[Gamestate.current_level].extra_enemy_health + Gamestate.waves_completed * 0.08
var move_speed = Gamestate.enemy_move_speed + Gamestate.waves_completed * 3
var sprite_frames: SpriteFrames

# === State ===
var current_health: int = 0
var event_log: Array = []
var current_time: float = 0.0
var is_dead: bool = false
var time_since_death: float = 0.0
var death_time: float = -1.0  

var end_reached = false

var thisRow: int

const MAX_DEAD_TIME := 10.0

# === Hit flash ===
var is_hit: bool = false
var hit_timer: float = 0.0
const hit_duration: float = 0.1

# === Nodes ===
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Area2D
@onready var hit_shape: CollisionShape2D = $Area2D/CollisionShape2D

signal enemy_die
signal enemy_revive

func _ready():
	current_health = max_health

	if sprite_frames and sprite_frames.has_animation("walk"):
		anim_sprite.sprite_frames = sprite_frames
		anim_sprite.play("walk")
	else:
		push_warning("Missing sprite_frames or 'walk' animation.")

	hitbox.connect("area_entered", Callable(self, "_on_area_entered"))

func _physics_process(delta):
	if Gamestate.gameover:
		anim_sprite.stop()
		anim_sprite.visible=false
		return
	if end_reached == true:
		return
		
	if is_hit:
		hit_timer -= delta
		if hit_timer <= 0:
			is_hit = false
			anim_sprite.modulate = Color(1, 1, 1)
			if !is_dead:
				anim_sprite.play("walk")
		return

	if Gamestate.is_rewinding:
		_process_rewind(delta)
		if !is_dead:
			anim_sprite.play_backwards("walk")
	else:
		if is_dead:
			time_since_death += delta
			current_time += delta  
			if time_since_death >= MAX_DEAD_TIME:
				queue_free()
			return

		_process_movement(delta)
		anim_sprite.play("walk")
		current_time += delta

func _process_movement(delta):
	velocity = Vector2(-move_speed, 0)
	move_and_slide()

func _process_rewind(delta):
	current_time -= delta

	velocity = Vector2(move_speed, 0)
	move_and_slide()

	while event_log.size() > 0 and event_log[-1]["time"] > current_time:
		var event = event_log.pop_back()
		match event["type"]:
			"damage":
				# SIKE! NO TAKE BACKSIES
				return
				current_health += event["amount"]
			"died":
				revive()

func take_damage(amount: int):
	if is_dead:
		return

	hit_flash()
	current_health -= amount

	if current_health <= 0:
		die()
		return
		
	event_log.append({
		"time": current_time,
		"type": "damage",
		"amount": amount
	})

func die():
	if is_dead:
		return

	is_dead = true
	time_since_death = 0.0
	death_time = current_time

	event_log.append({
		"time": current_time,
		"type": "died"
	})

	hide()
	hitbox.set_deferred("monitoring", false)
	hit_shape.set_deferred("disabled", true)
	Gamestate.money += Gamestate.money_per_enemy * Gamestate.levels[Gamestate.current_level].extra_money_bonnie_factor
	
	emit_signal('enemy_die')

func revive():
	# SIKE! NO REWIND ANYMORE 
	return
	is_dead = false
	current_health = 1
	time_since_death = 0.0
	death_time = -1.0

	show()
	set_physics_process(true)
	set_process(true)
	hitbox.set_deferred("monitoring", true)
	hit_shape.set_deferred("disabled", false)
	anim_sprite.play("walk")
	
	emit_signal('enemy_revive')

func hit_flash():
	is_hit = true
	hit_timer = hit_duration
	anim_sprite.modulate = Color(1, 0.2, 0.2)
	anim_sprite.play("hit")

func _on_area_entered(area: Area2D):
	if end_reached == true:
		return
		
	if !Gamestate.is_rewinding:
		if is_dead:
			return 

		if area.is_in_group("bullets"):
			take_damage(area.damage)
			Sound.play_sound("EnemyDamaged")
			
		if area.name == "TurretHitZone":
			end_reached = true
			move_speed = 0
			anim_sprite.play('hit_turret')
			anim_sprite.frame_changed.connect(_on_hit_animation)
			Sound.play_sound("TurretDamaged")

func _on_hit_animation():
	if anim_sprite.animation == "hit_turret" and anim_sprite.frame == anim_sprite.sprite_frames.get_frame_count("hit_turret") - 1:
		emit_signal('enemy_die')
		Gamestate.health -= 1
		queue_free()
