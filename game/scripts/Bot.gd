extends Node2D

var character


# Take a probability percentage and return true or false after diceroll
func success(chance):

	if chance > 100:
		return true

	chance = chance * get_fixed_process_delta_time()
	var luck_result = randi() % 100
	randomize() # New seed

	if luck_result <= chance:
		return true


func _fixed_process(delta):

	# TODO: Implement awareness of surroundings. Ability to detect and respond
	# to actions of players and bots around it. Awareness should be limited to
	# a 360 degree limited radius around it (and not be perfect observations
	# so that it appears more human in it's ability to predict and deduce
	# the intentions and actions of others).

	if not self.has_node("CharacterModel"):
		character = preload("res://common/Character/CharacterModel.tscn").instance()
		self.add_child(character)
		character = get_node("CharacterModel")
	
		var insignia = ImageTexture.new()
		insignia.load("res://npc/insignia.png")
		get_node("CharacterModel/InsigniaViewport/Insignia").set_texture(insignia)

	# Probability of attacking inside a second
	if success(50):
		if get_parent().get_node("Player/CharacterModel").moving: # Attack target's dest
			character.attack_coords = get_parent().get_node("Player/CharacterModel").jump_target_coords[0]
		else: # Attack target's current pos
			character.attack_coords = get_parent().get_node("Player").get_pos()
	
	# Probability of jumping
	if not character.moving:
		if success(80):
			character.jump_target_coords.append(character.randloc(get_viewport().get_visible_rect()))
	else:
		if success(70):
			character.jump_target_coords.append(character.randloc(get_viewport().get_visible_rect()))
		
	character.act(delta)


#####################################################################
#####################################################################
#####################################################################


func _ready():
	
	set_fixed_process(true)
