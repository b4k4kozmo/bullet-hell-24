extends Area2D

## Longest a bullet may live regardless of where it is. The normal despawn path
## is screen_exited; this is the backstop for bullets that never leave the view,
## and for ones spawned off-screen that therefore never "exit" it.
##
## The notifier here is deliberately a VisibleOnScreenNotifier2D, not an
## Enabler2D. The Enabler sets process_mode = DISABLED on this node while it is
## off-screen, which freezes the timer below along with everything else - a
## bullet that spawned off-screen would then never move, never exit the screen,
## and never expire.
const MAX_LIFETIME := 12.0

@export var texture_array: Array[Texture2D]

var speed := 100.0
var direction := Vector2.RIGHT
var bullet_type: int = 0

var player_bullet: bool
var player_spiral_bullet: bool
var enemy_bullet: bool


func _ready() -> void:
	# Enemy fire scales with difficulty; the player's shots do not.
	if not player_bullet:
		speed *= Difficulty.bullet_speed_mult
	$Lifetime.wait_time = MAX_LIFETIME
	$Lifetime.start()


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_screen_exited() -> void:
	queue_free()


func _on_lifetime_timeout() -> void:
	queue_free()


func set_property(type: int) -> void:
	bullet_type = type
	$Sprite2D.texture = texture_array[type]


func _on_body_entered(body: Node) -> void:
	if body.has_method("set_status"):
		body.set_status(bullet_type)
	if player_bullet and body.is_in_group("enemy"):
		queue_free()
	elif enemy_bullet and body.is_in_group("player"):
		queue_free()


func _on_timer_timeout() -> void:
	# Spins the shuriken sprite between its two frames.
	if bullet_type == 4:
		set_property(5)
	elif bullet_type == 5:
		set_property(4)


func _on_area_entered(area: Area2D) -> void:
	# Player shurikens cancel enemy bullets.
	if player_spiral_bullet and "enemy_bullet" in area and area.enemy_bullet:
		area.queue_free()
		$DespawnTimer.start()


func _on_despawn_timer_timeout() -> void:
	queue_free()
