extends Node
class_name GameState

# NETWORK DATA
# Port Tip: Check the web for available ports that is not preoccupied by other important services
# Port Tip #2: If you are the server; you may want to open it (NAT, Firewall)
const SERVER_PORT = 31041

# GAMEDATA
var p_players = {} setget set_players, get_players # Dictionary with player_id => player_name
remotesync var my_name # Your own player name
#var my_id # Your own player id

# SIGNALS to Main Menu (GUI)
signal refresh_lobby()
signal server_ended()
signal server_error()
signal connection_success()
signal connection_fail()

# A game_round without identity.
# To be, or not to be.
var game_round


sync func set_players(players: Dictionary) -> void:
    p_players = players
    return


func get_players() -> Dictionary:
    return p_players


sync func add_player(id: int, player_name: String) -> Dictionary:
    # If there's already a player with that name, append it with its ID
#    nd_name = name_to_node_name(nd_name, id)
    while get_players().values().has(player_name):
        player_name += String(id).left(2)
    rset("my_name", player_name)
    p_players[id] = player_name
    return p_players


func remove_player(id: int) -> Dictionary:
    p_players.erase(id)
    return p_players


# Join a server
func join_game(player_name: String, ip_address: String):
    # Store own player name
    my_name = player_name

    # Initializing the network as server
    var host := NetworkedMultiplayerENet.new()
    host.create_client(ip_address, SERVER_PORT)
    get_tree().network_peer = host

# Host the server
func host_game(host_player_name: String) -> void:
    # Store own player name
    my_name = host_player_name

    # Initializing the network as client
    var host := NetworkedMultiplayerENet.new()
    var err: int = host.create_server(SERVER_PORT, 6) # Max 6 players can be connected
    if err != OK:
        emit_signal("server_error", err)
    get_tree().network_peer = (host as NetworkedMultiplayerPeer)

    add_player(1, host_player_name)


# Client connected with you (can be both server or client)
func _player_connected(id):
    print("Player ", id, " connected")
    return


# Client disconnected from you
func _player_disconnected(id):
    # If I am server, send a signal to inform that an player disconnected
    unregister_player(id)
    rpc("unregister_player", id)


# Successfully connected to server (client)
func _connected_ok() -> void:
    rpc_id(1, "register_new_player", get_tree().get_network_unique_id(), my_name)
    return


# Could not connect to server (client)
func _connected_fail() -> void:
    get_tree().network_peer = null
    emit_signal("connection_fail")


# Server disconnected (client)
func _server_disconnected() -> void:
    print("Server disconnected")
    emit_signal("server_ended")
    quit_game()
    return


# Register a player who just connected to the lobby
remote func register_new_player(new_id: int, new_name: String):
    # If I am the server (not run on clients)
    if(get_tree().is_network_server()):
        var players: Dictionary = add_player(new_id, new_name) # update player list
        rpc("set_players", players)

        rpc_id(new_id, "register_new_player", 1, my_name) # Send info about server to new player

        # For each player, send the new guy info of all players (from server)
        for peer_id in players.keys():
            # Send info about others to new player
            rpc_id(new_id, "register_new_player", peer_id, players[peer_id])
            # Send info about the new player to the others
            rpc_id(peer_id, "register_new_player", new_id, new_name)

    # If we are in lobby
    if not has_node("/root/GameRound"):
        # Sends command to gui & will send player to lobby
        emit_signal("connection_success")
        # Notify lobby (GUI) about changes
        emit_signal("refresh_lobby")


# Unregister a player, whether he is in lobby or ingame
remote func unregister_player(id):
    # If the game is running
    if(has_node("/root/GameRound")):
        var node_name: String = get_players()[id] + str(id)
        # Remove player from game
        var nd_players: Node = game_round.find_node("Players")
        if nd_players.has_node(node_name):
            nd_players.get_node(node_name).queue_free()
        remove_player(id)
    else:
        # Remove from lobby
        remove_player(id)
        emit_signal("refresh_lobby")


# Quits the game, will automatically tell the server you disconnected; neat.
func quit_game():
    if has_node("/root/GameRound"):
        var prog = game_round.find_node("Players").get_node(my_name)
        prog.emit_signal("player_killed", get_tree().get_network_unique_id(), 0)
        game_round.queue_free()
#        yield(game_round, "exit_tree")
    get_tree().set_network_peer(null)
    get_tree().quit()


func start_game():
    # Swap scenes from MainMenu to GameRound
    var root = get_tree().get_root()
    if(root.has_node("GameRound")):
        game_round = root.get_node("GameRound")
    else:
        game_round = (load("res://scenes/GameRound.tscn") as PackedScene).instance()
        game_round.game_state_path = self.get_path()
        swap_scenes(root.get_node("MainMenu"), game_round, root)

#    rpc("spawn_players")
    spawn_players()
    return


# Get a random location inside a cut-out circle defined
# by a min and max of a radius from the given origin.
static func rand_loc(location, radius_min, radius_max):
    randomize() # generate new random seed or we might get the same result as previous time
    var new_radius = rand_range(radius_min, radius_max)
    var angle = deg2rad(rand_range(0, 360))
    var point_on_circ = Vector2(new_radius, 0).rotated(angle)
    return location + point_on_circ


func get_round_timer():
    return game_round.timer_round


# Display an indicator for where you clicked
static func spawn_click_indicator(parent: Node, pos: Vector2, anim: String):
    var indicator = preload("res://gui/Indicator.tscn").instance()
    indicator.position = pos
    parent.add_child(indicator)
    indicator.get_node("AnimationPlayer").play(anim)


# Spawn an NPC to play with
sync func spawn_enemy(loc):
    var enemy = preload("res://npc/Bot.tscn").instance()
    enemy.position = (loc)

    var id = int(rand_range(0,9))
    while get_players().has(id):
        id *= int(rand_range(0,9))
        randomize()

    var name = "Bot"
    name = add_player(id, name)[id]
    enemy.set_name(name)

    game_round.find_node("Players").add_child(enemy)
    game_round.add_to_keepers(id, name)


static func swap_scenes(old: Node, new: Node, parent: Node) -> void:
    parent.add_child(new)
    old.queue_free()


func spawn_players():
    pass

#    # Once everyone is added, add them to keepers
#    for id in players.keys():


func _ready():
    # Networking signals (high level networking)
    get_tree().connect("network_peer_connected", self, "_player_connected")
    get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
    get_tree().connect("connected_to_server", self, "_connected_ok")
    get_tree().connect("connection_failed", self, "_connected_fail")
    get_tree().connect("server_disconnected", self, "_server_disconnected")

func _input(ev: InputEvent) -> void:
#    if ev.is_action_pressed("spawn_enemy"):
#        var bot_id =
#        GameState.rpc("spawn_enemy", GameState.rand_loc(prog.mouse_pos, 0, 600))
    if ev.is_action_pressed("quit_game"):
        quit_game()
