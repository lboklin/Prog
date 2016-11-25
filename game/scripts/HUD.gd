extends CanvasLayer


#onready var player = get_parent().get_parent()
onready var points_label = get_node("Points")


#var points = 0


func _process(delta):

	var points = str(GameRound.points)
	points_label.set_text("Score: " + points)


func _ready():

	set_process(true)
