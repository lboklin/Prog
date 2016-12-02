extends Area2D

# Your Prog's very own beautiful color scheme
export(Color) var primary_color
export(Color) var secondary_color

const WEP_CD = 1.0 					# Weapon cooldown
const JUMP_CD = 0.2 				# Jump cooldown after landing
const MAX_SPEED = 1500				# Max horizontal (ground) speed
const MAX_JUMP_RANGE = 1000			# How far you can jump from any given starting pos

# State enums
enum {IDLE, DEAD, RESPAWNING, MOVING, ATTACKING, STUNNED, BUSY}
enum Power {ON, OFF}

var state = IDLE setget set_state, get_state

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


# This method mutates the state of this instance
func update_states():

	var delta = get_fixed_process_delta_time()

	if motion.length() > 0:
		if not is_state(MOVING): return set_state(MOVING)
	elif is_state(MOVING): return set_state(IDLE)

	if stunned_timer > 0:
		stunned_timer -= delta
		if not is_state(STUNNED): return set_state(STUNNED)
	elif is_state(STUNNED): return set_state(IDLE)

	if action_timer > 0:
		action_timer -= delta
		if not is_state(BUSY): return set_state(BUSY)
	elif is_state(BUSY): return set_state(IDLE)

	if respawn["respawn_timer"] > 0:
		respawn["respawn_timer"] -= delta
		if not is_state(DEAD): return set_state(DEAD)
	elif is_state(DEAD): return set_state(RESPAWNING)

	shield["state"] = ON if shield["duration_timer"] > 0 else OFF
	if shield["state"] == ON: shield["duration_timer"] -= delta

	weapon["state"] = OFF if weapon["cooldown_timer"] > 0 else ON
	if weapon["state"] == OFF: weapon["cooldown_timer"] -= delta


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


sync func look_towards(point):

	var delta = get_fixed_process_delta_time()
	var look_towards = point - self.get_pos()
	look_towards.y *= 2

	# Need to compensate with offset of the look_towards because the viewport only includes quadrant IV so sprite had to be moved into it
	# Don't waste any more time looking at this. Just leave it. This is how it is.
	var insignia = get_node("Sprite/Insignia/InsigniaViewport/InsigniaSprite")
	var dir_compensated = look_towards + insignia.get_pos()

	var angle = insignia.get_angle_to(dir_compensated)
	var s = sign(angle)
	angle = abs(angle)

	var rot_speed = 2
	insignia.rotate(min(angle, (delta*rot_speed*angle*angle)+0.1)*s)


func hit():

	if self.state != DEAD:
		self.state = DEAD
		self.set_monitorable(false)
		self.set_hidden(true)

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
		death_anim.set_pos(self.get_pos())
		get_parent().add_child(death_anim)

		print(get_name() + " was killed and will be back in ", self.respawn_timer)


func respawn():

	self.dead = false
	self.set_monitorable(true)

	self.shielded_timer = 2
	self.set_pos(rand_loc(Vector2(0,0), 0, 1000))
	self.jump["destinations"] = [self.get_pos()]


func attack(loc):

	return
#	var not_the_time_to_use_that = moving || busy
#	if self.state == IDLE and self.weapon_state == Power.ON:
#
#		## PLACEHOLDER ##
#		GameRound.points += 1
#		#################
#
#		# Spawn projectile
#		var character_pos = self.get_pos()
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



func stop_moving():

	self.motion = Vector2(0,0)
	set_pos(self.jump["destinations"][0])
	self.state = IDLE

	self.jump["destinations"].pop_front()
	self.jump["initial_pos"] = null
	self.set_monitorable(true)
	self.set_z(1) # Back to ground level
	self.get_node("Sprite").set_pos(Vector2(0, 0))
	self.stunned_timer = JUMP_CD


func move_towards_destination():

	self.set_z(3) # To appear above the others
	self.set_monitorable(false)

	var dist_covered = self.get_pos() - self.jump["initial_pos"]
	var dist_total = self.jump["destinations"][0] - self.jump["initial_pos"]
	var dir = self.jump["destinations"][0] - self.get_pos()

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

	self.get_node("Sprite").set_pos(Vector2(0, height))
	self.get_node("Shadow").set_scale(Vector2(scale, scale))
	self.get_node("Shadow").set_opacity(scale)

	var delta = get_fixed_process_delta_time()
	motion = dir * speed * delta
	motion.y /= 2
	set_pos(self.get_pos() + motion)


func should_be_moving():

	var pos = self.get_pos()
	var should = false
	var limit = 2 # Jump queue limit
	var dests = self.jump["destinations"]

	if dests.size() < 1: return false
	elif dests.size() > limit: dests.resize(limit)

	var dist = pos.distance_to(dests[0])
	return true if is_state(MOVING) and self.motion.length() > dist else false


#####################################################################
#####################################################################
#####################################################################
