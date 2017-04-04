extends Node


const REWARD_TIMER = 1

# onready var nd_hud = get_node("HUD")
var timer_round = 0
var timer_point_reward = 0
var scorekeeper = {}

signal score_updated()


func add_participant(ppt):
    scorekeeper[ppt] = 0
    get_node("HUD").add_to_scoreboard(ppt, 0)

    # Award points to the killer upon the death of their target
    var p = get_node("BackgroundTiles/Players/" + ppt)
    p.connect("player_killed", self, "_add_points")
    return


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
    print("Scores: ")
    for p in scorekeeper:
        print(p, " has ", scorekeeper[p], " points.")


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
