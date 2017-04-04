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
    # nd_names_label.set_text(nd_names_label.get_text() + name + "\n")
    # nd_points_label.set_text(nd_points_label.get_text() + str(score) + "\n")
    if nd_vbox_container.has_node(name):
        nd_vbox_container.get_node(name).set_name_score(name, score)
    return


func add_to_scoreboard(name, score):
    var nd_name_score = preload("res://gui/NameScore.tscn").instance()

    nd_name_score.set_name_score(name, score)
    nd_name_score.set_name(name)  # Set node name so we can later update existing entries

    # This is kind of a weird solution, but this is a way to put the elements in rows
    # instead of on top of each other.
    var c_children = get_parent().get_child_count()
    nd_name_score.set_pos(Vector2(0, c_children * 20))

    nd_vbox_container.add_child(nd_name_score)


func _process(delta):
    nd_timer_label.set_text("Elapsed Round Time: " + str(floor(GameState.get_round_timer())))
    if respawn_timer > 0:
        respawn_timer -= delta
        nd_respawn_label.set_text("Seconds until respawn: " + str(respawn_timer).pad_decimals(2))
        nd_respawn_label.set_hidden(false)
    else:
        nd_respawn_label.set_hidden(true)



func _ready():
    nd_game_round.connect("score_updated", self, "_update_score")

    # nd_names_label.set_text("")
    # nd_points_label.set_text("")
#    add_to_scoreboard(GameState.player_name, 0)
    set_process(true)
