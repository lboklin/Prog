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
slave var slave_motion = Vector2()
slave var slave_focus = Vector2()

# Counters
var points = 0
#var time_of_death = null  # If applicable


## Dicts

var p_state = {
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
} setget apply_condition_timer, get_condition_timers

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
	return

func get_state():
	return p_state

#-------------
# General state

func apply_condition_timer(condition, value):
	p_condition_timers[condition] = value

func get_condition_timers():
	return p_condition_timers

#-------------
#-------------
# Jump state

sync func set_path(new_path):
	p_path = new_path
	return

func get_path():
	return p_path

#-------------
#-------------
# Weapon state

func set_weapon_state(new_state):
	p_weapon_state = new_state
	return

func get_weapon_state():
	return p_weapon_state

#-------------
#-------------
# Shield state

func set_shield_state(new_state):
	p_shield_state = new_state
	return

func get_shield_state():
	return p_shield_state

#-------------

##########################


# This method modifies the member vars
func update_states(delta, state, condition_t):  ## PURE

#	var state = get_state()
#	var ct = get_condition_timers()

	## TODO: generalize the if conditions below ##
#	for timer in condition_t:
#		timer -=delta
#		if timer <= 0:
#			condition_t.erase(timer)
#		elif state["condition"] != Condition
	################################################

	if not condition_t.empty():
		# Check if stunned
		if condition_t.has("stunned"):
			condition_t["stunned"] -= delta
			if condition_t["stunned"] <= 0:
				condition_t.erase("stunned")
			elif state["condition"] != Condition.STUNNED:
				state["condition"] = Condition.STUNNED
				return [state, condition_t]
		# We will adjust state next time around instead of rechecking
		elif state["condition"] == Condition.STUNNED:
			state["action"] = Action.IDLE
			return [state, condition_t]

		# Check if performing an action
		if condition_t.has("busy"):
			condition_t["busy"] -= delta
			if condition_t["busy"] <= 0:
				condition_t.erase("busy")
			elif state["condition"] != Condition.BUSY:
				state["condition"] = Condition.BUSY
				return [state, condition_t]
		# We will adjust state next time around instead of rechecking
		elif state["condition"] == Condition.BUSY:
			state["action"] = Action.IDLE
			return [state, condition_t]

		# Check if supposed to respawn (is dead)
		if condition_t.has("respawn"):
			condition_t["respawn"] -= delta
			if condition_t["respawn"] <= 0:
				condition_t.erase("respawn")
			elif state["condition"] != DEAD:
				state["condition"] = Condition.DEAD
				return [state, condition_t]
		# We will adjust state next time around instead of rechecking
		elif state["condition"] == DEAD:
			state["condition"] = Condition.RESPAWNING
			return [state, condition_t]
	if state["condition"] == Condition.DEAD:
		condition_t["dead"] += delta
	elif condition_t.has("dead"):
		condition_t.erase("dead")

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
func respawn():  ## IMPURE

	set_monitorable(true)  # Enable detecondition_tion by other bodies and areas
	set_pos(rand_loc(Vector2(0,0), 0, 1000))

	set_shield_state(Power.ON, 2.0)
	rpc("set_path", { "from" : null, "to" : [] })
#	set_path({ "from" : null, "to" : [] })


# Attack given location (not relative to prog)
master func attack(loc):  ## IMPURE

#	var not_the_time_to_use_that = moving || busy
#	var state = get_state()
#	if state["action"] == Action.IDLE and get_weapon_state()["power"] == ON:
#		state["action"] = Condition.BUSY
#		set_state(state)
	return
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
#		gget_weapon_state()["timer"] = weapon_cooldown
#		self.state["timer"] = 0.2


# This one stops your movement..
#sync func reset_motion_state():  ## IMPURE
#	set_monitorable(true)  # Can be detected by other bodies and areas
#	set_z(1)  # Back onto ground
#	get_node("Sprite").set_pos(Vector2(0, 0))  # y is jump height
#
#	var p = get_path()
#	p["from"] = null
#	set_path(p)
#
#	apply_condition_timer("stunned", JUMP_CD)
#
#	return


sync func animate_jump(jump_height):  ## IMPURE
	# If we're not in the air, just set everything
	# accordingly and skip the calculations.
	if jump_height <= 0:
		set_monitorable(true)  # Can be detected by other bodies and areas
		set_z(1)  # Back onto ground
		get_node("Sprite").set_pos(Vector2(0, 0))  # y is jump height

		var path = get_path()
		path["from"] = null
		path["to"].pop_front()
		set_path(path)

		apply_condition_timer("stunned", JUMP_CD)
	else:
		var sprite_pos = Vector2(0, -1) * jump_height
		var shadow_scale = ( 1 - 0.08 * sin(deg2rad(-1 * jump_height)) )
		# Use shadow scale as a basis for the opacity too
		var shadow_opacity = shadow_scale
		# Then convert the scale into the proper type
		shadow_scale *= Vector2(1, 1)

		get_node("Sprite").set_pos(sprite_pos)
		get_node("Shadow").set_scale(shadow_scale)
		get_node("Shadow").set_opacity(shadow_opacity)
		set_z(jump_height + 1)  # To render after everything below
	return


sync func set_motion_state(path, state, condition_timers):  ## IMPURE

	# Check if there are any jumps queued and
	# if so pop any that hold our current pos.
	# Use while loop to catch any duplicates.
	while path["to"].size() > 0 and state["position"] == path["to"][0]:
		path["to"].pop_front()
		path["from"] = state["position"] if path["to"].size() > 0 else null
		set_path(path)

	animate_jump(state["height"])

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
	var coming_in_hot = state["motion"].length() > 0 && state["motion"].length() >= state["position"].distance_to(path["to"][0])
	if coming_in_hot:
		state["motion"] = path["to"][0] - state["position"]

	var jump_completion = dist_covered / dist_total if dist_total > 0 else 1
	state["height"] = sin(deg2rad(180*jump_completion)) * dist_total * 0.2

	return state


#####################################################################
#####################################################################
#####################################################################
