extends Button

class_name ConnectButton

@onready var main = get_tree().get_root().get_node("main")
var ip : String
var port : int

func _init(_ip:String, _port:int):
	self.ip = ip
	self.port = port

func _ready():
	self.connect("pressed", _on_press)
	
func _on_press():
	main.connect_to_server(ip, port)
	pass
	
