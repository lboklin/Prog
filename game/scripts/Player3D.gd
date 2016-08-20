
extends KinematicBody2D

const VSCALE=1.0
const SHOOT_INTERVAL = 1.5

var dash = false
var max_speed = 300.0
var idle_speed = 50.0
var speed = Vector2()
var accel = 5.0
var begin = Vector2()
var end = Vector2()
var shoot_countdown=0

func _fixed_process(delta):
	if ( dash ):
		max_speed = 900.0
		accel = 10.0
	else:
		max_speed = 300.0
		accel = 5.0
		
	shoot_countdown-=delta
	var motion = speed * delta
	var pos = get_pos()
	
	var dir = Vector2()
	if (Input.is_action_pressed("up") and !dash):
		dir+=Vector2(0,-1)
		end = Vector2()
	if (Input.is_action_pressed("down") and !dash):
		dir+=Vector2(0,1)
		end = Vector2()
	if (Input.is_action_pressed("left") and !dash):
		dir+=Vector2(-1,0)
		end = Vector2()
	if (Input.is_action_pressed("right") and !dash):
		dir+=Vector2(1,0)
		end = Vector2()
	
	
	# Click to move
	if ( end != Vector2() and begin != end ):
		# Here I am trying to stop the ball from being too anal about the destination it's trying to reach
		if ( end - pos > Vector2(1,1) or end - pos < Vector2(0,0) ):
			dir = end - pos
		else:
			end = Vector2()
			dash = false
			speed = Vector2(0.3,0.3)
			motion = Vector2(0.3,0.3)
	
	if (dir!=Vector2()):
		dir=dir.normalized()
	speed = speed.linear_interpolate(dir*max_speed,delta*accel)
	var motion = speed * delta
	motion.y*=VSCALE
	motion=move(motion)
	
	if (is_colliding()):
		var n = get_collision_normal()
		motion=n.slide(motion)
		move(motion)
		speed = Vector2()

func _input(ev):
	if ( ev.type==InputEvent.MOUSE_BUTTON and ev.pressed and !dash ):
		end = ev.pos
		begin = get_pos()
		begin = get_viewport_transform().xform(begin)
		var dir = (end - get_pos()).normalized()
		if ( ev.button_index==1 ):
			if (Input.is_action_pressed("hurry") and ev.pressed ):
				if ( ev.pressed ):
					dash = true
				else:
					dash = false
		if ( ev.button_index==2 and shoot_countdown<=0 ):
			var projectile = preload("res://projectile.scn").instance()
			projectile.advance_dir=dir
			projectile.set_pos( get_global_pos() + dir * 60 )
			get_parent().add_child(projectile)
			shoot_countdown=SHOOT_INTERVAL

func _ready():
	set_process_input(true)
	set_fixed_process(true)
	pass


