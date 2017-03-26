extends Area2D


const MAX_RANGE = 700
const SAFE_RADIUS = 128

var owner = ""
var destination = Vector2()

var counter_lifetime = 0.0


func _animation_finished():
    queue_free()


func _ready():

    var anim = get_node("Animation")
    anim.play("Explode")
    anim.connect("finished", self, "_animation_finished")

    set_fixed_process(true)
