extends Area2D

# Your Prog's very own beautiful color scheme
export(Color) var primary_color
export(Color) var secondary_color

const WEP_CD = 1.0  # Weapon cooldown
const JUMP_CD = 0.1  # Jump cooldown after landing
const MAX_SPEED = 1500  # Max horizontal (ground) speed
const MAX_JUMP_RANGE = 1000  # How far you can jump from any given starting pos
const JUMP_Q_LIM = 2  # Jump queue limit

# State enums
enum Condition {OK, DEAD, RESPAWNING, STUNNED, BUSY}
enum Action {IDLE, MOVING, ATTACKING}
enum Power {ON, OFF}

slave var slave_pos = Vector2()
slave var slave_atk_loc = Vector2()
#slave var slave_motion = Vector2()
slave var slave_focus = Vector2()

# Counters
var points = 0
#var time_of_death = null  # If applicable


## Dicts

sync var p_state = {
	"condition"			: Condition.OK,
	"action"			: Action.IDLE,
	"action_timer"		: 0.0,
	"position"			: Vector2(),
	"motion"			: Vector2(),  # Horizontal
	"height"			: 0  # Vertical
} setget set_state, get_state

# Add timers when applied and remove when they expire
var p_condition_timers = {
#	"stunned"			: 0.0,
#	"dead"				: 0.0,
#	"respawning"		: 0.0,
#	"busy"				: 0.0,
} setget set_condition_timers, get_condition_timers

var p_path = {
	"from"				: null,
	"to"				: [],  # Take note that this is a jump queue array
} setget set_path, get_path

var p_weapon_state = {
	"power" 			: Power.ON,
	"target_loc"		: null,
	"timer"	: 0.0
} setget set_weapon_state, get_weapon_state

var p_shield_state = {
	"power"				: Power.ON,
	"timer"				: 2.0  # Spawn in with 2 sec protective shield
} setget set_shield_state, get_shield_state


###########################
## SetGetters / queries  ##
###########################

#-------------
# General state

sync func set_state(new_state):
	# Explain myself here please.
	# 	re: Okay so it's probably that if the state disallows actions
	# 		we should just set current action to Action.IDLE.
	if ( new_state["condition"] != Condition.OK ) and ( new_state["condition"] != Condition.BUSY ):
		new_state["action"] = Action.IDLE

	p_state = new_state
	return p_state

func get_state():
	return p_state

#-------------
# General state

func set_condition_timers(cts):
	p_condition_timers = cts
	return p_condition_timers

func get_condition_timers():
	return p_condition_timers

#-------------
#-------------
# Jump state

sync func set_path(new_path):
	p_path = new_path
	return p_path

func get_path():
	return p_path

#-------------
#-------------
# Weapon state

func set_weapon_state(new_state):
	p_weapon_state = new_state
	return p_weapon_state

func get_weapon_state():
	return p_weapon_state

#-------------
#-------------
# Shield state

func set_shield_state(new_state):
	p_shield_state = new_state
	return p_shield_state

func get_shield_state():
	return p_shield_state

#-------------

##########################


func update_states(delta, state, ctimers):  ## PURE (but needs a more complete solution)

#	var state = get_state()
#	var ct = get_condition_timers()

	## TODO: generalize the if conditions below ##
#	for timer in ctimers:
#		timer -=delta
#		if timer <= 0:
#			ctimers.erase(timer)
#		elif state["condition"] != Condition
	################################################

	if ctimers.empty():
		state["condition"] = OK
	else:
		# Check if stunned
		if ctimers.has("stunned"):
			ctimers["stunned"] -= delta
			if ctimers["stunned"] <= 0:
				ctimers.erase("stunned")
			elif state["condition"] != Condition.STUNNED:
				state["condition"] = Condition.STUNNED
				return [state, ctimers]
		# We will adjust state next time around instead of rechecking
		elif state["condition"] == Condition.STUNNED:
			state["action"] = Action.IDLE
			return [state, ctimers]

		# Check if performing an action
		if ctimers.has("busy"):
			ctimers["busy"] -= delta
			if ctimers["busy"] <= 0:
				ctimers.erase("busy")
			elif state["condition"] != Condition.BUSY:
				state["condition"] = Condition.BUSY
				return [state, ctimers]
		# We will adjust state next time around instead of rechecking
		elif state["condition"] == Condition.BUSY:
			state["action"] = Action.IDLE
			return [state, ctimers]

		# Check if supposed to respawn (is dead)
		if ctimers.has("respawn"):
			ctimers["respawn"] -= delta
			if ctimers["respawn"] <= 0:
				ctimers.erase("respawn")
				ctimers.erase("dead")
				state["condition"] = Condition.RESPAWNING
			elif state["condition"] != DEAD:
				state["condition"] = Condition.DEAD
				return [state, ctimers]
		# We will adjust state next time around instead of rechecking
		elif state["condition"] == DEAD:
			state["condition"] = Condition.RESPAWNING
			return [state, ctimers]

	return[state, ctimers]

	## TODO: Do something about this mess. It messes with my purity.

	# Check the state of the shield as necessary
