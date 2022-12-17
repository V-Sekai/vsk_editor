extends Control


func _show_uro_menu() -> void:
	var vsk_editor: Node = get_node_or_null("/root/VSKEditor")
	if vsk_editor:
		vsk_editor.show_profile_panel()
	else:
		printerr("Could not load VSKEditor")


func _ready():
	var button = $Panel/ButtonContainer/Button
	button.pressed.connect(self._show_uro_menu)

	var vsk_editor: Node = get_node_or_null("/root/VSKEditor")
	if vsk_editor:
		vsk_editor.setup_editor(self, button, null)
	else:
		printerr("Could not load VSKEditor")
