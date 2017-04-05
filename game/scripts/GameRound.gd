extends Node


# const REWARD_TIMER = 1
const RESPAWNS_PER_ERT = 3  # Respawn timer to elapsed round time ratio

var timer_round = 0
var timer_point_reward = 0
var scorekeeper = {}
var statuskeeper = {}

enum Status { ALIVE, DEAD }

signal score_updated()


func get_participants():
    return scorekeeper.keys()


func get_respawn_time():
    var time = timer_round / RESPAWNS_PER_ERT
    time = clamp(time, 5, 60)
    return time


func add_to_keepers(id, name):
    var nd_players = find_node("Players")
    # var node_name = name if name == "Server" else name + str(id)
    var node_name = name
    var nd_participant = nd_players.get_node(node_name)
    print("Adding ", node_name)
    print("Player nodes: ")
    for node in nd_players.get_children():
        print(node.get_name())

    # Award points to the killer upon the death of their target
    nd_participant.connect("player_killed", self, "_player_killed")
    nd_participant.connect("player_respawned", self, "_player_respawned")

    var display_name = node_name.replace("@", "")
    statuskeeper[display_name] = Status.ALIVE
    scorekeeper[display_name] = 0
    get_node("HUD").add_to_scoreboard(display_name, 0)
    return


func _player_respawned(player):
    statuskeeper[player] = Status.ALIVE
    return


func _player_killed(player, killer, respawn_time):
    statuskeeper[player] = Status.DEAD
    return


sync func add_points(name, points):
    if name == "all":
        for p in get_participants():
            if statuskeeper[p] == Status.ALIVE:
                scorekeeper[p] += points
    else:
        scorekeeper[name] = scorekeeper[name] + points if scorekeeper.has(name) else points
        emit_signal("score_updated", name, scorekeeper[name])


func _process(delta):
    timer_round += delta

    rpc("add_points", "all", delta)

    # timer_point_reward += delta
    # if timer_point_reward > REWARD_TIMER:
    #     rpc("add_points", "all", 1)
    #     timer_point_reward = 0


func _ready():
    for player in GameState.get_players().values():
        call_deferred("add_to_keepers", player)

    set_process(true)
