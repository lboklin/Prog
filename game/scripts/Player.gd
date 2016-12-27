extends "res://scripts/Character.gd"


# Spawn an NPC to play with
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


#####################################################################
#####################################################################
#####################################################################


func _fixed_process(delta):

	# Update all states, timers and other statuses and end processing here if stunned
	if update_states(delta) == STUNNED: return

	if self.is_network_master():

		var jump = get_jump_state()
		var weapon = get_weapon_state()
		var pos = get_pos()
		rset_unreliable("slave_pos", pos)

		if jump["destinations"] != [] && pos == jump["destinations"][0]:
			rpc("stop_moving")
			jump = get_jump_state()

		if jump["initial_pos"] == null:
			jump["initial_pos"] = pos
		if jump["destinations"].size() > 0:
			if jump["destinations"].size() > JUMP_Q_LIM:	jump["destinations"].resize(JUMP_Q_LIM + 1)

			var new_motion_state = get_new_motion_state(delta, jump["initial_pos"], pos, jump["destinations"][0])

			apply_new_motion_state(new_motion_state)
			rset("slave_motion_state", new_motion_state)


		if weapon["target_loc"] != null:
			attack(weapon["target_loc"])

		var focus = weapon["target_loc"] if is_state(BUSY) else ( jump["destinations"][0] if is_state(MOVING) else get_global_mouse_pos() )
		rset_unreliable("slave_focus", focus)
		look_towards(focus)
	else:
		look_towards(slave_focus)


#####################################################################
#####################################################################
#####################################################################


func _unhandled_input(ev):
	var mouse_pos = get_global_mouse_pos()
	if Input.is_action_just_pressed("move_to"):
		var jump = get_jump_state()
		jump["destinations"].append(mouse_pos)
		set_jump_state(jump)
		spawn_click_indicator(mouse_pos, "move_to")
	if Input.is_action_just_pressed("attack"):
		var weapon = get_weapon_state()
		weapon["target_loc"] = mouse_pos
		set_weapon_state(weapon)
		rset("slave_atk_loc", weapon["target_loc"])
	if ev.is_action_pressed("spawn_enemy"): # Spawn aggressive bot
		spawn_enemy(rand_loc(mouse_pos, 200, 600))
	if ev.is_action_pressed("quit_game"):
		get_tree().quit()


######################
######################
######################


func _ready():
	if self.is_network_master(): set_process_unhandled_input(true)
	set_fixed_process(true)
