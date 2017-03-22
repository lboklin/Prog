extends "res://scripts/Character.gd"


export var accuracy_percentage = 80 # Better than a stormtrooper

onready var awareness_area = get_node("AwarenessArea")

# Holds the active target to attack and pursue
sync var p_botbrain = {
    "target" : null,
    "attack_location" : Vector2(),
    "path" : {
        "position" : Vector2(),
        "from" : null,
        "to" : []
    }
} setget set_botbrain, get_botbrain

sync func set_botbrain(botbrain):
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
    var attack_pos = GameState.rand_loc(aim_pos, 0, radius) # Generate where we (bot) accidentally/actually aimed

    return attack_pos


func ai_processing(delta, botbrain, state):
#	var botbrain = get_botbrain()

    # Maybe attack
    var attack_chance = 45 * delta
    if rand_range(0, 100) <= attack_chance :
        print(get_name(), ": Pew")
        var aim_pos
        var no_target = botbrain["target"] == null
        if no_target:
            botbrain["target"] = acquire_target(awareness_area.get_overlapping_areas())
        elif awareness_area.overlaps_area(botbrain["target"]):
            botbrain["attack_location"] = take_aim(botbrain["target"].get_path())
        else: # If target is lost
            botbrain["target"] = null # Give up
    else:
        # Maybe jump
        var moving = state["timers"].has("moving")
        var chance_of_jumping = ( 75 if moving else 85 ) * delta
        var roll = rand_range(0, 100)
        var want_to_jump = roll <= (chance_of_jumping)
        if want_to_jump:
            var from = botbrain["path"]["to"][0] if moving else botbrain["path"]["position"]
            var to = GameState.rand_loc(from, 50, MAX_JUMP_RANGE)
            if to.length() > from.length():
                var new_dir = from.normalized().rotated(PI)
                var new_to = from + to.length() * new_dir
                # print("Was going to go to       ", to,
                #     "\nbut instead am going to  ", new_to)
                to = new_to
            while botbrain["path"]["to"].size() > 1:
                botbrain["path"]["to"].pop_back()

            botbrain["path"]["to"].append(to)
            # print(get_name(), ": Hopping ", (to-from).length(), " pixels.")
            print(get_name(), ": Hop")

    return botbrain


#####################################################################
#####################################################################
#####################################################################
