extends KinematicBody2D

const ADVANCE_SPEED = 2000.0
const LIFETIME = 4

var age = 0
var advance_dir = Vector2(1,0)
var attack_coords = Vector2()

var hit=false

func _on_animation_finished():

	queue_free()

func explode():

		# Stop exploded projectiles from colliding with each other
		var shape = get_node("shape")
		if not shape.is_queued_for_deletion():
			shape.queue_free()
		get_node("anim").play("explode")

func _fixed_process(delta):

	if hit:
		return

	# Despawn after lifetime has expired
	age += delta
	if age > LIFETIME:
		hit = true
		explode()

	var motion = advance_dir*delta*ADVANCE_SPEED
	motion.y /= 2
	move(motion)
	if is_colliding():

		var collider = get_collider()
		if collider.is_in_group("Mortals"):
			collider.die()
		explode()
		hit=true

func _ready():

	get_node("anim").connect("finished", self, "_on_animation_finished")

	set_fixed_process(true)