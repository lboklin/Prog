
extends Camera2D

var zoom = Vector2()

func _fixed_process(delta):

	var viewpos = get_parent().get_node("RootView/CollisionSprites/Player").get_pos()
	self.set_offset(viewpos)
		

func _ready():
	set_fixed_process(true)
	pass


