extends Node2D

var character
var mouse_pos = Vector2()

func spawn_enemy(loc):

	var enemy = preload("res://npc/Bot.tscn").instance()

	enemy.set_pos(loc)
	get_parent().add_child(enemy)


#####################################################################
#####################################################################
#####################################################################


func _fixed_process(delta):

	mouse_pos = get_global_mouse_pos()

	if not self.has_node("CharacterModel"):
		character = preload("res://common/Character/CharacterModel.tscn").instance()
		self.set_global_pos(character.randloc(get_viewport().get_visible_rect()))
		self.add_child(character)
		character = get_node("CharacterModel")

		var insignia = ImageTexture.new()
		insignia.load("res://player/insignia.png")
		character.get_node("InsigniaViewport/Insignia").set_texture(insignia)

	# If a request to attack
	if Input.is_action_pressed("attack"):
		character.attack_coords = mouse_pos

	character.act(delta)


#####################################################################
#####################################################################
#####################################################################


func _input(ev):

	if self.has_node("CharacterModel"):

		# Request to jump
		if ev.is_action_pressed("move_to"):
			character.jump_target_coords.append(mouse_pos)

		# Request to spawn a clone with a grudge
		if ev.is_action_pressed("spawn_enemy"):
			spawn_enemy(mouse_pos)

		# To reset position in case of buggery
		if ev.is_action_pressed("reset"):
			character.rooted_timer = 1
			self.set_global_pos(Vector2(0,0))


######################
######################
######################


func _ready():

	set_process_input(true)
	set_fixed_process(true)
