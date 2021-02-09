extends Control

func _show_uro_menu() -> void:
	VSKEditor.show_profile_panel()

func _ready():
	var button = $Panel/ButtonContainer/Button
	button.connect("pressed", self, "_show_uro_menu")

	VSKEditor.setup_editor(self, button, null, null)
