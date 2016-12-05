extends Area2D

# Your Prog's very own beautiful color scheme
export(Color) var primary_color
export(Color) var secondary_color

const WEP_CD				= 1.0 	# Weapon cooldown
const JUMP_CD				= 0.2 	# Jump cooldown after landing
const MAX_SPEED				= 1500	# Max horizontal (ground) speed
const MAX_JUMP_RANGE		= 1000	# How far you can jump from any given starting pos

# State enums
enum {IDLE, DEAD, RESPAWNING, MOVING, ATTACKING, STUNNED, BUSY}
enum Power {ON, OFF}

var state = IDLE setget set_state, get_state

slave var slave_pos 		= Vector2()
slave var slave_atk_loc 	= Vector2()
slave var slave_mouse_pos 	= Vector2()
slave var slave_motion 		= Vector2()
slave var slave_focus		= Vector2()

# Counters
var points				= 0

# Timers
var stunned_timer 		= 0.0
var action_timer 		= 0.0

var motion 				= Vector2()

## Dicts ##

var jump = {
	"initial_pos" 		: null,
	"destinations"		: []
}

var weapon = {
	"state" 			: Power.ON,
	"target_loc"		: null,
	"cooldown_timer"	: 0.0
}

var shield = {
	"state"				: Power.ON,
	"duration_timer"	: 2.0		# Spawn in with 2 sec protective shield
}

var respawn = {
	"time_of_death" 	: null,
	"respawn_timer" 	: 0.0
}


##########################
## SetGetters / queries ##
##########################


func set_state(new_st):
	state = new_st
	return new_st


func get_state():
	return state


func is_state(st):
	return true if st == get_state() else false


##########################


# This method modifies the member vars
func update_states():

	var delta = get_fixed_process_delta_time()

	# Check if moving
	if motion.length() > 0:
		if not is_state(MOVING): return set_state(MOVING)
	elif is_state(MOVING): return set_state(IDLE)

	# Check if stunned
	if stunned_timer > 0:
		stunned_timer -= delta
		if not is_state(STUNNED): return set_state(STUNNED)
	elif is_state(STUNNED): return set_state(IDLE)

	# Check if performing an action
	if action_timer > 0:
		action_timer -= delta
		if not is_state(BUSY): return set_state(BUSY)
	elif is_state(BUSY): return set_state(IDLE)

	# Check if supposed to respawn (and if dead)
	if respawn["respawn_timer"] > 0:
		respawn["respawn_timer"] -= delta
		if not is_state(DEAD): return set_state(DEAD)
	elif is_state(DEAD): return set_state(RESPAWNING)

	# Check the state of the shield as necessary
	shield["state"] = ON if shield["duration_timer"] > 0 else OFF
	if shield["state"] == ON: shield["duration_timer"] -= delta

	# Check the state of the weapon and update if necessary
	weapon["state"] = OFF if weapon["cooldown_timer"] > 0 else ON
	if weapon["state"] == OFF: weapon["cooldown_timer"] -= delta


# Produce a random point inside a circle of a given radius
func rand_loc(location, radius_min, radius_max):

	var new_radius = rand_range(radius_min, radius_max)
	var angle = deg2rad(rand_range(0, 360))
	var point_on_circ = Vector2(new_radius, 0).rotated(angle)
	return location + point_on_circ


# Take a probability percentage and return true or false after diceroll
func success(chance):

	var delta = get_fixed_process_delta_time()
	var diceroll = rand_range(0, 100)
	randomize()

	if diceroll <= (chance * delta):
		return true


##################################################

# Rotates the insignia sprite towards the given point (point is not relative to prog)
master func look_towards(point):

	var delta = get_fixed_process_delta_time()
	var dir = point - get_pos()
	dir.y *= 2
	dir = dir.normalized()

	# Need to compensate with offset of the dir because the
	# viewport only includes quadrant IV so sprite had to be moved into it
	# Don't waste any more time looking at this. Just leave it. This is how it is.
	var insignia = find_node("InsigniaSprite")
	var dir_compensated = dir + insignia.get_pos()
#	var offset = Vector2(256, 256) # The pos of the insignia sprite
#	var dir_compensated = dir + offset
	var angle = insignia.get_angle_to(dir_compensated)
	var s = sign(angle)
	angle = abs(angle)
	var rot_speed = 2
	var rot = min(angle, (delta*rot_speed*angle*angle)+0.1)*s
	insignia.rotate(rot)
	insignia.rpc("rotate", rot)


