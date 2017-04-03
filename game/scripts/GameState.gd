extends Node

# NETWORK DATA
# Port Tip: Check the web for available ports that is not preoccupied by other important services
# Port Tip #2: If you are the server; you may want to open it (NAT, Firewall)
const SERVER_PORT = 31041

# GAMEDATA
var players = {} # Dictionary containing player names and their ID
var player_name # Your own player name

# SIGNALS to Main Menu (GUI)
signal refresh_lobby()
signal server_ended()
signal server_error()
signal connection_success()
signal connection_fail()

# A game_round without identity.
# To be, or not to be.
var nd_game_round


# Join a server
func join_game(name, ip_address):
    # Store own player name
    player_name = name

    # Initializing the network as server
    var host = NetworkedMultiplayerENet.new()
    host.create_client(ip_address, SERVER_PORT)
    get_tree().set_network_peer(host)

# Host the server
func host_game(name):
    # Store own player name
    player_name = name

    # Initializing the network as client
    var host = NetworkedMultiplayerENet.new()
    host.create_server(SERVER_PORT, 6) # Max 6 players can be connected
    get_tree().set_network_peer(host)

    players[1] = name


func _ready():
    # Networking signals (high level networking)
    get_tree().connect("network_peer_connected", self, "_player_connected")
    get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
    get_tree().connect("connected_to_server", self, "_connected_ok")
    get_tree().connect("connection_failed", self, "_connected_fail")
    get_tree().connect("server_disconnected", self, "_server_disconnected")


# Client connected with you (can be both server or client)
func _player_connected(id):
    pass


# Client disconnected from you
func _player_disconnected(id):
    # If I am server, send a signal to inform that an player disconnected
    unregister_player(id)
    rpc("unregister_player", id)


# Successfully connected to server (client)
func _connected_ok():
    # Send signal to server that we are ready to be assigned;
    # Either to lobby or ingame
    rpc_id(1, "user_ready", get_tree().get_network_unique_id(), player_name)
    pass


# Server receives this from players that have just connected
remote func user_ready(id, player_name):
    # Only the server can run this!
    if(get_tree().is_network_server()):
        # If we are ingame, add player to session, else send to lobby
        if(has_node("/root/GameRound")):
            rpc_id(id, "register_in_game")
        else:
            rpc_id(id, "register_at_lobby")


# Register yourself directly ingame
remote func register_in_game():
    rpc("register_new_player", get_tree().get_network_unique_id(), player_name)
    register_new_player(get_tree().get_network_unique_id(), player_name)


# Register myself with other players at lobby
remote func register_at_lobby():
    rpc("register_player", get_tree().get_network_unique_id(), player_name)
    emit_signal("connection_success") # Sends command to gui & will send player to lobby


# Could not connect to server (client)
func _connected_fail():
    get_tree().set_network_peer(null)
    emit_signal("connection_fail")


# Server disconnected (client)
func _server_disconnected():
    quit_game()
    emit_signal("server_ended")


# Register the player and jump ingame
remote func register_new_player(id, name):
    # This runs only once from server
    if(get_tree().is_network_server()):
        # Send info about server to new player
        rpc_id(id, "register_new_player", 1, player_name)

        # Send the new player info about the other players
        for peer_id in players:
            rpc_id(id, "register_new_player", peer_id, players[peer_id])

    # Add new player to your player list
    rpc("players[id]", name)

    # Hardcoded spawns; could be done better by getting
    # the number of spawns from the map and go from there.
    # At this stage, hardcoding will suffice...
    randomize() # If you dont add this line, rnd_spawn will always get the same number.
    var rnd_spawn = int(rand_range(1,7)) # 1-6

    var spawn_pos = {} # Dictionary
    spawn_pos[id] = rnd_spawn # Insert random spawn

    # Spawn player with id 'id' and at position 'spawn_pos[id]'
    print("Spawning " + str(name))
    spawn_players(spawn_pos)


# Register player the ol' fashioned way and refresh lobby
remote func register_player(id, name):
    # If I am the server (not run on clients)
    if(get_tree().is_network_server()):
        rpc_id(id, "register_player", 1, player_name) # Send info about server to new player

        # For each player, send the new guy info of all players (from server)
        for peer_id in players:
            rpc_id(id, "register_player", peer_id, players[peer_id]) # Send the new player info about others
            rpc_id(peer_id, "register_player", id, name) # Send others info about the new player

    # players[id] = name # update player list

    # Notify lobby (GUI) about changes
    emit_signal("refresh_lobby")


