extends Area2D

export var primary_color = Color()
export var secondary_color = Color()


const WEP_CD = 1.0 			# Weapon cooldown
const JUMP_CD = 0.2 		# Jump cooldown
const MAX_SPEED = 1500		# Max movement speed in px/s
const ROT_SPEED = 2			# Speed at which the prog turns around
const MAX_JUMP_RANGE = 1000

########################

var time_of_death = 0.0
var points = 0

## Timers
var weapon_cooldown = 0.0
var stunned_timer = 0.0
var busy_timer = 0.0
var shielded_timer = 2.0	# Spawn in with 2 sec protective shield
var respawn_timer = 0.0

## Statuses
var moving = false
var shielded = true
var stunned = false
var busy = false
var dead = false
var weapon_ready = true

## Coordinates
var jump_dest = [] 			# Where we want to go
var jump_orig = null		# Where we come from
var attack_location = null	# Where we want death


#########################
#########################
#########################


func update_states():

	var delta = get_fixed_process_delta_time()

	if self.motion.length() > 0:
		self.moving = true
	else:
		self.moving = false

	## Various status effects and their timers ##

	if self.shielded or self.shielded_timer > 0:
		self.shielded_timer -= delta
		if self.shielded_timer <= 0:
			self.shielded = false
		else:
			self.shielded = true

	if self.stunned or self.stunned_timer > 0:
		self.stunned_timer -= delta
		if self.stunned_timer <= 0:
			self.stunned = false
		else:
			self.stunned = true

	if self.stunned or self.stunned_timer > 0:
		self.stunned_timer -= delta
		if self.stunned_timer <= 0:
			self.stunned = false
		else:
			self.stunned = true

	# attack cooldowns
	if self.weapon_cooldown > 0:
		self.weapon_cooldown -= delta
		if self.weapon_cooldown <= 0:
			self.weapon_ready = true
		else:
			self.weapon_ready = false

	if self.busy or self.busy_timer > 0:
		self.busy_timer -= delta
		if self.busy_timer <= 0:
			self.busy = false
		else:
			self.busy = true


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


func look_towards(point):

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

	insignia.rotate(min(angle, (delta*ROT_SPEED*angle*angle)+0.1)*s)


func hit():

	if not self.dead:

		self.dead = true
		self.set_monitorable(false)
		self.set_hidden(true)

		## Reset all active timers and states ##
		self.weapon_cooldown = 0
		self.stunned_timer = 0
		self.busy_timer = 0

		self.attack_location = null
		self.jump_orig = null

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
	self.jump_dest = [self.get_pos()]

	self.set_hidden(false)


#####################################################################
#####################################################################
#####################################################################
