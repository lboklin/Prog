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
var nd_game_round


sync func set_players(players: Dictionary):
    p_players = players
    return


func get_players() -> Dictionary:
    return p_players


func get_player_node(id: int) -> Node:
    var node_name = get_players()[id]
    var node = get_node("/root/GameRound/Players/" + node_name)
    return node


sync func add_player(id: int, player_name: String) -> Dictionary:
    # If there's already a player with that name, append it with its ID
#    nd_name = name_to_node_name(nd_name, id)
    while get_players().values().has(player_name):
        player_name += String(id).left(2)
    rset("my_name", player_name)
    p_players[id] = player_name
    return p_players


func remove_player(id: int) -> void:
    p_players.erase(id)
    return


# Join a server
func join_game(name, ip_address):
    # Store own player name
    my_name = name

    # Initializing the network as server
    var host = NetworkedMultiplayerENet.new()
    host.create_client(ip_address, SERVER_PORT)
    get_tree().network_peer = host

# Host the server
func host_game(host_player_name):
    # Store own player name
    my_name = host_player_name

    # Initializing the network as client
    var host = NetworkedMultiplayerENet.new()
    var err = host.create_server(SERVER_PORT, 6) # Max 6 players can be connected
    if err != OK:
        emit_signal("server_error", err)
    get_tree().network_peer = host

    add_player(1, host_player_name)


# Client connected with you (can be both server or client)
func _player_connected(id):
    print("Player ", id, " connected")
    pass


# Client disconnected from you
func _player_disconnected(id):
    # If I am server, send a signal to inform that an player disconnected
    unregister_player(id)
    rpc("unregister_player", id)


# Successfully connected to server (client)
func _connected_ok():
    rpc_id(1, "register_new_player", get_tree().get_network_unique_id(), my_name)
    pass


# Could not connect to server (client)
func _connected_fail():
    get_tree().network_peer = null
    emit_signal("connection_fail")


# Server disconnected (client)
func _server_disconnected():
    print("Server disconnected")
    emit_signal("server_ended")
    quit_game()


# Register a player who just connected to the lobby
remote func register_new_player(new_id, new_name):
    # If I am the server (not run on clients)
    if(get_tree().is_network_server()):
        var players = add_player(new_id, new_name) # update player list
        rpc("set_players", players)

        rpc_id(new_id, "register_new_player", 1, my_name) # Send info about server to new player

        # For each player, send the new guy info of all players (from server)
        for peer_id in players:
            rpc_id(new_id, "register_new_player", peer_id, players[peer_id]) # Send info about others to new player
            rpc_id(peer_id, "register_new_player", new_id, new_name) # Send info about the new player to the others

    # If we are in lobby
    if not has_node("/root/GameRound"):
        emit_signal("connection_success") # Sends command to gui & will send player to lobby
        # Notify lobby (GUI) about changes
        emit_signal("refresh_lobby")


# Unregister a player, whether he is in lobby or ingame
remote func unregister_player(id):
    # If the game is running
    if(has_node("/root/GameRound")):
        var node_name = get_players()[id] + str(id)
        # Remove player from game
        var nd_players = nd_game_round.find_node("Players")
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
        var nd_player = nd_game_round.find_node("Players").get_node(my_name)
        nd_player.emit_signal("player_killed", get_tree().get_network_unique_id(), 0)
        nd_game_round.queue_free()
#        yield(nd_game_round, "exit_tree")
    get_tree().set_network_peer(null)
    get_tree().quit()


func start_game():
    rpc("spawn_players")
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
    return nd_game_round.timer_round


# Display an indicator for where you clicked
func spawn_click_indicator(pos, anim):
    var indicator = preload("res://gui/Indicator.tscn").instance()
    indicator.position = pos
    nd_game_round.find_node("Players").add_child(indicator)
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

    nd_game_round.find_node("Players").add_child(enemy)
    nd_game_round.add_to_keepers(id, name)


remotesync func spawn_players():
    if(has_node("/root/GameRound")):
        nd_game_round = get_node("/root/GameRound")
    else:
        nd_game_round = (load("res://scenes/GameRound.tscn") as PackedScene).instance()
        get_tree().get_root().add_child(nd_game_round)
        get_tree().get_root().get_node("MainMenu").queue_free()

    # Create Scenes to instance (further down)
    var scn_player = load("res://player/Player.tscn")
    var scn_camera = load("res://player/PlayerCam.tscn")

    # Add player nodes
    var players = get_players()
    for id in players.keys():
        # Create nd_player instance
        var nd_player = scn_player.instance()

        var player_name: String = players[id]
        var node_name = player_name #if name == "Server" else name + str(id)
#        var node_name = name + str(id)
        nd_player.name = node_name

        # Spawn at origin
        var spawn_pos = Vector2(0,0)
        nd_player.position = spawn_pos

        # If the new nd_player is you
        if (id == get_tree().get_network_unique_id()):
            # Set as master on yourself
            nd_player.set_network_master( 0 )
            # Add camera to your nd_player
            nd_player.add_child(scn_camera.instance())
            # Add a HUD for displaying name and score
            var nd_hud = (load("res://gui/HUD.tscn") as PackedScene).instance()
            nd_game_round.add_child(nd_hud)
#        else:
#            nd_player.set_network_mode( RPC_MODE_SLAVE )

        get_node("/root/GameRound/Players").add_child(nd_player)
        nd_game_round.add_to_keepers(id)

#    # Once everyone is added, add them to keepers
#    for id in players.keys():


func _ready():
    # Networking signals (high level networking)
    get_tree().connect("network_peer_connected", self, "_player_connected")
    get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
    get_tree().connect("connected_to_server", self, "_connected_ok")
    get_tree().connect("connection_failed", self, "_connected_fail")
    get_tree().connect("server_disconnected", self, "_server_disconnected")