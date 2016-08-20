
extends Label

func _process(delta):
#	var viewpos = get_parent().get_node("View").get_camera_pos()
#	viewpos = get_viewport_transform().affine_inverse().xform(viewpos)
#	var viewcenterpos = get_parent().get_node("View").get_camera_screen_center()
#	viewcenterpos = get_viewport_transform().affine_inverse().xform(viewcenterpos)
#	
#	var viewsize = (viewcenterpos - viewpos) * zoom * 2
#	var finalpos = viewcenterpos - (viewsize / 2)
#	finalpos = get_viewport_transform().xform(finalpos)
#	self.set_pos(finalpos)
#	
#	
#	var campos = get_viewport().get_visible_rect().pos
#	var screensize = get_viewport().get_visible_rect().size
#	self.set_pos((campos + Vector2(10,10)) - screensize/2)
	
	var begin = "begin: " + str(get_parent().get_node("CollisionTiles/Player").get("begin"))
	var end = "end: " + str(get_parent().get_node("CollisionTiles/Player").get("end"))
	var pos = "pos: " + str(get_parent().get_node("CollisionTiles/Player").get("pos"))
	var jumping = "jumping: " + str(get_parent().get_node("CollisionTiles/Player").get("jump"))
	self.set_text(begin + "\n" + end + "\n" + pos + "\n" + jumping)

func _ready():
	set_process(true)
	pass


