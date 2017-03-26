extends Area2D


const MAX_RANGE = 700
const SAFE_RADIUS = 128

onready var nd_anim = get_node("Animation")

var owner = ""
var destination = Vector2()


func _animation_finished():
    queue_free()


func _ready():
    var pos = get_global_pos()
    var dir = destination.angle()
    # set_rot(dir - deg2rad(90))
    set_rot(dir - deg2rad(-90))

    var current_pos = self.get_global_pos()
    var dir = (self.destination - current_pos).normalized()
    set_rot(dir.angle() - deg2rad(90))
    # set_scale(Vector2(0.5+abs(dir.x/2), 1))
    # var len = clamp((destination - current_pos).length() / MAX_RANGE, 0.0, 1)
    var len = (destination - current_pos).length() / MAX_RANGE
    set_scale(Vector2(len, 1))
    GameState.spawn_click_indicator(destination, "attack")
#    get_node("GlowLight").set_scale(Vector2(len * 1.5, 1))


    var len = (destination - pos).length() / MAX_RANGE
    set_scale(Vector2(len, 1))

    nd_anim.play("Beam")
    nd_anim.connect("finished", self, "_animation_finished")

    set_fixed_process(true)
