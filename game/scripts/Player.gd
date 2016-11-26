extends "res://scripts/Character.gd"

func spawn_enemy(loc):

	var enemy = preload("res://npc/Bot.tscn").instance()

	enemy.set_pos(loc)
	get_parent().add_child(enemy)


#####################################################################
#####################################################################
#####################################################################


func _fixed_process(delta):

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
			spawn_enemy(rand_loc(mouse_pos, 200, 600))

	if ev.is_action_pressed("quit_game"):
		get_tree().quit()


######################
######################
######################


func _ready():

#	get_node("Camera2D").make_current()
	set_process_input(true)
	set_fixed_process(true)
