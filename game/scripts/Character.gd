extends Area2D

# Your Prog's very own beautiful color scheme
export(Color) var primary_color
export(Color) var secondary_color

const WEP_CD = 1.0  # Weapon cooldown
const JUMP_CD = 0.2  # Jump cooldown after landing
const MAX_SPEED = 1500  # Max horizontal (ground) speed
const MAX_JUMP_RANGE = 1000  # How far you can jump from any given starting pos
const JUMP_Q_LIM = 2  # Jump queue limit

# State enums
enum {IDLE, DEAD, RESPAWNING, MOVING, ATTACKING, STUNNED, BUSY}
enum Power {ON, OFF}

var state = IDLE setget set_state, get_state

slave var slave_pos = Vector2()
slave var slave_atk_loc = Vector2()
slave var slave_motion = Vector2()
slave var slave_focus = Vector2()

# Counters
var points = 0

# Timers
var stunned_timer = 0.0
var action_timer = 0.0

## Dicts  ##

var jumps = {
	"active_jump_origin": null,
	"destinations"		: []
} setget set_jumps, get_jumps

var weapon_state = {
	"state" 			: Power.ON,
	"target_loc"		: null,
	"cooldown_timer"	: 0.0
} setget set_weapon_state, get_weapon_state

var shield_state = {
	"state"				: Power.ON,
	"duration_timer"	: 2.0  # Spawn in with 2 sec protective shield
} setget set_shield_state, get_shield_state

var respawn_state = {
	"time_of_death" 	: null,
	"respawn_timer" 	: 0.0
} setget set_respawn_state, get_respawn_state


##########################
## SetGetters / queries  ##
##########################

#-------------
# General state

func set_state(new_st):
	if not is_state(new_st):
		if is_state(MOVING):
			stop_moving()
	state = new_st
	return new_st

func get_state():
	return state

func is_state(st):
	return true if st == get_state() else false

#-------------
#-------------
# Jump state

func set_jumps(origin, dests):
	jumps = {
	"active_jump_origin" : origin,
	"destinations" : dests
	}

	return

func get_jumps():
	return jumps

#-------------
#-------------
# Weapon state

func set_weapon_state(power, t_loc, cd):
	weapon_state = {
	"state" 			: power,
	"target_loc"		: t_loc,
	"cooldown_timer"	: cd
	}

	return

func get_weapon_state():
	return weapon_state

#-------------
#-------------
# Shield state

func set_shield_state(state, dur):
	shield_state = {
	"state" : state,
	"duration_timer" : dur
	}

	return

func get_shield_state():
	return shield_state

#-------------
#-------------
# Respawn state

func set_respawn_state(tod, timer):
	respawn_state = {
	"time_of_death" 	: tod,
	"respawn_timer" 	: timer
	}

	return

func get_respawn_state():
	return respawn_state

#-------------

##########################


# This method modifies the member vars
func update_states(delta):  ## IMPURE

  # Check state of motion and stuff
	var dests = get_jumps()["destinations"]
	if dests.size() > 0:
		while dests.size() > 0 and get_pos() == dests[0]:
			dests.pop_front()
			set_jumps(get_pos(), dests)

  # Check if stunned
	if stunned_timer > 0:
		stunned_timer -= delta
		if not is_state(STUNNED):
			return set_state(STUNNED)
	elif is_state(STUNNED):
		return set_state(IDLE)

  # Check if performing an action
	if action_timer > 0:
		action_timer -= delta
		if not is_state(BUSY):
			return set_state(BUSY)
	elif is_state(BUSY):
		return set_state(IDLE)

  # Check if supposed to respawn (and if dead)
	var respawn = get_respawn_state()
	if respawn["respawn_timer"] > 0:
		respawn["respawn_timer"] -= delta
		set_respawn_state(respawn)
		if not is_state(DEAD):
			return set_state(DEAD)
	elif is_state(DEAD):
		return set_state(RESPAWNING)

  # Check the state of the shield as necessary
	var shield = get_shield_state()
	shield["state"] = Power.ON if shield["duration_timer"] > 0 else Power.OFF
	if shield["state"] == Power.ON:
		shield["duration_timer"] -= delta
	set_shield_state(shield["state"], shield["duration_timer"])

  # Check the state of the weapon and update if necessary
	var weapon = get_weapon_state()
	weapon["state"] = Power.OFF if weapon["cooldown_timer"] > 0 else Power.ON
	if weapon["state"] == Power.OFF:
		weapon["cooldown_timer"] -= delta
	set_weapon_state(weapon["state"], weapon["target_loc"], weapon["cooldown_timer"])


# Produce a random point inside a circle of a given radius
func rand_loc(location, radius_min, radius_max):  ## IMPURE

	var new_radius = rand_range(radius_min, radius_max)
	var angle = deg2rad(rand_range(0, 360))
	var point_on_circ = Vector2(new_radius, 0).rotated(angle)
	return location + point_on_circ


# Take a probability percentage and return true or false after diceroll
func success(chance):  ## IMPURE

	var delta = get_fixed_process_delta_time()
	var diceroll = rand_range(0, 100)
	randomize()

	if diceroll <= (chance * delta):
		return true


