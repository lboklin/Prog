extends KinematicBody2D

export var primary_color = Color()
export var secondary_color = Color()


########################
### Global variables ###
########################
# ATTK_CD = attack cooldown
# DEST_R = radius for destination approximation
# MAX_SPEED =  max movement ground_speed (magnitude)
# JUMP_CD = cooldown for jump
# ROT_SPEED = (visual) turning ground_speed for character
const ATTK_CD = 1.0
const DEST_R = 5.0
const MAX_SPEED = 1000
const JUMP_CD = 0.2
const ROT_SPEED = 2
const LIVES = 3

########################


var lives = LIVES

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
var busy = false
var disabled = false
var dead = false

## Movement booleans
var moving = false

## Movement vectors
var motion = Vector2(0,0)

## Coordinates
var character_pos = Vector2()
var character_start_pos = Vector2()
var jump_target_coords = []
var attack_coords = null

var mouse_pos = Vector2()


#########################
#########################
#########################


func update_states(delta):

	if motion.length() > 0:
		moving = true
	else:
		moving = false

	if rooted or stunned:
		disabled = true
	else:
		disabled = false

	# Various status effects and their cooldowns
	if rooted_timer > 0:
		rooted_timer -= delta
		if rooted_timer <= 0:
			rooted = false
		else:
			rooted = true

	if stunned_timer > 0:
		stunned_timer -= delta
		if stunned_timer <= 0:
			stunned = false
		else:
			stunned = true

	# attack cooldowns
	if attk_cd > 0:
		attk_cd -= delta

	# attack duration
	if attk_dur > 0:
		attk_dur -= delta
		if attk_dur <= 0:
			attacking = false
			attack_coords = null
		else:
			attacking = true


# Return a random location somewhere within the visible area
func randloc(area):

	var loc = Vector2()

	loc.x = round(rand_range(area.pos.x, area.end.x))
	loc.y = round(rand_range(area.pos.y, area.end.y))
	randomize() # New seed

	return loc


# Take a probability percentage and return true or false after diceroll
func success(delta, chance):

	var diceroll = rand_range(0, 100)
	randomize()

	if diceroll <= (chance * delta):
		return true


##################################################


# Create a transparent, ghost-like character sprite to represent it as if
# it had already arrived at its destination
func indicate(pos, anim):

	var indicator = preload("res://gui/Indicator.tscn").instance()
	indicator.set_pos(pos)
	self.get_parent().add_child(indicator)
	indicator.get_node("AnimationPlayer").play(anim)


func face_dir(delta,focus):

	var face_dir = focus - character_pos
	face_dir.y *= 2

	# Need to compensate with offset of the face_dir because the viewport only includes quadrant IV so sprite had to be moved into it
	# Don't waste any more time looking at this. Just leave it. This is how it is.
	var insignia = get_node("Sprite/Insignia/InsigniaViewport/InsigniaSprite")
	var dir_compensated = face_dir + insignia.get_pos()

	var angle = insignia.get_angle_to(dir_compensated)
	var s = sign(angle)
	angle = abs(angle)

	insignia.rotate(min(angle, (delta*ROT_SPEED*angle*angle)+0.1)*s)


func die():

	if not is_queued_for_deletion():
		dead = true
		# Dramatic animation goes here
		print(get_name() + " was killed.")
		lives -= 1
		get_node("CollisionPolygon2D").set_trigger(true)


func respawn():
	dead = false
	set_pos(randloc(get_viewport().get_visible_rect()))
	get_node("CollisionPolygon2D").set_trigger(false)


func attack():

	if not moving and not attacking and attk_cd <= 0:
		# Spawn projectile
		var projectile = preload("res://common/Projectile/Projectile.tscn").instance()
		var attack_dir = (attack_coords - character_pos)
		attack_dir.y *= 2
		attack_dir = attack_dir.normalized()

		# Initial position and direction
#		projectile.advance_dir = attack_dir
		projectile.destination = attack_coords
		projectile.set_global_pos( character_pos + attack_dir * Vector2(60,20) )
		get_parent().add_child(projectile)

		attk_cd = ATTK_CD
		attk_dur = 0.2


func stop_moving():

	motion = Vector2(0,0)
	set_pos(jump_target_coords[0])
	moving = false

	jump_target_coords.pop_front()
	character_start_pos = character_pos
	get_node("CollisionPolygon2D").set_trigger(false)
	self.set_z(1)
	stunned_timer = JUMP_CD


func move_towards_destination(delta):

	if not moving:
		get_node("CollisionPolygon2D").set_trigger(true)
		self.set_z(3)

	var travel_dist = jump_target_coords[0] - character_start_pos
	travel_dist.y *= 2
	travel_dist = (travel_dist).length()

	var dir = jump_target_coords[0] - character_pos
	dir.y *= 2
	dir = dir.normalized()

#	if motion == Vector2(0,0):
	var speed = max(min(travel_dist*2, 1000), 500)

	motion = dir * speed * delta
	motion.y /= 2
#	set_pos(character_pos + motion)
	move(motion)


func supposed_to_be_moving():

	# Check if no jumps are queued
	if jump_target_coords.size() == 0:
		return false

	# Keep number of jumps in queue under a limit
	if jump_target_coords.size() > 3:
		jump_target_coords.resize(3)

	# If not disabled and not at dest
	if not disabled and character_pos != jump_target_coords[0]:
		# If speed is greater than distance to dest
		if moving and motion.length() > character_pos.distance_to(jump_target_coords[0]):
			return false
#			if motion.length() >= (jump_target_coords[0] - character_pos).length():
#			if motion.length() > character_pos.distance_to(jump_target_coords[0]).length():
		else:
			return true
	else:
		false


#####################################################################
#####################################################################
#####################################################################


func act(delta):

	character_pos = get_pos()

	# Update the state the character is in
	update_states(delta)


	# Do nothing if stunned
	if stunned:
		return

	if supposed_to_be_moving():
		move_towards_destination(delta)
		face_dir(delta,jump_target_coords[0])
	elif moving:
		stop_moving()

	if not disabled: # If idling, always stay turned towards pointer location
		if attack_coords != null:
			attack()

		if attacking:
			face_dir(delta,attack_coords)
		elif moving:
			face_dir(delta,jump_target_coords[0])
		elif get_name() == "Player":
			face_dir(delta,mouse_pos)
