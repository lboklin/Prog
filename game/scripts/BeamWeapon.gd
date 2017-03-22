extends Area2D


const MAX_RANGE = 500
const SAFE_RADIUS = 128

onready var shape_projectile = self.get_node("CollisionShapeBeam")
onready var shape_explosion = self.get_node("CollisionShapeExplosion")

var destination = Vector2()
var hit = false


func _animation_finished():
  queue_free()


func _fixed_process(delta):
  var colliders = self.get_overlapping_areas()
  if not hit and colliders.size() > 0:
    for collider in colliders:
      if collider != null and collider.has_method("hit"):
        collider.hit()
        self.hit = true


func _ready():
  var current_pos = self.get_global_pos()
  var dir = (self.destination - current_pos).normalized()
  set_rot(dir.angle() - deg2rad(90))
  set_scale(Vector2(0.5+abs(dir.x/2), 1))

  var anim = get_node("Animation")
  anim.play("Beam")
  anim.connect("finished", self, "_animation_finished")

  set_fixed_process(true)