#	var shield = get_shield_state()
#	shield["power"] = Power.ON if shield["timer"] > 0 else Power.OFF
#	if shield["power"] == Power.ON:
#		shield["timer"] -= delta
#	set_shield_state(shield)
#
#	# Check the state of the weapon and update if necessary
#	var weapon = get_weapon_state()
#	weapon["power"] = Power.OFF if weapon["timer"] > 0 else Power.ON
#	if weapon["power"] == Power.OFF:
#		weapon["timer"] -= delta
#	set_weapon_state(weapon)


# Produce a random point inside a circle of a given radius
func rand_loc(location, radius_min, radius_max):  ## PURE

	var new_radius = rand_range(radius_min, radius_max)
	var angle = deg2rad(rand_range(0, 360))
	var point_on_circ = Vector2(new_radius, 0).rotated(angle)
	return location + point_on_circ


##################################################

# For rotating the insignia sprite towards the given point (point is in global coords)
master func new_rot(delta, current_pos, current_rot, point):  ## PURE
	var dir = point - current_pos
	dir.y *= 2

	# Use degrees 'cause it be more intuitive
	var new_rot_deg = rad2deg(dir.angle())
	var current_rot_deg = rad2deg(current_rot)

	# Always count rot in the positive
	while new_rot_deg < 0:
		new_rot_deg = new_rot_deg + 360
	while current_rot_deg < 0:
		current_rot_deg = current_rot_deg + 360

	var d_angle_deg = new_rot_deg - current_rot_deg

	var s = sign(d_angle_deg)
	var d_angle_deg = abs(d_angle_deg)

	# Don't go the long way around, it's stupid
	if d_angle_deg > 180:
		s *= -1
		d_angle_deg = 360 - d_angle_deg

	# Now go back to radians to make Godot happy
	var d_angle = deg2rad(d_angle_deg)

	var rot_speed = 3
	var min_rot_speed = 0.04

	var smooth_rot_speed = delta * rot_speed * d_angle * d_angle
	var d_rot = s * min(d_angle, max(smooth_rot_speed, min_rot_speed))
	var new_rot = current_rot + d_rot

	# Don't keep inflating the rot value
	if new_rot > 2*PI:
		new_rot -= 2*PI
	elif new_rot < 0:
		new_rot += 2*PI

	return new_rot


# Get hit (and die - at least until better implementation is implemented)
func hit():  ## IMPURE (Could be purified?)
	return
#	var state = get_state()
#	var condition_timers = get_condition_timers()
#
#	if state["condition"] != DEAD:
#		state["condition"] = DEAD
#
#		## Reset all active timers and states  ##
#		var wep_st = get_weapon_state()
#		wep_state["timer"] = 0
#		wep_state["target_loc"] = null
#		condition_timers.clear()
#		## TODO: Fix line below
#		self.jump["active_jump_origin"] = null
#
#		set_monitorable(false)
#		set_hidden(true)
#		update_states()
#		#########################################
#
#		# Set respawn timer based on elapsed game round time
#		self.time_of_death = GameRound.round_timer
#		self.timer = self.time_of_death / 10
#		print(self.timer)
#
#		var death_anim = preload("res://common/DeathEffect.tscn").instance()
#		death_anim.set_pos(get_pos())
#		get_parent().add_child(death_anim)
#
#		print(get_name() + " was killed and will be back in ", self.timer)


# Well, this one makes you respawn
func respawn():  ## IMPURE BD

	set_monitorable(true)  # Enable detecondition_tion by other bodies and areas
	set_pos(rand_loc(Vector2(0,0), 0, 1000))

	set_shield_state(Power.ON, 2.0)
	rpc("set_path", { "from" : null, "to" : [] })


