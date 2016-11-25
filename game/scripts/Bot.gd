extends "res://scripts/Character.gd"


export var accuracy_percentage = 80 # Better than a stormtrooper

# Holds the active target to attack and pursue
var target = null


func _fixed_process(delta):

	# Probabilities are a percentage of likelyhood within the timespan of a second

	if success(45): # Maybe consider possibly attacking, perhaps
		var awareness_area = self.get_node("AwarenessArea")
		# Try to acquire a target
		if self.target != null:
			if awareness_area.overlaps_area(self.target): # If target in sight
				# How much bot could miss - diameter of a prog is ~90
				var radius = 90 * 100 / accuracy_percentage
				var target_loc = Vector2()
				if self.target.moving:
					target_loc = self.target.jump_destination[0] # Attack target's dest
				else:
					target_loc = self.target.get_pos() # Attack target's current pos
				self.attack_location = rand_loc(target_loc, 0, radius) # Generate where bot accidentally/actually aimed
			elif not awareness_area.overlaps_body(self.target): # If target is lost
				self.target = null # Give up
		else:
			var possible_targets = awareness_area.get_overlapping_areas()
			if possible_targets.size() > 0:
				var valid_targets = []
				for target in possible_targets:
					if target.is_in_group("Prog") and target != self:
						valid_targets.append(target)
				var target_count = valid_targets.size()
				if target_count > 0:
					var chosen_target = randi() % target_count # choose one of them at random
					self.target = valid_targets[chosen_target] # make it bot's life goal to kill it.. for the moment
				else:
					self.target = null

	# Maybe jump - More likely to queue jumps while already doing it
	var want_to_jump = false
	if not self.moving:
		want_to_jump = success(85)
	else:
		want_to_jump = success(70)

	if want_to_jump:
		var jump_dest
		if self.moving:
			jump_dest = rand_loc(self.jump_destination[0], 50, MAX_JUMP_RANGE)
		else:
			jump_dest = rand_loc(self.get_pos(), 50, MAX_JUMP_RANGE)
		self.jump_destination.append(jump_dest)



	act(delta)


#####################################################################
#####################################################################
#####################################################################


func _ready():

	if primary_color ==  Color():
		primary_color = Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1))
	if secondary_color == Color():
		secondary_color = Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1))

	get_node("Sprite").set_modulate(primary_color)
	get_node("Sprite/Insignia").set_modulate(secondary_color)

	set_fixed_process(true)
