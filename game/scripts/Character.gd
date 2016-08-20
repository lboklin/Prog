extends KinematicBody2D

########################
### Global variables ###
########################
# ATTK_CD = attack cooldown
# DEST_R = radius for destination approximation 
# MAX_SPEED =  max movement ground_speed (magnitude)
# ROLL_ACCEL = acceleration while rolling
# JUMP_CD = cooldown for jump
# ROT_SPEED = (visual) turning ground_speed for character
const ATTK_CD = 0.5
const DEST_R = 5.0
const MAX_SPEED = 1000
const ROLL_ACCEL = 5.0
const JUMP_CD = 0.1
const ROT_SPEED = 20

## Cooldowns
# Set and updated by status update func
var attk_cd = 0
var rooted_timer = 0
var stunned_timer = 0
var busy_cd = 0
var attk_dur = 0

## Impediments
# Set and updated by status update func
var attacking = false		# Shared with fixed process and set by attack function
var rooted = false
var stunned = false
var impeded = false			# Shared with functions here and there
var busy = false

## Movement booleans
var no_roll = true			# Shared between input process and movement functions
var rolling = false
var jumping = false			# Shared with fixed process
var moving = false

var start_pos = Vector2()	# Shared between input process and movement functions
var destination = Vector2()
var ground_motion = Vector2()

## Misc
var command_queue = []
var mouse_pos = Vector2()	# Shared all over

## action dicts
var roll = {
	"start_pos"			:	Vector2(),
	"target_coords"		:	Vector2()
}
var jump = {
	"start_pos"			:	Vector2(),
	"target_coords"		:	[]
}
var attack = {
	"target_coords"		:	Vector2()
}

# for fun
var rand_color = 0


#########################
#########################
#########################




func draw_empty_circle(circle_center, circle_radius, color, resolution):
	var draw_counter = 1
	var line_origin = Vector2()
	var line_end = Vector2()
	line_origin = circle_radius + circle_center

	while draw_counter <= 360:
		line_end = circle_radius.rotated(deg2rad(draw_counter)) + circle_center
		draw_line(line_origin, line_end, color)
		draw_counter += 1 / resolution
		line_origin = line_end

	line_end = circle_radius.rotated(deg2rad(360)) + circle_center
	draw_line(line_origin, line_end, color)
	update()


func update_states(delta):
	
	# Movement status
	if jumping  or rolling:
		moving = true
	else:
		moving = false
	
	# Various status effects and their cooldowns
	if rooted_timer > 0:
		rooted = true
		rooted_timer -= delta
		if rooted_timer <= 0:
			rooted = false
		
	if stunned_timer > 0:
		stunned = true
		stunned_timer -= delta
		if stunned_timer <= 0:
			stunned = false
		
	if busy_cd > 0:
		busy = true
		busy_cd -= delta
		if busy_cd <= 0:
			busy = false

		# apply impeded status if appropriate
	if (rooted or stunned or busy) and not impeded:
		impeded = true
	else:
		impeded = false
		
	# apply busy status if busy doing stuff
	if attacking:
		busy = true
	else:
		busy = false
	
	# attack cooldowns
	if attk_cd > 0:
		attk_cd -= delta
	
	# attack duration
	if attk_dur > 0:
		attacking = true
		attk_dur -= delta
		if attk_dur <= 0:
			attacking = false
			command_queue.erase("attack")


func dir_vscaled(from, to):
	
	var dir_vscaled = to - from
	dir_vscaled.y /= GLOBALS.VSCALE # Compensate for velocity_magnitude.y*=GLOBALS.VSCALE
	dir_vscaled = dir_vscaled.normalized()
	return dir_vscaled


func face_dir(focus):
	
	var face_dir = dir_vscaled(get_pos(), focus) * -1
	# Need to compensate with offset of the face_dir because the viewport only includes quadrant IV so sprite had to be moved into it 
	var insignia = get_node("PlayerModel/InsigniaViewport/Insignia")
	var dir_compensated = face_dir + insignia.get_pos()
	var angle = insignia.get_angle_to(dir_compensated)
	var s = sign(angle)
	angle = abs(angle)
	insignia.rotate(min(angle, get_fixed_process_delta_time()*ROT_SPEED)*s)
	
#func abort_actions_except(exception):
#	jump.clear()
# To do: Figure out a good way to do this

func attack():
	
	stop_moving()
#	abort_actions_except("attack")
	
	attk_cd = ATTK_CD
	attk_dur = 0.5
	
	# Spawn projectile
	if not attacking:
		var projectile = preload("res://common/Projectile/projectile.tscn").instance()
		var attack_dir = dir_vscaled(get_pos(), attack.target_coords)
		projectile.advance_dir = attack_dir
		projectile.set_pos( get_pos() + attack_dir * Vector2(128,64) )
		get_parent().add_child(projectile)
	

func roll():
	
	if not rolling:
		rolling = true
	
	var dir = dir_vscaled(get_pos(), roll.target_coords)
	ground_motion = ground_motion.linear_interpolate(MAX_SPEED*dir,get_fixed_process_delta_time()*ROLL_ACCEL)
	ground_motion.y *= GLOBALS.VSCALE
	
	move(ground_motion)


func jump():
	
	var delta = get_fixed_process_delta_time()
	var dir = dir_vscaled(get_pos(), destination)
	
	if not jumping:
		jumping = true
	
	ground_motion = dir * MAX_SPEED * delta
	var motion = ground_motion #I have my reasons
	motion.y *= GLOBALS.VSCALE
	move(motion)

func stop_moving():
	
	if jumping:
		jumping = false
		stunned_timer = JUMP_CD
	elif rolling:
		rolling = false

	set_pos(destination)
	ground_motion = Vector2()
	destination = get_pos()
	
	command_queue.pop_front()


func supposed_to_be_moving():
	
	if is_colliding():
		print(self.get_collider())
		print(get_parent().get_child(1))
		return false
	
	# For use in knowing if nearing destination
	# d2go = distance left to go
	var ground_pos = get_pos()
	var d2go = destination - ground_pos
	d2go = d2go.length()

	if ground_motion.length() < d2go:
		return true
	else:
		return false	


func go_to_destination():
		
	# Move if able, else do nothing
	if not (stunned or rooted or busy):
		if command_queue[0] == "jump":
			# Set destination only once per jump
			if not jumping:
				destination = jump.target_coords[0]
				jump.target_coords.pop_front()
			jump()
		elif command_queue[0] == "roll":
			destination = roll.target_coords
			roll()
		
	if moving and not supposed_to_be_moving():
		stop_moving()


func execute_command():
	
	# If an attack is queued
	if command_queue.find("attack") != -1:
		face_dir(attack.target_coords)
		# If not busy jumping, attack
		if not jumping and attk_cd <= 0:
			attack()
	elif moving:
		face_dir(destination)
		
	# If next command is to move
	if not attacking and not busy and command_queue.size() > 0:
		go_to_destination()


#####################################################################
#####################################################################
#####################################################################


func randloc():

	randomize()

	var screenrect = get_viewport().get_visible_rect()
	var loc = Vector2()

	loc.x = round(rand_range(screenrect.pos.x, screenrect.end.x))
	loc.y = round(rand_range(screenrect.pos.y, screenrect.end.y))

	return loc


func success(chance):

	randomize()

	if chance > 100:
		return false

	var luck_result = randi() % convert((100 / get_fixed_process_delta_time()),2)

	if luck_result <= chance:
		return true
