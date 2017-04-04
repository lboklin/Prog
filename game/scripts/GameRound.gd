extends Node


const REWARD_TIMER = 1

var timer_round = 0
var timer_point_reward = 0
var scorekeeper = {}

signal score_updated()


func add_participant(ppt):
    scorekeeper[ppt] = 0
    get_node("HUD").add_to_scoreboard(ppt, 0)
    print("Scorekeeper contains: " + str(scorekeeper.keys()))

    # Award points to the killer upon the death of their target
    var p = get_node("BackgroundTiles/Players/" + ppt)
    p.connect("player_killed", self, "_player_killed")
    return


func get_participants():
    return scorekeeper.keys()


func _player_killed(player, killer):
    rpc("add_points", killer, 1)
    if player == GameState.player_name:
        var nd_player = get_node("BackgroundTiles/Players/" + player)
        get_node("HUD").respawn_timer = nd_player.get_state()["timers"]["dead"]


sync func add_points(name, points):
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
    #     rpc("add_points", "all", 1)
    #     timer_point_reward = 0


func _ready():
    for player in GameState.players.values():
        call_deferred("add_participant", player)
        # Add 1 point per kill
        # GameState.nd_game_round.find_node(player).connect("player_killed", self, "add_points", 1)
        # self.connect("add_points", self, "add_points")

    set_process(true)
