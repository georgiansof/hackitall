extends Node3D

enum State {CHOOSING_NAME = 0, CHOOSING_ROLE = 1, CREATE_SERVER = 2, JOIN_SERVER = 3, WAITING_FOR_PLAYERS = 4, PLAYING = 5}
enum Authority {SERVER, CLIENT, UNASSIGNED}

var players = []

@export var SERVER_BROADCAST_PORT : int = 25570
@export var SERVER_BROADCAST_INTERVAL : float = 3.0

@export var PORT : int = 25569
@export var MAX_CLIENTS : int = 8

var scene = preload("res://world.tscn")
var player = preload("res://assets/player/Player.tscn")

var username : String = ""

var state : State = State.CHOOSING_NAME
var authority : Authority = Authority.UNASSIGNED

var peer : ENetMultiplayerPeer
var udp : PacketPeerUDP

@onready var UI = [$UI_ChooseName, $UI_ChooseServerOrClient, $UI_WaitForPlayers]

func _ready():
	self.add_child(scene.instantiate())
	for ui_elem in UI:
		ui_elem.visible = true
	pass
		

var broadcast_timer = SERVER_BROADCAST_INTERVAL

func _process(delta):
	if authority == Authority.SERVER and state == State.CREATE_SERVER: 
		broadcast_timer += delta
		if broadcast_timer > SERVER_BROADCAST_INTERVAL:
			broadcast_timer -= SERVER_BROADCAST_INTERVAL
			broadcast_to_clients()
	elif authority == Authority.CLIENT and state == State.JOIN_SERVER:
		while udp.get_available_packet_count() > 0:
			var packet = udp.get_packet()
			var message = packet.get_string_from_utf8()
			var sender_ip = udp.get_packet_ip()
			var sender_port = udp.get_packet_port()
			var sender_username = message.substr(17)
			if message.begins_with("SERVER_DISCOVERY"):
				print_debug("Found server " + sender_username + " at " + sender_ip + ":" + str(sender_port))
				var grid = $UI_DiscoverServers.get_node("GridContainer")
			
				if server_already_listed(grid, sender_username):
					continue
						
				var label = Label.new()
				label.text = sender_username
				
				var button = ConnectButton.new(sender_ip, sender_port)
				button.text = "Connect"
				
				grid.add_child(label)
				grid.add_child(button)
	pass

func server_already_listed(grid, server_name) -> bool :
	for child in grid.get_children():
		if child is Label and child.text == server_name:
			return true
	return false

func broadcast_to_clients():
	print_debug("Broadcasting...")
	var data = ("SERVER_DISCOVERY:" + username).to_utf8_buffer()
	
	udp = PacketPeerUDP.new()
	udp.set_broadcast_enabled(true)
	udp.set_dest_address("255.255.255.255", 12346)	
	udp.put_packet(data)
	pass

	

func create_server():
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	
	
func wait_server_broadcasts():
	print_debug("Listening...")
	udp = PacketPeerUDP.new()
	udp.set_broadcast_enabled(true)
	udp.bind(12346, "0.0.0.0")

func connect_to_server(ip: String, port: int):
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(on_client_connected)
	multiplayer.connection_failed.connect(on_client_connection_failed)
	
func on_client_connected():
	print_debug("Connected successfully to server !")
	$UI_DiscoverServers.visible = false
	state = State.WAITING_FOR_PLAYERS
	$UI_WaitForPlayersClient.visible = true
	notify_server_client_connected(username)
	udp.close()
	
	
func on_client_connection_failed():
	print_debug("Connection failure !")
	var errorLabel = $UI_DiscoverServers.get_node("ErrorLabel")
	errorLabel.text = "Unable to connect to server."
	errorLabel.visible = true

# Function called when the client joins the server
func notify_server_client_connected(username: String):
	if authority == Authority.CLIENT:
		rpc("add_user", username)  # Call server's RPC to add username
	pass

# RPC function to add a new user to the server
@rpc("any_peer")
func add_user(username: String):
	if username not in players:
		players.append(username)
		print("Added username: " + username)
		render_playerlist()
		sync_usernames()  # Sync updated list with all clients

# RPC function to sync the user list with all clients

func sync_usernames():
	print("Syncing user list with clients: ", players)
	rpc("receive_user_list", players)

# RPC function to receive the updated list of users on clients
@rpc("authority")
func receive_user_list(user_list: Array):
	print("Received updated user list: ", user_list)
	players = user_list
	render_playerlist()
	# Update the UI or perform necessary actions with the user list here


func render_playerlist():
	var grid
	if authority == Authority.SERVER:
		grid = $UI_WaitForPlayers/GridContainer
	else:
		grid = $UI_WaitForPlayersClient/GridContainer
	
	for child in grid.get_children():
		child.queue_free()
	for player_name in players:
		if player_name != username:
			var player_label = Label.new()
			player_label.text = player_name
			grid.add_child(player_label)
			
func start_playing():
	state = State.PLAYING
	$UI_WaitForPlayers.visible = false
	self.add_child(scene.instantiate())
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	rpc("start_playing_client")
	
	var spawn_direction = (get_node("root/floor/Sepultura2").position - get_node("root/WorldCenter").position).normalized()
	var spawn_position = get_node("root/floor/Sepultura2").position - spawn_direction * 20
	
	var created_player = player.instantiate()
	created_player.position = spawn_position
	self.add_child(created_player)

@rpc("authority")
func start_playing_client():
	state = State.PLAYING
	$UI_WaitForPlayersClient.visible = false
	self.add_child(scene.instantiate())
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var index = players.find(username) + 1
	var spawnpoint_name = "Sepultura" + str(index)
	var spawnpoint_position = get_node("root/floor").get_node(spawnpoint_name).position
	var spawn_direction = (get_node("root/floor").get_node(spawnpoint_name).position - get_node("root/WorldCenter").position).normalized()
	
	var adjusted_spawnpoint_position = spawnpoint_position - spawn_direction * 10
	var created_player = player.instantiate()
	created_player.position = adjusted_spawnpoint_position
	self.add_child(created_player)
	
	
