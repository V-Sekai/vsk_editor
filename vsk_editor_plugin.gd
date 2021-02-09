extends EditorPlugin
tool

const uro_logo_const = preload("uro_logo.png")
var editor_interface: EditorInterface = null
var undo_redo: UndoRedo = null
var button: Button = null


func _show_profile_panel() -> void:
	VSKEditor.show_profile_panel()


func _init() -> void:
	print("Initialising VSKEditor plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying VSKEditor plugin")


func get_name() -> String:
	return "VSKEditor"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	undo_redo = get_undo_redo()

	add_autoload_singleton("VSKEditor", "res://addons/vsk_editor/vsk_editor.gd")

	button = Button.new()
	button.set_text("Uro")
	button.set_button_icon(uro_logo_const)
	button.set_tooltip("Access the Uro Menu.")
	button.set_flat(true)
	button.set_disabled(true)
	button.connect("pressed", self, "_show_profile_panel")

	add_control_to_container(CONTAINER_TOOLBAR, button)

	VSKEditor.setup_editor(editor_interface.get_editor_viewport(), button, editor_interface, undo_redo)


func _exit_tree() -> void:
	VSKEditor.teardown_editor_user_interfaces()

	remove_autoload_singleton("VSKEditor")
	button.free()
