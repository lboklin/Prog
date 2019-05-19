extends CanvasLayer
class_name HUD

onready var nd_game_round = get_node("/root/GameRound")
#onready var nd_player = nd_game_state.player_name
#onready var nd_scoreboard = get_node("Control/Scoreboard")
onready var nd_vbox_container = get_node("Control/Scoreboard/VBoxContainer")
# onready var nd_name_score = get_node("Control/Scoreboard/ScrollContainer/NameScore")
onready var nd_timer_label = get_node("Control/RoundTimer")
onready var nd_respawn_label = get_node("Control/RespawnTimer")
onready var nd_game_state = $"/root/GameState"

var respawn_timer = 0


func update_score(name, score):
    # nd_names_label.set_text(nd_names_label.get_text() + name + "\n")
    # nd_points_label.set_text(nd_points_label.get_text() + str(score) + "\n")
    if nd_vbox_container.has_node(name):
        nd_vbox_container.get_node(name).set_name_score(name, score)
    return


func add_to_scoreboard(name, score):
    var nd_name_score = preload("res://gui/NameScore.tscn").instance()

    nd_name_score.set_name_score(name, score)
    nd_name_score.set_name(name.replace("@", ""))  # Set node name so we can later update existing entries

    # This is kind of a weird solution, but this is a way to put the elements in rows
    # instead of on top of each other.
    var c_children = get_parent().get_child_count()
    nd_name_score.rect_position = Vector2(0, 20 + c_children * 20)

    nd_vbox_container.add_child(nd_name_score)


func _player_killed(_player, _killer):
    respawn_timer = nd_game_round.get_respawn_time()


func _player_respawned(_player):
    return


func _process(delta):
    # Round timer
    nd_timer_label.set_text("ROUND: " + str(floor(nd_game_state.get_round_timer())))

    for p in nd_game_round.scorekeeper.keys():
        update_score(p, nd_game_round.scorekeeper[p])

    # Respawn timer
    if respawn_timer > 0:
        respawn_timer -= delta
        nd_respawn_label.set_text("Seconds until respawn: " + str(respawn_timer).pad_decimals(2))
#        nd_respawn_label.set_hidden(false)
        nd_respawn_label.visible = true
    else:
        nd_respawn_label.visible = false
#        nd_respawn_label.set_hidden(true)



func _ready():
    nd_game_round.connect("score_updated", self, "update_score")
    for player in nd_game_round.find_node("Players").get_children():
        player.connect("player_killed", self, "_player_killed")
        player.connect("player_respawned", self, "_player_respawned")

    # nd_names_label.set_text("")
    # nd_points_label.set_text("")
#    add_to_scoreboard(nd_game_state.player_name, 0)
    set_process(true)
