extends Node2D

var player
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
	
	# Request to attack target location
	if Input.is_action_pressed("attack"):
		player.attack_coords = mouse_pos
	
	player.act(delta)
	

#####################################################################
#####################################################################
#####################################################################


func _input(ev):
	
	# Request to jump
	if ev.is_action_pressed("move_to"):
		player.jump_target_coords.append(mouse_pos)

	if ev.is_action_pressed("spawn_enemy"):
		spawn_enemy(mouse_pos)
		
	# To reset position in case of buggery
	if ev.is_action_pressed("reset"):
		player.rooted_timer = 1
		set_pos(Vector2(0,0))
			

######################
######################
######################


func _ready():
	player = get_node("CharacterModel")
	var insignia = ImageTexture.new()
	insignia.load("res://player/insignia.png")
	player.get_node("InsigniaViewport/Insignia").set_texture(insignia)
	
	set_process_input(true)
	set_fixed_process(true)
	pass
