extends "res://scripts/Character.gd"


export var accuracy_percentage = 80 # Better than a stormtrooper

onready var awareness_area = get_node("AwarenessArea")

var fake_mouse_pos = Vector2(0,0)

# Holds the active target to attack and pursue
sync var p_botbrain = {
	"target"			:	null,
	"attack_location"	:	Vector2(),
} setget set_botbrain, get_botbrain

func set_botbrain(botbrain):
	p_botbrain = botbrain
	return botbrain

func get_botbrain():
	return p_botbrain


func acquire_target(possible_targets):
	var new_target = null
	if possible_targets.size() > 0:
		var valid_targets = []
		for target in possible_targets:
			if target.is_in_group("Prog") and target != self:
				valid_targets.append(target)
		new_target = null if valid_targets.empty() else valid_targets[randi() % valid_targets.size()]

	return new_target


func take_aim(target_path):
	# How much bot could miss - diameter of a prog is ~90
	var radius = 90 * 100 / accuracy_percentage
	# Take aim, and if target is moving, aim towards where it's going
	var aim_pos = target_path["position"] if target_path["to"].empty() else target_path["to"][0]
	var attack_pos = rand_loc(aim_pos, 0, radius) # Generate where we (bot) accidentally/actually aimed

	return attack_pos


#####################################################################
#####################################################################
#####################################################################


func _fixed_process(delta):

	# Update all states, timers and other statuses and end processing here if stunned
	var tmp = update_states(delta, get_state(), get_condition_timers()) # Yes, temporary inelegancy
	var state = tmp[0]
	var path = get_path()
	var ctimers = set_condition_timers(tmp[1])

	path["position"] = get_pos()

	if state["condition"] == STUNNED:
		return

	fake_mouse_pos = rand_loc(path["position"], 0, 1) if ( (randi() % 100) <= (60 * delta) ) else fake_mouse_pos

	var focus = Vector2()

	if not is_network_master():
		focus = slave_focus
	else:
		var path = get_path()
		var weapon = get_weapon_state()
		rset_unreliable("slave_pos", path["position"])

		## Bot things ##

		var botbrain = get_botbrain()

		# Maybe attack
		var attack_chance = 45 * delta
		if (randi() % 100) <= (attack_chance) :
			print(get_name(), ": Pew")
			var aim_pos
			var no_target = botbrain["target"] == null
			if no_target:
				botbrain["target"] = acquire_target(awareness_area.get_overlapping_areas())
			elif awareness_area.overlaps_area(botbrain["target"]):
				weapon["aim_pos"] = take_aim(botbrain["target"].get_path())
			else: # If target is lost
				botbrain["target"] = null # Give up

		# Maybe jump
		var moving = state["motion"].length() > 0
		var chance_of_jumping = ( 70 if moving else 85 ) * delta
		var want_to_jump = (randi() % 100) <= (chance_of_jumping)
		if want_to_jump:
			var from = path["to"][0] if moving else path["position"]
			var to = rand_loc(from, 50, MAX_JUMP_RANGE)
			path["to"].append(to)
			print(get_name(), ": Hop")

		#################

		if path["to"].size() > 0:
			if path["to"].size() > JUMP_Q_LIM:
				path["to"].resize(JUMP_Q_LIM + 1)
			if path["from"] == null:
				path["from"] = path["position"]
			set_path(path)
			rpc("set_motion_state", path, new_motion_state(delta, path, state), get_condition_timers())

		if weapon["aim_pos"] != null:
			attack(weapon["aim_pos"])

		focus = weapon["aim_pos"] if ( state["action"] == BUSY ) else ( path["to"][0] if not path["to"].empty() else fake_mouse_pos )
		rset("slave_focus", focus)

		set_botbrain(botbrain)
		set_state(state)

	insignia.set_rot(new_rot(delta, path["position"], insignia.get_rot(), focus))

	return


#####################################################################
#####################################################################
#####################################################################


func _ready():

	primary_color = Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1), rand_range(0.5, 1))
	get_node("Sprite").set_modulate(primary_color)
	secondary_color = Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1), rand_range(0.5, 1))
	get_node("Sprite/Insignia/InsigniaViewport/InsigniaSprite").set_modulate(secondary_color)

	set_fixed_process(true)
