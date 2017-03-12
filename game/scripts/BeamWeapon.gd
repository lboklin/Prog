extends Area2D


const ADVANCE_SPEED = 2600.0
const MAX_RANGE = 500
const SAFE_RADIUS = 128

onready var shape_projectile = self.get_node("CollisionShapeBeam")
onready var shape_explosion = self.get_node("CollisionShapeExplosion")

var destination = Vector2()
var direction = Vector2(1,0)
# var distance = 0
# var dist_traveled = 0

var exploded = false
var hit = false


func _animation_finished():

  queue_free()


func explode():

  get_node("Animation").play("Explode")
  self.exploded = true


func _fixed_process(delta):

#   if not self.exploded:
#     var current_pos = self.get_pos()

#     var dist_to_target = self.destination - current_pos
#     dist_to_target.y *= 0.5
#     dist_to_target = dist_to_target.length()
#     var motion = self.direction * delta * self.ADVANCE_SPEED
#     motion.y *= 0.5
#     if motion.length() >= dist_to_target:
#       motion = self.destination - current_pos
#       self.set_pos(current_pos + motion)
#       self.explode()
#     else:
# #			self.move(motion)
#       self.set_pos(current_pos + motion)
#       motion.y *= 2
#       self.dist_traveled += motion.length()

  var colliders = self.get_overlapping_areas()
  if not hit and colliders.size() > 0 and self.dist_traveled > SAFE_RADIUS :
    for collider in colliders:
      if collider != null and collider.has_method("hit"):
        collider.hit()
        self.hit = true
      if not self.exploded:
        self.explode()



func _ready():

  get_node("Animation").connect("finished", self, "_animation_finished")

  var current_pos = self.get_global_pos()

  var dist = self.destination - current_pos
  dist.y *= 2
  self.distance = dist.length()
  var dir = self.destination - current_pos
  dir.y *= 2
  self.direction = dir.normalized()

  dir = dir.normalized()

#	var rot_dir = dir.angle()
#	self.get_node("Object/ExplosionForwards").set_rot(rot_dir)
#	var rot_dir = dir.angle() - deg2rad(180)
#	self.get_node("Object/ExplosionBackwards").set_rot(rot_dir)

  dir.y *= 0.5
  var rot_dir = dir.angle() - deg2rad(180)
#	rot_dir = rot_dir - deg2rad(180)
  self.get_node("Object/EnergyBall").set_rot(rot_dir)

  set_fixed_process(true)