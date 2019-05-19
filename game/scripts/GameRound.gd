extends Node
class_name GameRound


# const REWARD_TIMER = 1
const RESPAWNS_PER_ERT := 3  # Respawn timer to elapsed round time ratio

export(NodePath) var game_state_path
onready var game_state := get_node(game_state_path) as GameState

var timer_round: float = 0
#var timer_point_reward = 0
var scorekeeper := {} # Dict of player id => player_score (int)
var statuskeeper := {} # Dict of player id => Status

enum Status { ALIVE, DEAD }

signal score_updated()


func get_respawn_time() -> float:
    var time: float = timer_round / RESPAWNS_PER_ERT
    time = clamp(time, 5, 60)
    return time


func get_player_node(id: int) -> Node:
    var node_name: String = game_state.get_players()[id]
    return get_node("Players/" + node_name)


# TODO: Make sure there aren't any duplicate names
func add_to_keepers(id: int) -> void:
    var prog: Prog = get_player_node(id) as Prog
    var nd_name = prog.name
    print("Adding ", nd_name)
#    print("Player nodes: ")
#    for p in game_state.get_players().keys():
#        var node = game_state.get_player_node(p)
#        print(node.name,"\n")

    # Award points to the killer upon the death of their target
    if not prog.is_connected("player_killed", self, "_player_killed"):
        prog.connect("player_killed", self, "_player_killed")
    if not prog.is_connected("player_respawned", self, "_player_respawned"):
        prog.connect("player_respawned", self, "_player_respawned")

    var display_name: String = nd_name.replace("@", "").replace(id, "")
    statuskeeper[display_name] = Status.ALIVE
    scorekeeper[display_name] = 0
#    prog.hud.add_to_scoreboard(display_name, 0)
    return


func _player_respawned(player: Player) -> void:
    statuskeeper[player] = Status.ALIVE
    return


func _player_killed(player: int, killer: int) -> void:
    statuskeeper[player] = Status.DEAD
    self.add_points(killer, 1)
    return


# Assigns player (ID) additional points. If player is 0, nobody gets points,
# if player is -1 all players are given the points.
sync func add_points(player: int, points: int):
    if player == -1: # Give everyone points
        for p in scorekeeper.keys():
            if statuskeeper[p] == Status.ALIVE:
                scorekeeper[p] += points
    else:
        scorekeeper[name] = scorekeeper[name] + points if scorekeeper.has(name) else points
        emit_signal("score_updated", name, scorekeeper[name])


func _process(delta):
    timer_round += delta

    rpc("add_points", -1, delta)

    # timer_point_reward += delta
    # if timer_point_reward > REWARD_TIMER:
    #     rpc("add_points", "all", 1)
    #     timer_point_reward = 0


func spawn_players() -> void:
    # Create Scenes to instance (further down)
    var prog_scn := preload("res://scenes/Prog.tscn") as PackedScene

    # Add player nodes
    var players: Dictionary = game_state.get_players()
    for id in players.keys():
        # Create prog instance
        var prog = prog_scn.instance()

        var player_name: String = players[id]
        var node_name := player_name #if name == "Server" else name + str(id)
#        var node_name = name + str(id)
        prog.name = node_name

        # Spawn at origin
        var spawn_pos := Vector2(0,0)
        prog.position = spawn_pos

        $Players.add_child(prog)

        # If the new prog is you
        if (id == get_tree().get_network_unique_id()):
            var player: Player = (load("res://scripts/Player.gd") as GDScript).new()
            player.prog_path = prog.get_path()
            prog.add_child(player)

        prog.set_network_master(id)
        add_to_keepers(id)


func _ready():
    spawn_players()

    for player in game_state.get_players().values():
        call_deferred("add_to_keepers", player)

    set_process(true)
