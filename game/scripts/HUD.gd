extends CanvasLayer

onready var nd_game_round = get_node("/root/GameRound")
#onready var nd_player = GameState.player_name
onready var nd_points_label = get_node("Control/Points")
onready var nd_name_label = get_node("Control/Name")
onready var nd_timer_label = get_node("Control/RoundTimer")
onready var nd_respawn_label = get_node("Control/RespawnTimer")

var respawn_timer = 0


func _update_score(killer_name, score):
    nd_points_label.set_text("Score: " + str(score))


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
    nd_name_label.set_text(GameState.player_name)
    nd_points_label.set_text("Score: 0")
    set_process(true)
