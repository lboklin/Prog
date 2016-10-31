
extends KinematicBody2D

var travel_time = 0
var advance_dir=Vector2(1,0)
const ADVANCE_SPEED = 1500.0

var hit=false

func _on_animation_finished():
	queue_free()

func _fixed_process(delta):
	
	if hit:
		return
	
	travel_time += delta
	
	if travel_time > 10:
		queue_free()
		
	var motion = advance_dir*delta*ADVANCE_SPEED
	motion.y *= GLOBALS.VSCALE
	move(motion)
	if is_colliding():
		get_node("anim").play("explode")
		# Stop exploded projectiles from colliding with each other
		get_node("shape").queue_free() 
		var collider = get_collider()
		if collider.get_name() == "CharacterModel":
			collider.die()
			print(collider)
		hit=true

func _ready():
	get_node("anim").connect("finished", self, "_on_animation_finished")
	# Initialization here
	set_fixed_process(true)
	pass


