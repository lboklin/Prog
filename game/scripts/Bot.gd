extends "res://scripts/Character.gd"


export var accuracy_percentage = 70


func _fixed_process(delta):

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

			self.attack_location = rand_loc(target_loc, 0, radius)

#	# Probability of jumping
#	if not moving:
#		if success(80):
#			var jump_dest = randloc(get_viewport().get_visible_rect())
#			jump_destination.append(jump_dest)
#			self.indicate(jump_dest, "move_to")
#	else:
#		if success(70):
#			var jump_dest = randloc(get_viewport().get_visible_rect())
#			jump_destination.append(randloc(get_viewport().get_visible_rect()))
#			self.indicate(jump_dest, "move_to")

	# Maybe jump - More likely to queue jumps while already doing it
	var want_to_jump = false
	if not self.moving:
		want_to_jump = success(85)
	else:
		want_to_jump = success(70)

	if want_to_jump:
		var jump_dest
		if self.moving:
			jump_dest = rand_loc(self.jump_destination[0], 50, MAX_JUMP_RANGE)
		else:
			jump_dest = rand_loc(self.get_pos(), 50, MAX_JUMP_RANGE)
		self.jump_destination.append(jump_dest)



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
