"""
The base character class which is meant to be
inherited by all characters. It contains necessary
common functions for it to behave like a character.
It is designed to be inherited in particular by
player characters and bots.

Functions are to be as pure as possible, meaning
that they should cause no or as few side effects as
possible, and they should ideally always return
the same value when the arguments provided have the
same value. This makes it much easier to predict
the results and also allows for easier syncing
between clients over a network.
"""

extends Area2D

# signal damaged_by()
signal player_killed()

# Your Prog's very own beautiful color scheme
export(Color) sync var primary_color
export(Color) sync var secondary_color

const WEP_CD = 1.0    # Weapon cooldown
const JUMP_CD = 0.1    # Jump cooldown after landing
const MAX_SPEED = 1500    # Max horizontal (ground) speed
const MAX_JUMP_RANGE = 1000    # How far you can jump from any given starting pos
const JUMP_Q_LIM = 2    # Jump queue limit

onready var nd_sprite = get_node("Sprite")
onready var nd_insignia = get_node("Sprite/Insignia/InsigniaViewport/InsigniaSprite")
onready var nd_shadow = get_node("Shadow")
onready var nd_shadow_opacity = nd_shadow.get_opacity()
onready var nd_shadow_scale = nd_shadow.get_scale()
onready var nd_hud = GameState.nd_game_round.get_node("HUD")

# "enums"
# enum Condition {OK, DEAD, RESPAWNING, STUNNED}
# enum Action {IDLE, MOVING, ATTACKING, BUSY}
# enum ""{GOOD, MOVING, ATTACKING, STUNNED, RESPAWNING, DEAD}
# enum Power {ON, OFF}

var my_name
var my_id
var mouse_pos = Vector2()

#slave var slave_pos = Vector2()
slave var slave_atk_loc = Vector2()
#slave var slave_motion = Vector2()
slave var slave_focus = Vector2()

# Counters
var points = 0
#var time_of_death = null    # If applicable


## Dicts

sync var p_state = {
    "timers" : {},
    "motion" :  Vector2(), # Horizontal
    "target" :  null,
    "height" :  0          # Vertical
} setget set_state, get_state

sync var p_path = {
    "position" : Vector2(),
    "from" : null,
    "to" : [],    # Take note that this is a jump queue array
} setget set_path, get_path


###########################
## SetGetters / queries    ##
###########################

#-------------
# General state

sync func set_state(new_state):
    # if new_state["timers"].has("dead"):
    #     queue_free()
    if new_state["timers"].has("stunned"):
        var t = new_state["timers"]["stunned"]
        new_state["timers"].clear()
        new_state["timers"]["stunned"] = t
    p_state = new_state
    return p_state

func get_state():
    return p_state

#-------------
#-------------
# Jump state

sync func set_path(new_path):
    p_path = new_path
    return p_path

func get_path():
    return p_path

#-------------

##########################


# func update_states(delta, timers):

#     if timers.size() > 0:
#         for timer in timers:
#             timers[timer] -= delta
#             if (timers[timer] <= 0.0):
#                 timers.erase(timer)

#     return timers


##################################################

# For rotating the insignia sprite towards the given point (point is in global coords)
master func new_rot(delta, current_pos, current_rot, point):
    var dir = point - current_pos
    dir.y *= 2

    # Use degrees 'cause it be more intuitive
    var new_rot_deg = rad2deg(dir.angle())
    var current_rot_deg = rad2deg(current_rot)

    # Always count rot in the positive
    while new_rot_deg < 0:
        new_rot_deg = new_rot_deg + 360
    while current_rot_deg < 0:
        current_rot_deg = current_rot_deg + 360

    var d_angle_deg = new_rot_deg - current_rot_deg

    var s = sign(d_angle_deg)
    var d_angle_deg = abs(d_angle_deg)

    # Don't go the long way around, it's stupid
    if d_angle_deg > 180:
        s *= -1
        d_angle_deg = 360 - d_angle_deg

    # Now go back to radians to make Godot happy
    var d_angle = deg2rad(d_angle_deg)

    var rot_speed = 3
    var min_rot_speed = 0.04

    var smooth_rot_speed = delta * rot_speed * d_angle * d_angle
    var d_rot = s * min(d_angle, max(smooth_rot_speed, min_rot_speed))
    var new_rot = current_rot + d_rot

    # Don't keep inflating the rot value
    if new_rot > 2*PI:
        new_rot -= 2*PI
    elif new_rot < 0:
        new_rot += 2*PI

    return new_rot


