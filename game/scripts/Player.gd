extends "res://scripts/Character.gd"

func spawn_enemy(loc):

	var enemy = preload("res://npc/Bot.tscn").instance()

	enemy.set_pos(loc)
	get_parent().add_child(enemy)


#####################################################################
#####################################################################
#####################################################################


func _fixed_process(delta):

	if dead:
		respawn() # I'm undead >:)
#		if lives > 0:
#			respawn()
#		elif lives == 0 and not self.is_queued_for_deletion():
#			queue_free()
#			return

	mouse_pos = get_global_mouse_pos()

	# If a request to attack
	if Input.is_action_pressed("attack"):
		self.attack_location = mouse_pos

	act(delta)


#####################################################################
#####################################################################
#####################################################################


func _input(ev):

	if is_visible():

		# Request to jump
		if ev.is_action_pressed("move_to"):
			self.jump_destination.append(mouse_pos)
			indicate(mouse_pos, "move_to")

		# Request to spawn a clone with a grudge
		if ev.is_action_pressed("spawn_enemy"):
			spawn_enemy(randloc(get_viewport().get_visible_rect()))

		# To reset position in case of buggery
		if ev.is_action_pressed("reset"):
			rooted_timer = 1
			self.set_global_pos(Vector2(0,0))


######################
######################
######################


func _ready():

	set_process_input(true)
	set_fixed_process(true)
