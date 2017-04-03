extends CanvasLayer

onready var nd_game_round = get_node("/root/GameRound")
#onready var nd_player = GameState.player_name
onready var nd_scoreboard = get_node("Control/Scoreboard")
onready var nd_vbox_container = get_node("Control/Scoreboard/VBoxContainer")
# onready var nd_name_score = get_node("Control/Scoreboard/ScrollContainer/NameScore")
onready var nd_timer_label = get_node("Control/RoundTimer")
onready var nd_respawn_label = get_node("Control/RespawnTimer")

var respawn_timer = 0


func _update_score(name, score):
    return
    # nd_names_label.set_text(nd_names_label.get_text() + name + "\n")
    # nd_points_label.set_text(nd_points_label.get_text() + str(score) + "\n")


# func add_to_scoreboard(name, score):
#     var nd_cont = HSplitContainer.new()
#     var nd_ns_l = Label.new()
#     var nd_pts_l = Label.new()

#     nd_ns_l.set_text(name)

#     nd_pts_l.set_text(str(score))
#     nd_pts_l.set_anchor_and_margin(nd_pts_l.get_constant("MARGIN_RIGHT"), nd_pts_l.get_constant("ANCHOR_END"), 20)

#     nd_cont.set_pos(get
#     nd_vbox_container.add_child(nd_cont)

#     nd_cont.add_child(nd_ns_l)
#     nd_cont.add_child(nd_pts_l)

func add_to_scoreboard(name, score):
    var nd_name_score = preload("res://gui/NameScore.tscn").instance()

    nd_name_score.set_name_score(name, score)

    var c_children = get_parent().get_child_count()
    nd_name_score.set_pos(Vector2(0, c_children * 20))

    nd_vbox_container.add_child(nd_name_score)


func show_respawn_timer(timer):
    nd_respawn_label.set_hidden(true)


func _process(delta):
    nd_timer_label.set_text("Round Time: " + str(floor(GameState.get_round_timer())))
    if respawn_timer > 0:
        respawn_timer -= delta
        nd_respawn_label.set_text("Respawning in: " + str(floor(respawn_timer)))
    else:
        nd_respawn_label.set_hidden(false)



func _ready():
    nd_game_round.connect("score_updated", self, "_update_score")

    # nd_names_label.set_text("")
    # nd_points_label.set_text("")
    add_to_scoreboard(GameState.player_name, 0)
    set_process(true)
