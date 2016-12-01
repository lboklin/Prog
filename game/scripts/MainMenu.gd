extends Node

# CONTAINERS
onready var menu_container = get_node("MenuContainer")
onready var join_container = get_node("JoinContainer")
onready var host_container = get_node("HostContainer")
onready var lobby_container = get_node("LobbyContainer")

onready var blue_light = get_node("MenuContainer/Background/BlueLight")
onready var red_light = get_node("MenuContainer/Background/RedLight")

onready var window_size = get_viewport().get_visible_rect().size
# Player Name
const PLAYER_NAME_DEFAULT = "Player"
const SERVER_NAME_DEFAULT = "Server"

var light_pos = Vector2(0,0)
var light_speed = 200

# MAIN MENU - Join Game
# Opens up the 'Connect to Server' window
func _on_join_game_button_pressed():
	menu_container.hide()
	join_container.show()


# MAIN MENU - Host Game
# Opens up the 'Choose a nickname' window
func _on_host_game_button_pressed():
	menu_container.hide()
	host_container.show()


# MAIN MENU - Quit Game
func _on_quit_game_button_pressed():
	get_tree().quit()


# JOIN CONTAINER - Connect
# Attempts to connect to the server
# If successful, continue to Lobby or jump in-game (if running)
func _on_connect_button_pressed():
	# Check entered IP address for errors
	var ip_address = join_container.find_node("LineEditIPAddress").get_text()
	if(!ip_address.is_valid_ip_address()):
		join_container.find_node("LabelError").set_text("Invalid IP address")
		return

	# Check nickname for errors
	var player_name = join_container.find_node("LineEditNickname").get_text()
	if(player_name == ""):
		join_container.find_node("LabelError").set_text("Nickname cannot be empty")
		return

	# Clear error (if any)
	join_container.find_node("LabelError").set_text("")

	# Connect to server
	GameState.join_game(player_name, ip_address)

	# While we are attempting to connect, disable button for 'continue'
	join_container.find_node("ConnectButton").set_disabled(true)


# HOST CONTAINER - Continue (from choosing a nickname)
# Opens the server for connectivity from clients
func _on_continue_button_pressed():
	# Check if nickname is valid
	var player_name = host_container.find_node("LineEditNickname").get_text()
	if(player_name == ""):
		host_container.find_node("LabelError").set_text("Nickname cannot be empty")
		return

	# Clear error (if any)
	host_container.find_node("LabelError").set_text("")

	# Establish network
	GameState.host_game(player_name)

	# Refresh Player List (with your own name)
	refresh_lobby()

	# Toggle to Lobby
	host_container.hide()
	lobby_container.show()
	lobby_container.find_node("StartGameButton").set_disabled(false)


# LOBBY CONTAINER - Starts the Game
func _on_start_game_button_pressed():
	GameState.start_game()


# LOBBY CONTAINER - Cancel Lobby
# (The only time you are already connected from main menu)
func _on_cancel_lobby_button_pressed():
	# Toggle containers
	lobby_container.hide()
	menu_container.show()

	# Disconnect networking
	GameState.quit_game()

	# Enable buttons
	join_container.find_node("ConnectButton").set_disabled(false)


# ALL - Cancel (from any container)
func _on_cancel_button_pressed():
	menu_container.show()
	join_container.hide()
	join_container.find_node("LabelError").set_text("")
	host_container.hide()
	host_container.find_node("LabelError").set_text("")

# Refresh Lobby's player list
# This is run after we have gotten updates from the server regarding new players
func refresh_lobby():
	# Get the latest list of players from gamestate
	var player_list = GameState.get_player_list()
	player_list.sort()

	# Add the updated player_list to the itemlist
	var itemlist = lobby_container.find_node("ItemListPlayers")
	itemlist.clear()
	itemlist.add_item(GameState.get_player_name() + " (YOU)") # Add yourself to the top

	# Add every other player to the list
	for player in player_list:
		itemlist.add_item(player)

	# If you are not the server, we disable the 'start game' button
	if(!get_tree().is_network_server()):
		lobby_container.find_node("StartGameButton").set_disabled(true)


# Handles what to happen after server ends
func _on_server_ended():
	lobby_container.hide()
	join_container.hide()
	join_container.find_node("ConnectButton").set_disabled(false)
	menu_container.show()

	# If we are ingame, remove world from existence!
	if(has_node("/root/World")):
		get_node("/root/MainMenu").show() # Enable main menu
		get_node("/root/World").queue_free() # Terminate world


func _on_server_error():
	print("_ON_SERVER_ERROR: Unknown error")


func _on_connection_success():
	join_container.hide()
	lobby_container.show()


func _on_connection_fail():
	# Display error telling the user that the server cannot be connected
	join_container.find_node("LabelError").set_text("Cannot connect to server, try again or use another IP address")

	# Enable continue button again
	join_container.find_node("ConnectButton").set_disabled(false)


func _on_viewport_size_changed():

	window_size = get_viewport().get_visible_rect().size
	menu_container.set_size(window_size)


func _process(delta):

	var margin = 200

	light_pos.x += delta * light_speed
	light_pos.y = -10
	if light_pos.x > window_size.x + margin:
		light_pos.x = -margin
	blue_light.set_pos(light_pos)

	var red_light_pos = Vector2()
	red_light_pos.x = -light_pos.x + window_size.x
	red_light_pos.y = window_size.y + 20
	red_light.set_pos(red_light_pos)


func _ready():
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	# Set default nicknames on host/join
	join_container.find_node("LineEditNickname").set_text(PLAYER_NAME_DEFAULT)
	host_container.find_node("LineEditNickname").set_text(SERVER_NAME_DEFAULT)

	# Setup Network Signaling between Gamestate and Game UI
	GameState.connect("refresh_lobby", self, "refresh_lobby")
	GameState.connect("server_ended", self, "_on_server_ended")
	GameState.connect("server_error", self, "_on_server_error")
	GameState.connect("connection_success", self, "_on_connection_success")
	GameState.connect("connection_fail", self, "_on_connection_fail")

	set_process(true)