extends Control

func export_data() -> Dictionary:
	return {}

func _ready():
	VSKEditor.setup_user_interfaces(self, null, null)