# Unregister a player, whether he is in lobby or ingame
remote func unregister_player(id):
    # If the game is running
    if(has_node("/root/GameRound")):
        # Remove player from game
        var nd_p = nd_game_round.find_node("Players")
        if(nd_p.has_node(str(id))):
            nd_p.get_node(str(id)).queue_free()
        players.erase(id)
    else:
        # Remove from lobby
        players.erase(id)
        emit_signal("refresh_lobby")


# Returns a list of players (lobby)
func get_participants():
    return nd_game_round.get_participants()


# Returns a list of players (lobby)
func get_player_list():
    return players.values()


# Returns your name
func get_player_name():
    return player_name


# Quits the game, will automatically tell the server you disconnected; neat.
func quit_game():
    get_tree().set_network_peer(null)
    players.clear()


func start_game():

    # Set spawn pos for each player
    var spawn_points = {}

    # Generate spawn points associated with each player
    spawn_points[1] = 1 # Set first spawn point to server

    # Add spawn point in spawn_points dictionary for each player
    for p in players:
        var spawn_loc = rand_loc(Vector2(0,0), 0, 2000)
        print(str(p) + ", spawn at " + str(spawn_loc))
        spawn_points[p] = spawn_loc

    # Tell each player 'p' with id 'spawn_points' to spawn at specified 'spawn_points[id]'
    for p in players:
        if players[p] != player_name:
            rpc_id(p, "spawn_players", spawn_points)

    spawn_players(spawn_points)
    pass


func rand_loc(location, radius_min, radius_max):    ## PURE (almost? what does rand_range() really do?)
    var new_radius = rand_range(radius_min, radius_max)
    var angle = deg2rad(rand_range(0, 360))
    var point_on_circ = Vector2(new_radius, 0).rotated(angle)
    return location + point_on_circ


func get_round_timer():
    return nd_game_round.timer_round


# Display an indicator for where you clicked
func spawn_click_indicator(pos, anim):
    var indicator = preload("res://gui/Indicator.tscn").instance()
    indicator.set_pos(pos)
    nd_game_round.find_node("Players").add_child(indicator)
    indicator.get_node("AnimationPlayer").play(anim)


# Spawn an NPC to play with
sync func spawn_enemy(loc):
    var enemy = preload("res://npc/Bot.tscn").instance()
    enemy.set_pos(loc)
    nd_game_round.find_node("Players").add_child(enemy)


remote func spawn_players(spawn_points):
    # If your game have already started, we get the current reference,
    # else we create our instance and add it to root
    if(has_node("/root/GameRound")):
        nd_game_round = get_node("/root/GameRound")
    else:
        nd_game_round = load("res://scenes/GameRound.tscn").instance()
        get_tree().get_root().add_child(nd_game_round)
        get_tree().get_root().get_node("MainMenu").hide()

    # Create Scenes to instance (further down)
    var scn_player = load("res://player/Player.tscn")
    var scn_camera = load("res://player/PlayerCam.tscn")

    # Spawn! Spawn ALL the players!
    # There are only multiple players when we wait for players in lobby before starting.
    # Else we generate a random spawn point and throw him in with the other players.
    for p in spawn_points:
        # Create nd_player instance
        var nd_player = scn_player.instance()

        # Set Nd_Player ID as node name - Unique for each nd_player!
        nd_player.set_name("Player" + str(p))

        # Set random spawn position for the nd_player
        var spawn_pos = rand_loc(Vector2(0,0), 0, 2000)
        nd_player.set_pos(spawn_pos)
        # nd_player.connect("player_killed", nd_game_round, "_add_points", [1])


        # If the new nd_player is you
        if (p == get_tree().get_network_unique_id()):
            nd_player.set_name(player_name)
            # Set as master on yourself
            nd_player.set_network_mode( NETWORK_MODE_MASTER )
            # Add camera to your nd_player
            nd_player.add_child(scn_camera.instance())
            # Add a HUD for displaying name and score
            var nd_hud = load("res://gui/HUD.tscn").instance()
            nd_hud.get_node("Control/Name").set_text(nd_player.get_name())
            nd_hud.get_node("Control/Points").set_text("Score: 0")
            nd_game_round.add_child(nd_hud)
        else:
            nd_player.set_network_mode( NETWORK_MODE_SLAVE )
            # Add nd_player name
            # nd_player.get_node("HUD/Name").set_text(str(players[p]))

        # Add the nd_player (or you) to the nd_game_round!
        nd_game_round.find_node("Players").add_child(nd_player)
        var name = nd_player.get_name()
        nd_game_round.scorekeeper[name] = 0
        # Award points for kills
        nd_player.connect("player_killed", nd_game_round, "_add_points", [1])