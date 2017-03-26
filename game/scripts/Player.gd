extends "res://scripts/Character.gd"

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
        var state = get_state()
        state["target"] = mouse_pos
        set_state(state)
        rset("slave_atk_loc", state["target"])
        GameState.spawn_click_indicator(mouse_pos, "attack")
    if ev.is_action_pressed("spawn_enemy"):
        GameState.rpc("spawn_enemy", GameState.rand_loc(mouse_pos, 0, 600))
    if ev.is_action_pressed("quit_game"):
        get_tree().quit()


######################
######################
######################


func _ready():
#	var nd_hud = load("res://gui/HUD.tscn").instance()
#	add_child(nd_hud)
    set_process_unhandled_input(is_network_master())
