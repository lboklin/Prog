extends CanvasLayer

onready var nd_game_round = get_node("/root/GameRound")

onready var nd_player = get_parent()
onready var nd_points_label = get_node("Points")
onready var nd_name_label = get_node("Name")


func _update_score(killer_name, points):
    nd_points_label.set_text("Score: " + str(points))


# func _process(delta):
#     # var name = nd_player.get_name()
#     var id = get_tree().get_network_unique_id()
#     var points = str(nd_game_round.points[id])
#     nd_points_label.set_text("Score: " + points)


func _ready():
    nd_game_round.connect("add_points", self, "_update_score")
    nd_name_label.set_text(nd_player.get_name())
    nd_points_label.set_text("Score: 0")
    set_process(true)