# Attack given location (not relative to prog)
master func attack(loc):  ## IMPURE BD
	return

#	var not_the_time_to_use_that = moving || busy
#	var state = get_state()
#	if state["action"] == Action.IDLE and get_weapon_state()["power"] == ON:
#		state["action"] = Condition.BUSY
#		set_state(state)
#
#		## PLACEHOLDER  ##########
#		GameRound.points += 1  ##
#		########################
#
#		# Spawn projectile
#		var character_pos = get_pos()
#		var projectile = preload("res://common/Projectile/Projectile.tscn").instance()
#		var attack_dir = (gget_weapon_state()["target_loc"] - character_pos)
#		attack_dir.y *= 2
#		attack_dir = attack_dir.normalized()
#
#		projectile.destination = gget_weapon_state()["target_loc"]
#		projectile.set_global_pos( character_pos + attack_dir * Vector2(60,20) )
#		get_parent().add_child(projectile)
#
#		get_weapon_state()["timer"] = weapon_cooldown
#		self.state["timer"] = 0.2


sync func animate_jump(state, path):  ## IMPURE BD
	var jump_height = state["height"]
	# If we're not in the air, just set everything
	# accordingly and skip the calculations.
	if jump_height <= 0:
		set_monitorable(true)  # Can be detected by other bodies and areas
		set_z(1)  # Back onto ground
		get_node("Sprite").set_pos(Vector2(0, 0))  # y is jump height

		if not state["motion"].length() > 0:
			path["from"] = null
			path["to"].pop_front()
			set_path(path)

			var cts = get_condition_timers()
			cts["stunned"] = JUMP_CD
			set_condition_timers(cts)
	else:
		var sprite_pos = Vector2(0, -1) * jump_height
		var shadow_scale = ( 0.45 - 0.08 * -cos(deg2rad(jump_height)) )
		# Use shadow scale as a basis for the opacity too
		var shadow_opacity = shadow_scale
		# Then convert the scale into the proper type
		shadow_scale *= Vector2(1, 1)

		get_node("Sprite").set_pos(sprite_pos)
		get_node("Shadow").set_scale(shadow_scale)
		get_node("Shadow").set_opacity(shadow_opacity)
		set_z(jump_height + 1)  # To render after everything below
	return


sync func set_motion_state(path, state, condition_timers):  ## IMPURE BD

	# Check if there are any jumps queued and
	# if so pop any that hold our current pos.
	# Use while loop to catch any duplicates.
	while path["to"].size() > 0 and state["position"] == path["to"][0]:
		path["to"].pop_front()
		path["from"] = state["position"] if path["to"].size() > 0 else null
		set_path(path)

	animate_jump(state, path)

	# Check if (supposed to be) moving and apply motion
	if (state["motion"].length() > 0 or path["to"].size() > 0):
		# Disable detection by other bodies and areas.
		# This is to avoid hitting or being hit by anything while jumping.
		set_monitorable(false)

		set_pos(state["position"] + state["motion"])
	# Stun on landing
	elif state["action"] == Action.MOVING:
		condition_timers["stunned"] += JUMP_CD


# Update the state of motion to reflect what is desired
master func new_motion_state(delta, path, state):  ## PURE

	var dist_covered = state["position"] - path["from"]
	dist_covered.y *= 2
	dist_covered = dist_covered.length()

	var dist_total = path["to"][0] - path["from"]
	dist_total.y *= 2
	dist_total = dist_total.length()

	var dir = path["to"][0] - state["position"]
	dir.y *= 2
	dir = dir.normalized()


	# Where to put ourselves next
	var speed = min(dist_total*2, MAX_SPEED)
	state["motion"] = dir * speed * delta
	state["motion"].y *= 0.5
	# If about to overshoot destination
	var coming_in_hot = ( state["motion"].length() > 0 ) and ( state["motion"].length() >= state["position"].distance_to(path["to"][0]) )
	if coming_in_hot:
		state["motion"] = path["to"][0] - state["position"]

	var jump_completion = dist_covered / dist_total if dist_total > 0 else 1
	state["height"] = sin(deg2rad(180*jump_completion)) * dist_total * 0.2

	return state