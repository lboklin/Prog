extends Node2D


func _on_AnimationPlayer_finished():
	self.queue_free()


func _ready():

	var anim = self.get_node("AnimationPlayer")

	return
