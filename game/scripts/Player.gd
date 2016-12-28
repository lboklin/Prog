extends "res://scripts/Character.gd"

var mouse_pos = Vector2()

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
	if update_states(delta) == STUNNED:
		return

	if self.is_network_master():

		var dests = get_jumps()["destinations"]
		var init_pos = get_jumps()["active_jump_origin"]
		var weapon = get_weapon_state()
		var pos = get_pos()
		rset_unreliable("slave_pos", pos)

		if dests.size() > 0:
			if init_pos == null:
				init_pos = pos
				set_jumps(init_pos, dests)
			rpc("set_motion_state", new_motion_state(delta, init_pos, pos, dests[0]))
			if dests.size() > JUMP_Q_LIM:
				dests.resize(JUMP_Q_LIM + 1)
		else:
			rpc("set_motion_state", { "motion" : Vector2(0,0), "jump_height" : 0 })

		if weapon["target_loc"] != null:
			attack(weapon["target_loc"])

		var focus = weapon["target_loc"] if is_state(BUSY) else ( dests[0] if is_state(MOVING) else mouse_pos )
		rset_unreliable("slave_focus", focus)
		look_towards(focus)
	else:
		look_towards(slave_focus)


#####################################################################
#####################################################################
#####################################################################


func _unhandled_input(ev):
	mouse_pos = get_global_mouse_pos()
	if Input.is_action_just_pressed("move_to"):
		var dests = get_jumps()["destinations"]
		var init_pos = get_jumps()["active_jump_origin"]
		if not (( dests.size() > 0 ) and ( mouse_pos == dests.back() )):
			init_pos = init_pos if dests.size() > 0 else get_pos()
			dests.append(mouse_pos)
			set_jumps(init_pos, dests)
			spawn_click_indicator(mouse_pos, "move_to")
	if Input.is_action_just_pressed("attack"):
		var weapon = get_weapon_state()
		weapon["target_loc"] = mouse_pos
		set_weapon_state(weapon["state"], mouse_pos, weapon["cooldown_timer"])
		rset("slave_atk_loc", weapon["target_loc"])
	if ev.is_action_pressed("spawn_enemy"):  # Spawn aggressive bot
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
