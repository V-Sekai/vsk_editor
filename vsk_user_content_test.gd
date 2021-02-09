extends Control

func export_data() -> Dictionary:
	return {}

func _ready():
	VSKEditor.setup_editor(self, null, null, null)
