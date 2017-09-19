extends Node2D

func _on_AnimationPlayer_animation_finished( name ):
        self.queue_free()
