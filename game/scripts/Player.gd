extends "res://scripts/Character.gd"


var motion = Vector2()
var mouse_pos = Vector2()


func spawn_enemy(loc):

	var enemy = preload("res://npc/Bot.tscn").instance()

	enemy.set_pos(loc)
	get_parent().add_child(enemy)


# Display an indicator for where you clicked
func spawn_click_indicator(pos, anim):

	var indicator = preload("res://gui/Indicator.tscn").instance()
	indicator.set_pos(pos)
	self.get_parent().add_child(indicator)

	indicator.get_node("AnimationPlayer").play(anim)


func attack():

	var not_the_time_to_use_that = moving || busy
	if not moving and not busy and weapon_cooldown <= 0:

		## PLACEHOLDER ##
		GameRound.points += 1
		#################

		# Spawn projectile
		var character_pos = self.get_pos()
		var projectile = preload("res://common/Projectile/Projectile.tscn").instance()
		var attack_dir = (self.attack_location - character_pos)
		attack_dir.y *= 2
		attack_dir = attack_dir.normalized()

		projectile.destination = self.attack_location
		projectile.set_global_pos( character_pos + attack_dir * Vector2(60,20) )
		get_parent().add_child(projectile)

		weapon_cooldown = weapon_cooldown
		busy_timer = 0.2


func stop_moving():

	motion = Vector2(0,0)
	set_pos(jump_dest[0])
	moving = false

	jump_dest.pop_front()
	jump_orig = null
	self.set_monitorable(true)
	self.set_z(1) # Back to ground level
	self.get_node("Sprite").set_pos(Vector2(0, 0))
	stunned_timer = JUMP_CD


func move_towards_destination():

	self.set_z(3) # To appear above the others
	self.set_monitorable(false)

	var dist_covered = self.get_pos() - self.jump_orig
	var dist_total = self.jump_dest[0] - self.jump_orig
	var dir = self.jump_dest[0] - self.get_pos()

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
	var dests = self.jump_dest

	if dests.size() < 1:
		should = false
	elif dests.size() > limit: # Keep number of jumps kept in queue under a limit
		dests.resize(limit)

	var dist = pos.distance_to(dests[0])
	if self.moving and self.motion.length() > dist: # If about to overshoot dest
		should = false
	else:
		should = true

	return should


#####################################################################
#####################################################################
#####################################################################


func _fixed_process(delta):

	if self.is_network_master():
		mouse_pos = get_global_mouse_pos()
		rset_unreliable("slave_mouse_position", mouse_position)
		if Input.is_action_just_pressed("move_to"):
			self.jump_destination.append(mouse_pos)
			spawn_click_indicator(mouse_pos, "move_to")
		if Input.is_action_just_pressed("attack"):
			attack_loc = mouse_pos

	var attack_loc

	if attacking:
		look_towards(attack_loc)
	elif moving:
		look_towards(jump_destination[0])
	elif not stunned and not busy:
		look_towards(mouse_pos)

	if self.is_network_master():

		update_states() # Update all status conditions

		if self.dead:
			if self.respawn_timer <= 0:
				respawn()
			else:
				self.respawn_timer -= delta
				return

		if stunned: # Do nothing if stunned
			return

		if self.attack_location != null:
			attack()

		if should_be_moving():
			move_towards_destination(delta)
			look_towards(delta, jump_dest[0])
		elif moving:
			stop_moving()


#####################################################################
#####################################################################
#####################################################################


func _unhandled_input(ev):

	if ev.is_action_pressed("move_to"):
		self.jump_destination.append(mouse_pos)
		spawn_click_indicator(mouse_pos, "move_to")
	if ev.is_action_pressed("spawn_enemy"): # Spawn aggressive bot
		spawn_enemy(rand_loc(mouse_pos, 200, 600))
	if ev.is_action_pressed("quit_game"):
		get_tree().quit()


######################
######################
######################


func _ready():

	if self.is_network_master():
		set_process_unhandled_input(true)
	set_fixed_process(true)
