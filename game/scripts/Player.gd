extends "res://scripts/Character.gd"

# Spawn an NPC to play with
sync func spawn_enemy(loc):
#	return
    ## Bot.gd needs serious cleanup before we can do this again
    var enemy = preload("res://npc/Bot.tscn").instance()
    enemy.set_pos(loc)
    get_parent().add_child(enemy)


#####################################################################
#####################################################################
#####################################################################


func _unhandled_input(ev):
    if Input.is_action_just_pressed("move_to"):
        var path = get_path()
        if not (( path["to"].size() > 0 ) and ( mouse_pos == path["to"].back() )):
            path["from"] = path["from"] if path["to"].size() > 0 else get_pos()
            path["to"].append(mouse_pos)
            set_path(path)
            GameState.spawn_click_indicator(mouse_pos, "move_to")
    if Input.is_action_just_pressed("attack"):
        var weapon = get_weapon_state()
        weapon["aim_pos"] = mouse_pos
        set_weapon_state(weapon)
        rset("slave_atk_loc", weapon["aim_pos"])
    if ev.is_action_pressed("spawn_enemy"):
        rpc("spawn_enemy", rand_loc(mouse_pos, 200, 600))
    if ev.is_action_pressed("quit_game"):
        get_tree().quit()


######################
######################
######################


func _ready():
    set_process_unhandled_input(is_network_master())
