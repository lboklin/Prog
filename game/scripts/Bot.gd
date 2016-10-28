extends "res://scripts/Character.gd"


# Return a random location somewhere within the visible area
func randloc():

	randomize()

	var screenrect = get_viewport().get_visible_rect()
	var loc = Vector2()

	loc.x = round(rand_range(screenrect.pos.x, screenrect.end.x))
	loc.y = round(rand_range(screenrect.pos.y, screenrect.end.y))

	return loc


# Take a probability percentage and return true or false after diceroll
func success(chance):

	randomize()

	if chance > 100:
		return false

	var luck_result = randi() % convert((100 / get_fixed_process_delta_time()),2)

	if luck_result <= chance:
		return true


func _fixed_process(delta):
	
	update_states(delta)

	# TODO: Implement awareness of surroundings. Ability to "see" and respond
	# to actions of players and bots around it. Awareness should be limited to
	# a limited 360 degree radius around it (and not be perfect observations
	# so that it appears more human in it's ability to predict and deduce
	# the intentions and actions of others).

	# with a likelyhood of 50% each second
	if success(50):
		# attack 
		if command_queue.find("attack") == -1:
			# if target is standnig still - attack its current pos
			if get_node("../Player").jumping == false:
				attack.target_coords = get_node("../Player").get_pos()
			else:
				# attack where target is heading
				attack.target_coords = get_node("../Player").destination
			command_queue.append("attack")
	else:
		var prob = 0
		if not jumping:
			prob = 80
		else:
			prob = 70

		if success(prob):
			jump.target_coords.append(randloc())
			command_queue.append("jump")

	# Command queue limit
	if command_queue.size() > 3:
		command_queue.resize(3)
	
	# Don't bother with anything if stunned
	if stunned:
		return
	
	# Do stuff if commanded to
	if command_queue.size() > 0:
		execute_command()
	# If idle
	elif not busy:
		face_dir(mouse_pos)

	if is_colliding():
		print(get_collider())
		print(get_parent().get_child(1))
		queue_free()


#####################################################################
#####################################################################
#####################################################################


func _ready():
	var insignia = ImageTexture.new()
	insignia.load("res://npc/insignia.png")
	get_node("CharacterSprite/InsigniaViewport/Insignia").set_texture(insignia)
	
	set_fixed_process(true)
	pass
