extends Node2D


func _on_Animation_finished():
	self.queue_free()


func _ready():
	var anim = get_node("Animation")
	anim.play("Explode")
	pass

