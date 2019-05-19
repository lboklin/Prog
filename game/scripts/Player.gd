extends Node
class_name Player

export(NodePath) var prog_path: NodePath

onready var prog: Prog = get_node(prog_path) as Prog


func _input(_ev):
    if prog.state["timers"].has("dead"):
        return

    var root = get_tree().get_root()

    if Input.is_action_just_pressed("move_to"):
        var cur_state: Dictionary = prog.get_state()
        var is_empty_q: bool = cur_state["path"]["to"].empty()
        var m_pos: Vector2 = prog.mouse_pos
        var dest_queue: Array = cur_state["path"]["to"]
        var is_duplicate_input: bool = is_empty_q && m_pos == dest_queue.back()
        var pos: Vector2 = cur_state["path"]["position"]
        var out_of_range: bool = pos.distance_to(m_pos) > prog.MAX_JUMP_RANGE
        if not is_duplicate_input and not out_of_range:
            if is_empty_q:
                cur_state["path"]["from"] = pos
            dest_queue.append(m_pos)
            prog.set_state(cur_state)
            GameState.spawn_click_indicator(root, m_pos, "move_to")
        elif out_of_range:
            GameState.spawn_click_indicator(root, m_pos, "no_can_do")
    if Input.is_action_just_pressed("attack"):
        var cur_state = prog.get_state()
        cur_state["target"] = prog.mouse_pos
        prog.set_state(cur_state)
        rset("slave_atk_loc", cur_state["target"])
        GameState.spawn_click_indicator(root, prog.mouse_pos, "attack")


######################
######################
######################


func _ready():
    # Add camera to your prog
    add_child((load("res://player/PlayerCam.tscn") as PackedScene).instance())
    # Add a HUD for displaying name and score
    add_child((load("res://gui/HUD.tscn") as PackedScene).instance())
