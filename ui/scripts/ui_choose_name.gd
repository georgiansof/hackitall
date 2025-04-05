extends Control

@onready var ButtonNext = $ButtonNext

func _ready() :
	pass


func _on_button_next_pressed() -> void:
	var main = get_tree().get_root().get_node('main') 
	main.username = $UsernameBox.text
	main.players.append(main.username)
	
	main.get_node('UI_ChooseName').visible = false
	main.get_node('UI_ChooseServerOrClient').visible = true
	
	main.state = main.State.CHOOSING_ROLE
	pass 
