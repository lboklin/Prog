extends "res://scripts/Character.gd"


# Return a random location somewhere within the visible area
func randloc():

	var screenrect = get_viewport().get_visible_rect()
	var loc = Vector2()

	loc.x = round(rand_range(screenrect.pos.x, screenrect.end.x))
	loc.y = round(rand_range(screenrect.pos.y, screenrect.end.y))
	randomize() # New seed

	return loc


# Take a probability percentage and return true or false after diceroll
func success(chance):

	if chance > 100:
		return true

	var luck_result = randf() % ( 100 / get_fixed_process_delta_time() )
	randomize() # New seed

	if luck_result <= chance:
		return true


func _fixed_process(delta):

	# TODO: Implement awareness of surroundings. Ability to "see" and respond
	# to actions of players and bots around it. Awareness should be limited to
	# a limited 360 degree radius around it (and not be perfect observations
	# so that it appears more human in it's ability to predict and deduce
	# the intentions and actions of others).

	if is_colliding():
		if get_collider().is_in_group("Lethal"):
			die()

	var p # Probability variable
	p = 50 # 50% probability of attacking inside a second
	if success(p):
		if get_node("../Player").moving: # Attack target's dest
			attack.target_coords = get_node("../Player").destination
		else: # Attack target's current pos
			attack.target_coords = get_node("../Player").get_pos()
	else:
		# Probability of jumping
		if not moving:
			p = 80
		else:
			p = 70

		if success(p):
			jump.target_coords.append(randloc())


#####################################################################
#####################################################################
#####################################################################


func _ready():
	var insignia = ImageTexture.new()
	insignia.load("res://npc/insignia.png")
	get_node("CharacterSprite/InsigniaViewport/Insignia").set_texture(insignia)
	
	set_fixed_process(true)
	pass