##################################################

# Rotates the insignia sprite towards the given point (point is not relative to prog)
master func look_towards(point):  ## IMPURE

	var delta = get_fixed_process_delta_time()
	var dir = point - get_pos()
	dir.y *= 2
	dir = dir.normalized()

  # Need to compensate with offset of the dir because the
  # viewport only includes quadrant IV so sprite had to be moved into it
  # Don't waste any more time looking at this. Just leave it. This is how it is.
	var insignia = find_node("InsigniaSprite")
	var dir_compensated = dir + insignia.get_pos()
	var angle = insignia.get_angle_to(dir_compensated)
	var s = sign(angle)
	angle = abs(angle)
	var rot_speed = 2
	var rot = min(angle, (delta*rot_speed*angle*angle)+0.1)*s
	insignia.rotate(rot)
#	insignia.rpc("rotate", rot)


# Get hit (and die - at least until better implementation is implemented)
func hit():  ## IMPURE

	if self.state != DEAD:
		self.state = DEAD
		set_monitorable(false)
		set_hidden(true)

  ## Reset all active timers and states  ##
		self.weapon["cooldown_timer"] = 0
		self.stunned_timer = 0
		self.action_timer = 0

		self.weapon["target_loc"] = null
		self.jump["active_jump_origin"] = null

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
func respawn():  ## IMPURE

	set_monitorable(true)  # Enable detection by other bodies and areas
	set_pos(rand_loc(Vector2(0,0), 0, 1000))

	set_shield_state(Power.ON, 2.0)
	set_jumps(null, [])


# Attack given location (not relative to prog)
master func attack(loc):  ## IMPURE

#	var not_the_time_to_use_that = moving || busy
	return set_state(BUSY if is_state(IDLE) && self.weapon["state"] == ON else get_state())
#
#  ## PLACEHOLDER  ##
#		GameRound.points += 1
#  #################
#
#  # Spawn projectile
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


# This one stops your movement..
sync func stop_moving():  ## IMPURE
	set_monitorable(true)  # Can be detected by other bodies and areas
	set_z(1)  # Back onto ground
	get_node("Sprite").set_pos(Vector2(0, 0))  # y is jump height

	set_jumps(null, get_jumps()["destinations"])
	self.stunned_timer = JUMP_CD
	return


sync func animate_jump(jump_height):  ## IMPURE
	var sprite_pos = Vector2(0, 1) * jump_height
	var shadow_scale = ( 1 - 0.08 * sin(deg2rad(-1 * jump_height)) )
	var shadow_opacity = shadow_scale
	shadow_scale *= Vector2(1, 1)

	get_node("Sprite").set_pos(sprite_pos)
	get_node("Shadow").set_scale(shadow_scale)
	get_node("Shadow").set_opacity(shadow_opacity)
	set_z(jump_height)  # To render after everything below
	return


sync func set_motion_state(motion_state):  ## IMPURE

	var pos = get_pos()
	var dests = get_jumps()["destinations"]

	animate_jump(motion_state["jump_height"])
#	rpc("animate_jump", motion_state["jump_height"])

  # Check if moving
	if (motion_state["motion"].length() > 0 or
			dests.size() > 0):
		set_monitorable(false)  # Disable detection by other bodies and areas
		set_pos(pos + motion_state["motion"])
		if not is_state(MOVING):
			set_state(MOVING)
	elif is_state(MOVING):
		return set_state(STUNNED)


# Update the state of motion to reflect what is desired
master func new_motion_state(delta, init_pos, pos, dest):  ## PURE

	var motion
	var jump_height

	var dist_covered = pos - init_pos
	dist_covered.y *= 2
	dist_covered = dist_covered.length()

	var dist_total = dest - init_pos
	dist_total.y *= 2
	dist_total = dist_total.length()

	var dir = dest - pos
	dir.y *= 2
	dir = dir.normalized()


  # Where to put ourselves next
	var speed = min(dist_total*2, MAX_SPEED)
	motion = dir * speed * delta
	motion.y /= 2
	var projected_pos = pos + motion
	var coming_in_hot = motion.length() > 0 && speed >= pos.distance_to(dest)
	motion = ( projected_pos - pos ) if not coming_in_hot else ( dest - pos )

	var jump_completion = dist_covered / dist_total if dist_total > 0 else 1
	jump_height = sin(deg2rad(180*jump_completion)) * dist_total * -0.2

  # Bundle up and return the new state in a nice little dict
	return {
		"motion"		: 	motion,
		"jump_height" 	: 	jump_height,
	}


# This chec... ugh just read the name
#master func should_be_moving():
#	var limit = 2  # Jump queue limit
#	var dests = self.jump["destinations"]
#  # Check if any jumps are queued
#	if dests.size() < 1:
#		return false
#  # Limit amount of queued jumps allowed, add one because active dest is not cleared until landing
#	if dests.size() > limit:
#		self.jump["destinations"].resize(limit + 1)
#	return true if dests[0] != get_pos() else false


#####################################################################
#####################################################################
#####################################################################
