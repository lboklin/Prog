extends Node


const REWARD_TIMER = 1

var timer_round = 0
var timer_point_reward = 0
var scorekeeper = {}

signal score_updated()


func get_participants():
    return scorekeeper.keys()


func _add_points(name, points):
    if name == "all":
        for p in get_participants():
            scorekeeper[p] += points
            emit_signal("score_updated", p, scorekeeper[p])
    else:
        scorekeeper[name] = scorekeeper[name] + points if scorekeeper.has(name) else points
        emit_signal("score_updated", name, scorekeeper[name])
    # if is_network_master():
    #     get_tree().find_node(name).get_node("HUD/Points").set_text("Score: " + str(scorekeeper[name]))


func _process(delta):
    timer_round += delta

    # timer_point_reward += delta
    # if timer_point_reward > REWARD_TIMER:
    #     add_points("all", 1)
    #     timer_point_reward = 0


func _ready():
    for player in GameState.players.values():
        scorekeeper[player] = 0
        # Add 1 point per kill
        # GameState.nd_game_round.find_node(player).connect("player_killed", self, "_add_points", 1)
        # self.connect("add_points", self, "_add_points")
    print("Scorekeeper contains: " + str(scorekeeper.keys()))

    set_process(true)
