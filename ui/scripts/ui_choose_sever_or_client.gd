extends Control

@onready var ButtonServer = $CreateServer
@onready var ButtonClient = $JoinServer

var main

func _ready() -> void:
	main = get_tree().get_root().get_node('main')

func _on_create_server_pressed() -> void:
	main.authority = main.Authority.SERVER
	main.state = main.State.CREATE_SERVER
	main.create_server()
	main.get_node('UI_WaitForPlayers').visible = true
	main.get_node('UI_DiscoverServers').visible = false
	self.visible = false
	pass # Replace with function body.


func _on_join_server_pressed() -> void:
	main.authority = main.Authority.CLIENT
	main.state = main.State.JOIN_SERVER
	main.wait_server_broadcasts()
	main.get_node('UI_WaitForPlayers').visible = false
	main.get_node('UI_DiscoverServers').visible = true
	self.visible = false
	pass # Replace with function body.
