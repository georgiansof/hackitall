extends Control

func _on_button_pressed() -> void:
	self.visible = false
	var main = get_tree().get_root().get_node('main')
	main.start_playing()
	pass 
