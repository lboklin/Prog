extends "res://scripts/Character.gd"


func spawn_enemy(loc):

	var enemy = preload("res://npc/bot.tscn").instance()

	enemy.set_pos(loc)
	get_parent().add_child(enemy)


#####################################################################
#####################################################################
#####################################################################


func _fixed_process(delta):
				
	mouse_pos = get_global_mouse_pos()
	
	# Request to attack target location
	if Input.is_action_pressed("attack"):
		attack.target_coords = mouse_pos
	

#####################################################################
#####################################################################
#####################################################################


func _input(ev):
	
#	# Pointer is moved
#	if ev.type == (InputEvent.MOUSE_MOTION or InputEvent.MOUSE_BUTTON):
#		mouse_pos = get_global_mouse_pos()
	
	# Request to jump
	if ev.is_action_pressed("move_to"):
		jump.target_coords.append(mouse_pos)

	if ev.is_action_pressed("spawn_enemy"):
		spawn_enemy(mouse_pos)
		
	# To reset position in case of buggery
	if ev.is_action_pressed("reset"):
		rooted = true
		set_pos(Vector2(0,0))
			

######################
######################
######################


func _ready():
	var insignia = ImageTexture.new()
	insignia.load("res://player/insignia.png")
	get_node("CharacterSprite/InsigniaViewport/Insignia").set_texture(insignia)
	
	set_process_input(true)
	set_fixed_process(true)
	pass
