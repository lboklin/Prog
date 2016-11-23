extends "res://scripts/Character.gd"


export var accuracy_percentage = 70


func _fixed_process(delta):

	# TODO: Implement awareness of surroundings. Ability to detect and respond
	# to actions of players and bots around it. Awareness should be limited to
	# a 360 degree limited radius around it (and not be perfect observations
	# so that it appears more human in it's ability to predict and deduce
	# the intentions and actions of others).

	if dead:
		if lives > 0:
			respawn()
		elif lives == 0 and not self.is_queued_for_deletion():
			queue_free()
			return


	# Probabilities are a percentage of likelyhood within the timespan of a second

	# Attacking
	if success(35):

		if get_parent().has_node("Player"):
			var player = get_parent().get_node("Player")
			var player_sprite = player.get_node("Sprite")
			var player_size = player_sprite.get_texture().get_width() * player_sprite.get_scale().x
			var radius = player_size * 100 / accuracy_percentage
			var target_loc = Vector2()

			if player.moving: # Attack target's dest
				target_loc = player.jump_destination[0]
			else: # Attack target's current pos
				target_loc = player.get_pos()

			self.attack_location = rand_loc(target_loc, radius)

	# Probability of jumping
	if not moving:
		if success(80):
			var jump_dest = randloc(get_viewport().get_visible_rect())
			jump_destination.append(jump_dest)
			self.indicate(jump_dest, "move_to")
	else:
		if success(70):
			var jump_dest = randloc(get_viewport().get_visible_rect())
			jump_destination.append(randloc(get_viewport().get_visible_rect()))
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
