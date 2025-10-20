extends Area2D

@export var speed: float = Gamestate.bullet_speed
@export var direction: Vector2 = Vector2.RIGHT
@export var rewind_window: float = Gamestate.max_rewind_time
@export var max_lifetime: float = 30.0
@export var right_bound: float = 1000.0
@export var left_bound: float = -100.0

@onready var hit_shape: CollisionShape2D = $CollisionShape2D

var start_position: Vector2
var current_time: float = 0.0
var death_time: float = -1.0
var damage = Gamestate.bullet_damage

func _ready() -> void:
	add_to_group("bullets")
	direction = direction.normalized()
	start_position = global_position
	connect("body_entered", Callable(self, "_on_hit"))
	connect("area_entered", Callable(self, "_on_hit"))

func _physics_process(delta: float) -> void:
	if Gamestate.is_rewinding:
		current_time -= delta
	else:
		current_time += delta

		# Off-screen or too old
		var pos = start_position + direction * speed * current_time
		if death_time < 0.0:
			if pos.x > right_bound or pos.x < left_bound:
				death_time = current_time

		# Remove after lifetime or rewind window expires
		if current_time >= max_lifetime:
			queue_free()
		elif death_time >= 0.0 and (current_time - death_time) > rewind_window:
			queue_free()

	# Apply position and state
	_apply_state()

func _apply_state() -> void:
	if current_time < 0.0:
		visible = false
		hit_shape.disabled = true
		return

	var alive = death_time < 0.0 or current_time < death_time
	visible = alive
	hit_shape.disabled = not alive

	if alive:
		var t = clamp(current_time, 0.0, death_time) if death_time >= 0.0 else current_time
		global_position = start_position + direction * speed * t

func _on_hit(body: Node) -> void:
	if death_time < 0.0:
		death_time = current_time