# Well, this one makes you respawn
func respawn(pos = GameState.rand_loc(Vector2(0,0),0,1000)):

    set_monitorable(true)    # Enable detection by other bodies and areas
    set_hidden(false)
    set_pos(pos)

    var state = get_state()
    state["timers"]["shield"] = 2.0
    set_state(state)
    rset("set_path", { "from" : null, "to" : [] })


func _area_enter(nd_area):
    if nd_area.is_in_group("Damaging"):
        if not nd_area.owner == my_name:
            self.call_deferred("damaged_by", nd_area.owner)

func die(state, killer):
    var state = get_state()
    state["timers"]["dead"] = GameState.get_round_timer() / 2

    set_monitorable(false)
    set_hidden(true)

    var nd_death_anim = preload("res://common/DeathEffect.tscn").instance()
    nd_death_anim.set_pos(get_pos())
    get_parent().add_child(nd_death_anim)

    emit_signal("player_killed", killer)
    # print(get_name() + " was killed by ", meanie, " and will be back in ", state["timers"]["dead"])

    # if is_in_group("Bot"):
    #     queue_free()

    return state


# Get hit (and die - at least until better implementation is implemented)
sync func damaged_by(meanie):
    print(my_name, " was hit by ", meanie)

    var state = get_state()
    if state["timers"].has("shield"):
        # Fancy shield deflection animation?
        return
    elif state["timers"].has("dead"):
        return

    set_state(die(state, meanie))
    return


sync func spawn_energy_beam(from, to):
    var nd_energy_beam = preload("res://scenes/weapon/EnergyBeam.tscn").instance()
    nd_energy_beam.owner = my_name
    nd_energy_beam.destination = to
    nd_energy_beam.set_global_pos(from)
    get_parent().add_child(nd_energy_beam)

    var nd_beam_impact = preload("res://scenes/weapon/EnergyBeamImpact.tscn").instance()
    nd_beam_impact.owner = my_name
    nd_beam_impact.set_pos(to)
    get_parent().add_child(nd_beam_impact)


slave func slave_attack(loc):
    spawn_energy_beam(get_pos(), loc)
    self.slave_atk_loc = null


# Attack given location (not relative to prog)
sync func attack(state):
    spawn_energy_beam(get_pos(), state["target"])

    state["timers"]["attacking"] = 0.2
    state["timers"]["weapon_cd"] = WEP_CD
    state["target"] = null

    set_state(state)


master func set_colors(primary, secondary):

    if primary_color != null:
        # nd_sprite.set_modulate(primary)
        nd_sprite.rpc("set_modulate", primary_color)
    if secondary_color != null:
        # nd_insignia.set_modulate(secondary)
        nd_insignia.rpc("set_modulate", secondary_color)
    return


sync func animate_jump(state, path):
    var jump_height = state["height"]
    # If we're not in the air, just set everything
    # accordingly and skip the calculations.
    if jump_height <= 0:
        set_z(1)    # Back onto ground
        nd_sprite.set_pos(Vector2(0, 0))
        nd_shadow.set_opacity(nd_shadow_opacity)
        nd_shadow.set_scale(nd_shadow_scale)
    else:
        # Set sprite vertical pos based on height and adjusted for the perspective
        var sprite_pos = Vector2(0, -1) * ( jump_height / 2 )

        # Since the lightsource is ~26 degrees rotated downwards vertically
        # the shadow should project about halfway between directly below
        # and (from the camera's perspective) directly behind the Prog.
        var shadow_pos = sprite_pos * 0.5

        var no_shadow_h = 1200
        var shadow_opacity = 1 - max(0, min(1, ( jump_height / no_shadow_h )))
        shadow_opacity *= nd_shadow_opacity
        if shadow_opacity > nd_shadow_opacity:
            print("That's not right...")

        var shadow_shrink_ratio = Vector2(0.8, 0.5) * max(0, min(1, ( jump_height / (no_shadow_h*4) )))
        var shadow_scale = Vector2(1, 1) - shadow_shrink_ratio
        shadow_scale *= nd_shadow_scale

        nd_sprite.set_pos(sprite_pos)
        nd_shadow.set_pos(shadow_pos)
        nd_shadow.set_scale(shadow_scale)
        nd_shadow.set_opacity(shadow_opacity)
        set_z(jump_height + 1)    # +1 to render after everything below

        state["timers"]["moving"] = 10.0
    return


