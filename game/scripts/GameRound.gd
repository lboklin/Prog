extends Node


# const REWARD_TIMER = 1
const RESPAWNS_PER_ERT = 3  # Respawn timer to elapsed round time ratio

var timer_round = 0
var timer_point_reward = 0
var scorekeeper = {}
var statuskeeper = {}
# var nd_participants = {}

enum Status { ALIVE, DEAD }

signal score_updated()


func add_participant(participant):
    var p = get_node("BackgroundTiles/Players/" + participant)
    # nd_participants[participant] = p
    # Award points to the killer upon the death of their target
    p.connect("player_killed", self, "_player_killed")
    p.connect("player_respawned", self, "_player_respawned")

    participant = participant.replace("@", "")
    statuskeeper[participant] = Status.ALIVE
    scorekeeper[participant] = 0
    get_node("HUD").add_to_scoreboard(participant, 0)
    return


func get_participants():
    return scorekeeper.keys()


func get_respawn_time():
    var time = GameState.get_round_timer() / RESPAWNS_PER_ERT
    time = clamp(time, 5, 60)
    return time


func _player_respawned(player):
    statuskeeper[player] = Status.ALIVE
    return


func _player_killed(player, killer):
    statuskeeper[player] = Status.DEAD
    if player == GameState.player_name:
        var nd_player = get_node("BackgroundTiles/Players/" + player)
        get_node("HUD").respawn_timer = nd_player.get_state()["timers"]["dead"]
    return
    # rpc("add_points", killer, 1)


sync func add_points(name, points):
    if name == "all":
        for p in get_participants():
            if statuskeeper[p] == Status.ALIVE:
                scorekeeper[p] += points
                # emit_signal("score_updated", p, scorekeeper[p])
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
    for player in GameState.players.values():
        call_deferred("add_participant", player)
        # Add 1 point per kill
        # GameState.nd_game_round.find_node(player).connect("player_killed", self, "add_points", 1)
        # self.connect("add_points", self, "add_points")

    set_process(true)
