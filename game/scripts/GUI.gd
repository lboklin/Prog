
extends Control

var radial_loc = Vector2()

func _process(delta):	
	# Variable values for debugging
	var begin = "begin: " + str(get_parent().get_parent().get_node("RootView/CollisionSprites/Player").get("begin"))
	var end = "end: " + str(get_parent().get_parent().get_node("RootView/CollisionSprites/Player").get("end"))
	var pos = "pos: " + str(get_parent().get_parent().get_node("RootView/CollisionSprites/Player").get("pos"))
	var jumping = "jumping: " + str(get_parent().get_parent().get_node("RootView/CollisionSprites/Player").get("jump"))
	get_node("Debug").set_text(begin + "\n" + end + "\n" + pos + "\n" + jumping)

	# Not used for now
#	var mpos = get_viewport().get_mouse_pos()
#	var dist = mpos - radial_loc 
#	dist = sqrt(dist.x*dist.x + dist.y*dist.y)

#	# GUI pos
	var viewpos = get_parent().get_camera_pos()
	var screensize = get_viewport().get_visible_rect().size
	self.set_pos(get_viewport_transform().xform(viewpos) - screensize)
	
	# Radial menu - pops up when simply right clicking
#	if ( Input.is_mouse_button_pressed(2) and !Input.is_action_pressed("hurry") ):
#		get_node("RadialMenu").set_pos(radial_loc)
#		get_node("RadialMenu").set_opacity(1)
#	else:
#		get_node("RadialMenu").set_opacity(0)
	
func _input(ev):
	if ( ev.type==InputEvent.MOUSE_BUTTON and ev.button_index == 2 and ev.pressed ):
		radial_loc = ev.pos - (get_node("RadialMenu").get_size() / 2)

func _ready():
	set_process_input(true)
	set_process(true)
	pass



