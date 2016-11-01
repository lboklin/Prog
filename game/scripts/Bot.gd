extends Node2D

const LIVES = 3

var character
var lives = LIVES


# Take a probability percentage and return true or false after diceroll
func success(delta, chance):

	var diceroll = rand_range(0, 100)
	randomize()

	if diceroll <= (chance * delta):
		return true


func _fixed_process(delta):

	# TODO: Implement awareness of surroundings. Ability to detect and respond
	# to actions of players and bots around it. Awareness should be limited to
	# a 360 degree limited radius around it (and not be perfect observations
	# so that it appears more human in it's ability to predict and deduce
	# the intentions and actions of others).

	if not self.has_node("CharacterModel") and lives > 0:
		character = preload("res://common/Character/CharacterModel.tscn").instance()
		self.set_global_pos(character.randloc(get_viewport().get_visible_rect()))
		self.add_child(character)
		character = get_node("CharacterModel")

		var insignia = ImageTexture.new()
		insignia.load("res://npc/insignia.png")
		get_node("CharacterModel/InsigniaViewport/Insignia").set_texture(insignia)
	elif lives == 0:
		return

	# Probabilities are a percentage of likelyhood within the timespan of a second

	# Attacking
	if success(delta, 35):
		if get_parent().get_node("Player/CharacterModel").moving: # Attack target's dest
			character.attack_coords = get_parent().get_node("Player/CharacterModel").jump_target_coords[0]
		else: # Attack target's current pos
			character.attack_coords = get_parent().get_node("Player").get_pos()

	# Probability of jumping
	if not character.moving:
		if success(delta, 80):
			character.jump_target_coords.append(character.randloc(get_viewport().get_visible_rect()))
	else:
		if success(delta, 70):
			character.jump_target_coords.append(character.randloc(get_viewport().get_visible_rect()))

	character.act(delta)


#####################################################################
#####################################################################
#####################################################################


func _ready():

	set_fixed_process(true)
