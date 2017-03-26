extends CanvasLayer

onready var nd_game_round = get_node("/root/GameRound")

#onready var nd_player = GameState.player_name
onready var nd_points_label = get_node("Control/Points")
onready var nd_name_label = get_node("Control/Name")


func _update_score(killer_name, score):
    nd_points_label.set_text("Score: " + str(score))


# func _process(delta):
#     # var name = nd_player.get_name()
#     var id = get_tree().get_network_unique_id()
#     var score = str(nd_game_round.score[id])
#     nd_points_label.set_text("Score: " + score)


func _ready():
    nd_game_round.connect("score_updated", self, "_update_score")
    nd_name_label.set_text(GameState.player_name)
    nd_points_label.set_text("Score: 0")
    set_process(true)