# Get hit (and die - at least until better implementation is implemented)
func hit():

	if self.state != DEAD:
		self.state = DEAD
		set_monitorable(false)
		set_hidden(true)

		## Reset all active timers and states ##
		self.weapon["cooldown_timer"] = 0
		self.stunned_timer = 0
		self.action_timer = 0

		self.weapon["target_loc"] = null
		self.jump["initial_pos"] = null

		update_states()
		#########################################

		# Set respawn timer based on elapsed game round time
		self.time_of_death = GameRound.round_timer
		self.respawn_timer = self.time_of_death / 10
		print(self.respawn_timer)

		var death_anim = preload("res://common/DeathEffect.tscn").instance()
		death_anim.set_pos(get_pos())
		get_parent().add_child(death_anim)

		print(get_name() + " was killed and will be back in ", self.respawn_timer)


# Well, this one makes you respawn
func respawn():

	set_monitorable(true) # Enable detection by other bodies and areas
	set_pos(rand_loc(Vector2(0,0), 0, 1000))

	self.shield["duration_timer"] = 2
	self.jump["destinations"] = [get_pos()]


# Attack given location (not relative to prog)
master func attack(loc):

	return
#	var not_the_time_to_use_that = moving || busy
#	if self.state == IDLE and self.weapon_state == Power.ON:
#
#		## PLACEHOLDER ##
#		GameRound.points += 1
#		#################
#
#		# Spawn projectile
#		var character_pos = get_pos()
#		var projectile = preload("res://common/Projectile/Projectile.tscn").instance()
#		var attack_dir = (self.weapon["target_loc"] - character_pos)
#		attack_dir.y *= 2
#		attack_dir = attack_dir.normalized()
#
#		projectile.destination = self.weapon["target_loc"]
#		projectile.set_global_pos( character_pos + attack_dir * Vector2(60,20) )
#		get_parent().add_child(projectile)
#
#		self.weapon["cooldown_timer"] = weapon_cooldown
#		self.action_timer = 0.2


# Go to place next in jump dest dict
master func move_towards_destination():

	set_z(3) # To appear above the others
	set_monitorable(false) # Disable detection by other bodies and areas
	var pos = get_pos()
	var dest = self.jump["destinations"][0]

	if not is_state(MOVING): self.jump["initial_pos"] = pos

	var dist_covered = pos - self.jump["initial_pos"]
	var dist_total = dest - self.jump["initial_pos"]
	var dir = dest - pos

	dist_covered.y *= 2
	dist_total.y *= 2
	dir.y *= 2

	dist_covered = dist_covered.length()
	dist_total = dist_total.length()
	dir = dir.normalized()

	var speed = max(min(dist_total*2, self.MAX_SPEED), 500)

	## GLORIOUS JUMP ANIMATION ##
	var completion = dist_covered / dist_total
	var height = sin(deg2rad(180*completion)) * dist_total * -0.2
	var scale = 0.5 - 0.08 * sin(deg2rad(-1 * height))

	get_node("Sprite").set_pos(Vector2(0, height))
	get_node("Shadow").set_scale(Vector2(scale, scale))
	get_node("Shadow").set_opacity(scale)

	var dist = pos.distance_to(dest)
	# Whether about to reach destination
	var coming_in_hot = is_state(MOVING) && self.motion.length() >= dist

	var delta = get_fixed_process_delta_time()
	motion = dir * speed * delta
	motion.y /= 2
	var new_pos = pos + motion
	set_pos(new_pos if not coming_in_hot else dest)
	rset_unreliable("slave_pos", get_pos())


# This one stops your movement..
master func stop_moving():

	self.motion = Vector2(0,0)
	set_pos(self.jump["destinations"][0])
	self.state = IDLE

	self.jump["destinations"].pop_front()
	self.jump["initial_pos"] = get_pos()
	set_monitorable(true)
	set_z(1) # Back to ground level
	get_node("Sprite").set_pos(Vector2(0, 0))
	self.stunned_timer = JUMP_CD


# This chec... ugh just read the name
master func should_be_moving():
	var limit = 2 # Jump queue limit
	var dests = self.jump["destinations"]
	# Check if any jumps are queued
	if dests.size() < 1: return false
	# Limit amount of queued jumps allowed, add one because active dest is not cleared until landing
	if dests.size() > limit: self.jump["destinations"].resize(limit + 1)
	return true if dests[0] != get_pos() else false


#####################################################################
#####################################################################
#####################################################################
