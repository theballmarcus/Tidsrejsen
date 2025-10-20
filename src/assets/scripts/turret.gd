extends CharacterBody2D

@export var bullet_scene: PackedScene

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var upgrade_button: TextureButton = $TurretPanel/TurretPanelTexture/UpgradeButton
@onready var turretPanel = $TurretPanel
@onready var nTurret = $TurretPanel/TurretPanelTexture/Turret/nTurret
@onready var nPrice = $TurretPanel/TurretPanelTexture/UpgradePrice/nPrice
@onready var nShootingSpeed = $TurretPanel/TurretPanelTexture/ShootingSpeed/nShootingSpeed
@onready var nBulletDamage = $TurretPanel/TurretPanelTexture/BulletDamage/nBulletDamage
@onready var nTurretLevel = $TurretPanel/TurretPanelTexture/TurretLevel/nTurretLevel
@onready var turretButton = $TurretButton

var turretNumber: int
var ready_to_fire: bool = false
var event_log: Array = []
var current_time: float = 0.0
var turret_state = 0 # 0 = not built, 1 = alive, 2 = upgraded

var turret_level: String

var time_value : float = 0.0
var next_shoot_time : float

# ------- Turret stuff ------- #
func _ready():
	anim_sprite.play("not_built")

	upgrade_button.connect("button_down", Callable(self, "upgrade_turret"))
	turretPanel.visible = false
	
	nTurret.text=""+str(turretNumber)
	nPrice.text=""+str(Gamestate.turret_states[turret_state + 1].price)
	nBulletDamage.text=""+str(Gamestate.turret_states[turret_state].damage)
	nShootingSpeed.text=""+str(Gamestate.turret_states[turret_state].shoot_time)
	nTurretLevel.text=""+str(turret_state)
	 
func _physics_process(delta):
	if Gamestate.current_level == turret_level:
		turretButton.visible = true
		turretButton.disabled = false
		_update_upgrade_button_state()
	else:
		turretButton.visible = false
		turretButton.disabled = true
	
	if Gamestate.current_level != turret_level:
		anim_sprite.visible = false
		upgrade_button.visible = false
		upgrade_button.disabled = true

		return
	else:
		anim_sprite.visible = true
		
	if Gamestate.game_running == false:
		return
		
	if turret_state != 0:
		if Gamestate.is_rewinding:
			time_value -= delta

			if time_value <= 0:
				time_value = Gamestate.turret_states[turret_state].shoot_time
				
			_process_rewind(delta)
		else:
			time_value += delta
			
			current_time += delta
		
			if time_value >= next_shoot_time:
				time_value = 0
				next_shoot_time = randf_range(Gamestate.turret_states[turret_state].shoot_time - 0.2, Gamestate.turret_states[turret_state].shoot_time + 0.25)
				anim_sprite.play("shoot")
				anim_sprite.frame_changed.connect(_on_frame_changed_shoot)
				ready_to_fire = true

func _on_frame_changed_deploy():
	if anim_sprite.animation == "deploy" and anim_sprite.frame == anim_sprite.sprite_frames.get_frame_count("deploy") - 1:
		anim_sprite.frame_changed.disconnect(_on_frame_changed_deploy)

		anim_sprite.play("idle")

func _on_frame_changed_shoot():
	if anim_sprite.animation == "shoot" and anim_sprite.frame == anim_sprite.sprite_frames.get_frame_count("shoot") - 1:
		anim_sprite.frame_changed.disconnect(_on_frame_changed_shoot)

		if ready_to_fire:
			shoot()
			ready_to_fire = false

		anim_sprite.play("idle")

func shoot():
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		get_tree().current_scene.add_child(bullet)
		Sound.play_sound("TurretLaser")

		# Log bullet spawn event
		event_log.append({
			"time": current_time,
			"type": "bullet_fired",
			"instance": bullet
		})

func _process_rewind(delta):
	current_time -= delta

	while event_log.size() > 0 and event_log[-1]["time"] > current_time:
		var event = event_log.pop_back()
		if event["type"] == "bullet_fired" and is_instance_valid(event["instance"]):
			event["instance"].queue_free()

	if anim_sprite.animation == "walk" and !anim_sprite.playing_backwards:
		anim_sprite.play_backwards("walk")

# ------- Button stuff ------- #
func upgrade_turret():
	if Gamestate.turret_states.has(turret_state + 1):
		var next_turret_state = Gamestate.turret_states[turret_state + 1]
		if Gamestate.money < next_turret_state.price:
			return

		Gamestate.money -= Gamestate.turret_states[turret_state+1].price

		if turret_state == 0:
			Sound.play_sound("TurretBuild")
			anim_sprite.play("deploy")
			anim_sprite.frame_changed.connect(_on_frame_changed_deploy)
			upgrade_button.texture_normal = load("res://assets/graphics/images/UpgradeTurret_BTN.png")
			upgrade_button.texture_hover = load("res://assets/graphics/images/UpgradeTurretHover_BTN.png")
			
		else:
			Sound.play_sound("TurretLevelUp")
			
		turret_state += 1

		next_shoot_time = randf_range(Gamestate.turret_states[turret_state].shoot_time - 0.2, Gamestate.turret_states[turret_state].shoot_time + 0.25)
		
		nBulletDamage.text=""+str(Gamestate.turret_states[turret_state].damage)
		nShootingSpeed.text=""+str(round_to_dec(1 / Gamestate.turret_states[turret_state].shoot_time,2))
		nTurretLevel.text=""+str(turret_state)
		if Gamestate.turret_states.has(turret_state + 1):
			nPrice.text="$"+str(Gamestate.turret_states[turret_state + 1].price)
		else:
			nPrice.text = "max"


func _update_upgrade_button_state():
	if Gamestate.turret_states.has(turret_state + 1) == false:
		upgrade_button.disabled = true
		upgrade_button.visible = false
		return
		
	upgrade_button.visible=true
	if Gamestate.money < Gamestate.turret_states[turret_state + 1].price:
		upgrade_button.disabled = true
		upgrade_button.modulate = Color(0.5, 0.5, 0.5)  # Gray out
	else:
		upgrade_button.disabled = false
		upgrade_button.modulate = Color(1, 1, 1)  # Normal

#Turret Panel Stuff
func _on_turret_button_pressed() -> void:
	if Gamestate.openTurretPanel != null:
		Gamestate.openTurretPanel.visible = false
		
	turretPanel.global_position=Vector2(575,110)
	turretPanel.visible = true
	Gamestate.openTurretPanel = turretPanel

func _on_ctp_button_pressed() -> void:
	turretPanel.visible=false

func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)
