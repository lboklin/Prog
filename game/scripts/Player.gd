extends "res://scripts/Character.gd"


func spawn_enemy(loc):

	var enemy = preload("res://npc/bot.tscn").instance()

	enemy.set_pos(loc)
	get_parent().add_child(enemy)


#####################################################################
#####################################################################
#####################################################################


func _fixed_process(delta):
	
	update_states(delta)
	
#	if is_colliding():
#		die()
#		return
	
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
	
	# Refresh custom draw calls
#	update()


#####################################################################
#####################################################################
#####################################################################


func _input(ev):
	
	# Pointer is moved
	if ev.type == InputEvent.MOUSE_MOTION:
		mouse_pos = get_viewport_transform().affine_inverse().xform(ev.pos)

	if Input.is_action_pressed("spawn_enemy"):
		spawn_enemy(mouse_pos)
		
	# Mouse is clicked
	if ev.type == InputEvent.MOUSE_BUTTON and ev.is_pressed():
		randomize()
		rand_color = randi() % 55
		
		# Move to
		if Input.is_action_pressed("move_to"):
			jump.target_coords.append(mouse_pos)
			command_queue.append("jump")
				
		# RMB = Attack target location
		if ev.button_index == 2:
			if command_queue.find("attack") == -1:
				attack.target_coords = mouse_pos
				command_queue.append("attack")
		
	# Key is pressed
	if ev.type == InputEvent.KEY and ev.is_pressed():
		
		# To reset position in case of buggery
		if Input.is_action_pressed("reset"):
			rooted = true
			set_pos(Vector2(0,0))
		
		var delta = get_fixed_process_delta_time()
			
	get_tree().set_input_as_handled()
			

######################
######################
######################

# func _draw():
# 	draw_empty_circle(get_global_transform().affine_inverse().xform(destination),Vector2(50,50),Color(rand_color,rand_color,rand_color),1)


func _ready():
	var insignia = ImageTexture.new()
	insignia.load("res://player/insignia.png")
	get_node("CharacterSprite/InsigniaViewport/Insignia").set_texture(insignia)
	
	set_process_input(true)
	set_fixed_process(true)
	pass
