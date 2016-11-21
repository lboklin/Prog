extends "res://scripts/Character.gd"

func _fixed_process(delta):

	# TODO: Implement awareness of surroundings. Ability to detect and respond
	# to actions of players and bots around it. Awareness should be limited to
	# a 360 degree limited radius around it (and not be perfect observations
	# so that it appears more human in it's ability to predict and deduce
	# the intentions and actions of others).

	if dead:
		if lives > 0:
			respawn()
		elif lives == 0:
			if not is_queued_for_deletion():
				queue_free()
			return


	# Probabilities are a percentage of likelyhood within the timespan of a second

	# Attacking
	if success(35):
		var player = get_parent().get_node("Player")
		if player.moving: # Attack target's dest
			attack_coords = player.jump_target_coords[0]
		else: # Attack target's current pos
			attack_coords = player.get_pos()

	# Probability of jumping
	if not moving:
		if success(80):
			var jump_dest = randloc(get_viewport().get_visible_rect())
			jump_target_coords.append(jump_dest)
			self.indicate(jump_dest, "move_to")
	else:
		if success(70):
			var jump_dest = randloc(get_viewport().get_visible_rect())
			jump_target_coords.append(randloc(get_viewport().get_visible_rect()))
			self.indicate(jump_dest, "move_to")


	act(delta)


#####################################################################
#####################################################################
#####################################################################


func _ready():

	if primary_color ==  Color():
		primary_color = Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1))
	if secondary_color == Color():
		secondary_color = Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1))

	get_node("Sprite").set_modulate(primary_color)
	get_node("Sprite/Insignia").set_modulate(secondary_color)

	set_fixed_process(true)
