extends KinematicBody2D


const ADVANCE_SPEED = 2600.0
const MAX_RANGE = 500
const SAFE_RADIUS = 128

onready var shape_projectile = self.get_node("CollisionShapeProjectile")
onready var shape_explosion = self.get_node("CollisionShapeProjectile")

var destination = Vector2()
var direction = Vector2(1,0)
var distance = 0
var dist_traveled = 0


func _animation_finished():

	queue_free()


func explode():

	# Stop exploded projectiles from colliding with each other
#	if not self.shape_projectile.is_queued_for_deletion():
#		self.shape_projectile.set_trigger(true)

	# Set the explosion orientation based on how it collided
#	var col_norm = self.get_collision_normal()
#	var vel_at_impact = self.ADVANCE_SPEED * self.direction
#	var collision_vector = self.get_collider_velocity() * col_norm
#	var lost_vel = (vel_at_impact - collision_vector).length()
#	var spread_angle_deg_width = lerp(85, 45, lost_vel / self.ADVANCE_SPEED)
#	var spread_dir = vel_at_impact.slide(collision_vector).angle() - deg2rad(180)

#	var explosion = self.get_node("Object/ExplosionForwards")
#	explosion.set_param(0, spread_dir)
#	explosion.set_param(1, spread_angle_deg_width)

#	rot_dir = dir.angle() - deg2rad(180)
#	self.get_node("Object/ExplosionForwards").set_rot(rot_dir)

	self.shape_explosion.set_trigger(false)
	get_node("Animation").play("Explode")


func _fixed_process(delta):

	var hit = false
	var current_pos = self.get_pos()

	var dist_to_target = self.destination - current_pos
	dist_to_target.y *= 0.5
	dist_to_target = dist_to_target.length()

	if not hit:
		var motion = self.direction * delta * self.ADVANCE_SPEED
		motion.y *= 0.5
		if motion.length() >= dist_to_target:
			self.move(self.destination - current_pos)
			hit = true
		elif self.is_colliding():
				hit = true
				var collider = get_collider()
				if collider.is_in_group("Mortals"):
					collider.die()
		else:
			self.move(motion)
			motion.y *= 2
			self.dist_traveled += motion.length()
			if self.dist_traveled > SAFE_RADIUS:
				self.shape_projectile.set_trigger(false)

	if hit:
		explode()
		self.set_fixed_process(false)


func _ready():

	get_node("Animation").connect("finished", self, "_animation_finished")

	self.shape_projectile.set_trigger(true)
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