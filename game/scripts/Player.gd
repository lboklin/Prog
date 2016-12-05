extends "res://scripts/Character.gd"


var mouse_pos


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

	if update_states() == STUNNED: return # Update all status conditions

	var atk_loc

	if self.is_network_master():
		mouse_pos = get_global_mouse_pos()
		rset_unreliable("slave_mouse_pos", mouse_pos)
		if Input.is_action_just_pressed("move_to"):
			jump["destinations"].append(mouse_pos)
			spawn_click_indicator(mouse_pos, "move_to")
		if Input.is_action_just_pressed("attack"):
			atk_loc = mouse_pos
			rset("slave_atk_loc", mouse_pos)

		if atk_loc != null:	attack(atk_loc)
		if should_be_moving():
			move_towards_destination()
		elif is_state(MOVING):
			stop_moving()

		var focus = atk_loc if is_state(BUSY) else jump["destinations"][0] if is_state(MOVING) else mouse_pos
		rset_unreliable("slave_focus", focus)
		look_towards(focus)
	else:
		look_towards(slave_focus)
		rpc("set_pos", slave_pos)


#####################################################################
#####################################################################
#####################################################################


func _unhandled_input(ev):
#	if ev.is_action_pressed("move_to"):
#		self.jump["destinations"].append(mouse_pos)
#		spawn_click_indicator(mouse_pos, "move_to")
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
