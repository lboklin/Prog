extends "res://scripts/Character.gd"

#####################################################################
#####################################################################
#####################################################################


func _unhandled_input(ev):
    if ev.is_action_pressed("spawn_enemy"):
        GameState.rpc("spawn_enemy", GameState.rand_loc(mouse_pos, 0, 600))
    if ev.is_action_pressed("quit_game"):
        GameState.quit_game()

    if get_state()["timers"].has("dead"):
        return

    if Input.is_action_just_pressed("move_to"):
        var state = get_state()
        var is_empty_q = state["path"]["to"].empty()
        var is_duplicate_input = false if is_empty_q else mouse_pos == state["path"]["to"].back()
        var out_of_range = state["path"]["position"].distance_to(mouse_pos) > MAX_JUMP_RANGE
        if not is_duplicate_input and not out_of_range:
            if is_empty_q:
                state["path"]["from"] = state["path"]["position"]
            state["path"]["to"].append(mouse_pos)
            set_state(state)
            GameState.spawn_click_indicator(mouse_pos, "move_to")
        elif out_of_range:
            GameState.spawn_click_indicator(mouse_pos, "no_can_do")
    if Input.is_action_just_pressed("attack"):
        var state = get_state()
        state["target"] = mouse_pos
        set_state(state)
        rset("slave_atk_loc", state["target"])
        GameState.spawn_click_indicator(mouse_pos, "attack")


######################
######################
######################


func _ready():
#	var nd_hud = load("res://gui/HUD.tscn").instance()
#	add_child(nd_hud)
    set_process_unhandled_input(is_network_master())
