extends "res://scripts/Character.gd"

onready var insignia = get_node("Sprite/Insignia/InsigniaViewport/InsigniaSprite")

var mouse_pos = Vector2()

# Spawn an NPC to play with
sync func spawn_enemy(loc):
	return
	## Bot.gd needs serious cleanup before we can do this again
#	var enemy = preload("res://npc/Bot.tscn").instance()
#	enemy.set_pos(loc)
#	get_parent().add_child(enemy)


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
	mouse_pos = get_global_mouse_pos()

	# Update all states, timers and other statuses and end processing here if stunned
	var tmp = update_states(delta, get_state(), get_condition_timers()) # Yes, temporary inelegancy
	var state = tmp[0]
	state["position"] = get_pos()
	var ctimers = set_condition_timers(tmp[1])

	if state["condition"] == STUNNED:
		return

	if self.is_network_master():

		var path = get_path()
		var weapon = get_weapon_state()
		rset_unreliable("slave_pos", state["position"])

		if path["to"].size() > 0:
			if path["to"].size() > JUMP_Q_LIM:
				path["to"].resize(JUMP_Q_LIM + 1)
			if path["from"] == null:
				path["from"] = state["position"]
			set_path(path)
			rpc("set_motion_state", path, new_motion_state(delta, path, state), get_condition_timers())
#		else:
#			rpc("set_motion_state", { "motion" : Vector2(0,0), "jump_height" : 0 })

		if weapon["target_loc"] != null:
			attack(weapon["target_loc"])

		var focus = weapon["target_loc"] if get_state() == BUSY else ( path["to"][0] if get_state() == MOVING else mouse_pos )
		rset("slave_focus", focus)

		var current_rot = insignia.get_rot()
		insignia.rotate(new_rot(delta, state["position"], current_rot, focus))
	else:
		new_rot(delta, state["position"], insignia.get_rot(), slave_focus)


#####################################################################
#####################################################################
#####################################################################


func _unhandled_input(ev):
	if Input.is_action_just_pressed("move_to"):
		var path = get_path()
		if not (( path["to"].size() > 0 ) and ( mouse_pos == path["to"].back() )):
			path["from"] = path["from"] if path["to"].size() > 0 else get_pos()
			path["to"].append(mouse_pos)
			set_path(path)
			spawn_click_indicator(mouse_pos, "move_to")
	if Input.is_action_just_pressed("attack"):
		var weapon = get_weapon_state()
		weapon["target_loc"] = mouse_pos
		set_weapon_state(weapon)
		rset("slave_atk_loc", weapon["target_loc"])
	if ev.is_action_pressed("spawn_enemy"):
		spawn_enemy(rand_loc(mouse_pos, 200, 600))
	if ev.is_action_pressed("quit_game"):
		get_tree().quit()


######################
######################
######################


func _ready():
	get_node("Sprite").set_modulate(primary_color)
	insignia.set_modulate(secondary_color)
	if self.is_network_master():
		set_process_unhandled_input(true)
	set_fixed_process(true)
