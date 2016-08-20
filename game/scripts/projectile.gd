
extends KinematicBody2D

# member variables here, example:
# var a=2
# var b="textvar"

var advance_dir=Vector2(1,0)
const ADVANCE_SPEED = 1800.0

var hit=false

func _fixed_process(delta):
	
	if (hit):
		return
	var motion = advance_dir*delta*ADVANCE_SPEED
	motion.y *= GLOBALS.VSCALE
	move(motion)
	if (is_colliding()):
		get_node("anim").play("explode")
		hit=true

func _ready():
	# Initialization here
	set_fixed_process(true)
	pass


