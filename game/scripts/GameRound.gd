extends Node


var round_timer = 0


func _process(delta):

	self.round_timer += delta


func _ready():

	set_process(true)