sync func set_motion_state(path, state):

    # Check if there are any jumps queued and
    # if so pop any that hold our current pos.
    # Use while loop to catch any duplicates.
    while path["to"].size() > 0 and path["position"] == path["to"][0]:
        path["to"].pop_front()
        path["from"] = path["position"] if path["to"].size() > 0 else null
        set_path(path)

    animate_jump(state, path)

    # Check if (supposed to be) moving and apply motion
    if (state["motion"].length() > 0 or path["to"].size() > 0):
        # Disable detection by other bodies and areas.
        # This is to avoid hitting or being hit by anything while jumping.
        set_monitorable(false)
        set_pos(path["position"] + state["motion"])
    # Stun on landing
    elif state["timers"].has("moving"):
        set_monitorable(true)
        state["timers"]["stunned"] = JUMP_CD
        set_state(state)


# Update the state of motion to reflect what is desired
master func new_motion_state(delta, path, state):

    var dist_covered = path["position"] - path["from"]
    dist_covered.y *= 2
    dist_covered = dist_covered.length()

    var dist_total = path["to"][0] - path["from"]
    dist_total.y *= 2
    dist_total = dist_total.length()

    var dir = path["to"][0] - path["position"]
    dir.y *= 2
    dir = dir.normalized()


    # Where to put ourselves next
    var speed = min(dist_total*2, MAX_SPEED)
    state["motion"] = dir * speed * delta
    state["motion"].y *= 0.5
    # If about to overshoot destination
    var coming_in_hot = ( state["motion"].length() > 0 ) and ( state["motion"].length() >= path["position"].distance_to(path["to"][0]) )
    if coming_in_hot:
        state["motion"] = path["to"][0] - path["position"]

    var jump_completion = dist_covered / dist_total if dist_total > 0 else 1
    state["height"] = sin(PI*jump_completion) * dist_total * 0.4

    return state


#####################################################################
#####################################################################
#####################################################################


func _fixed_process(delta):

    var state = get_state()

    var incapacitated = false
    # Update all state timers.
    # If we don't create a new dict and copy over the ones we want, non-fatal
    # errors about invalid keys sprouts for some reason. [Rant about mutable states].
    var timers = {}
    for timer in state["timers"]:
        state["timers"][timer] -= delta
        if (state["timers"][timer] > 0.0):
            timers[timer] = state["timers"][timer]
            if timer == "stunned" or timer == "dead":
                incapacitated = true
        elif timer == "dead":
            respawn()
            timers = {}
            continue
    state["timers"] = timers

    if incapacitated:
        return

    var path = get_path()
    path["position"] = get_pos()


    var focus = Vector2()

    if is_network_master():
        if is_in_group("Bot"):
            var botbrain = get_botbrain()
            mouse_pos = GameState.rand_loc(botbrain["path"]["position"], 0, 1) if ( (rand_range(0, 100)) <= (60 * delta) ) else mouse_pos
            botbrain = ai_processing(delta, botbrain, state)
            path = botbrain["path"]
            state["target"] = botbrain["attack_location"]
            rpc("set_botbrain", botbrain)
        else:
            mouse_pos = get_global_mouse_pos()


        if path["to"].size() > 0:
            if path["to"].size() > JUMP_Q_LIM:
                path["to"].resize(JUMP_Q_LIM + 1)
            if path["from"] == null:
                path["from"] = path["position"]
            rset("set_path", path)
            rpc("set_motion_state", path, new_motion_state(delta, path, state))

        if state["timers"].empty() and not state["timers"].has("weapon_cd") and state["target"] != null:
           rpc("attack", state)

        focus = state["target"] if (state["target"] != null) and state["timers"].has("attacking") else ( path["to"][0] if not path["to"].empty() else mouse_pos )
        rset("slave_focus", focus)
        rpc("set_state", state)
        rpc("set_path", path)
    else:
        focus = slave_focus
        # if slave_atk_loc != null:
        #     slave_attack(slave_atk_loc)


    nd_insignia.set_rot(new_rot(delta, path["position"], nd_insignia.get_rot(), focus))

    return


######################
######################
######################


func _ready():
    if is_network_master():
        if is_in_group("Bot"):
            rset("primary_color", Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1), rand_range(0.5, 1)))
            rset("secondary_color", Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1), rand_range(0.5, 1)))

    self.connect("area_enter", self, "_area_enter")

    set_colors(primary_color, secondary_color)

    my_id = get_tree().get_network_unique_id()
    my_name = self.get_name()

    set_fixed_process(true)
