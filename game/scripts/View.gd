
extends Camera2D

var zoom = Vector2()

func _input(ev):
	if (ev.type == InputEvent.MOUSE_BUTTON and ev.button_index == 4): # Scroll wheel up
		zoom = get_zoom()
		zoom *= 0.92
		if ( zoom.x <= 0.05 ):
			zoom = Vector2(0.05,0.05)
		else:
			set_zoom(zoom)
	if (ev.type == InputEvent.MOUSE_BUTTON and ev.button_index == 5): # Scroll wheel down
		zoom = get_zoom()
		zoom *= 1.08
		if ( zoom.x > 0.9 ):
			zoom = Vector2(1.0,1.0)
			set_zoom(zoom)
		else:
			set_zoom(zoom)
		

func _ready():
	set_process_input(true)
	pass


