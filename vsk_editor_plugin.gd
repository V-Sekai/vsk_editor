@tool
extends EditorPlugin

var uro_logo_png = load("res://addons/vsk_editor/uro_logo.png")
var editor_interface: EditorInterface = null
var undo_redo: UndoRedo = null
var button: Button = null


func _init():
	print("Initialising VSKEditor plugin")


func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying VSKEditor plugin")


func _get_plugin_name() -> String:
	return "VSKEditor"

func setup_vskeditor(
	viewport: Viewport,
	button: Button,
	editor_interface: EditorInterface,
	undo_redo: UndoRedo) -> void:
		
	VSKEditor.setup_editor(editor_interface.get_editor_main_control(), button, editor_interface)

func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	undo_redo = get_undo_redo()

	add_autoload_singleton("VSKEditor", "res://addons/vsk_editor/vsk_editor.gd")

	button = Button.new()
	button.set_text("Uro")
	button.set_button_icon(uro_logo_png)
	button.set_tooltip("Access the Uro Menu.")
	button.set_flat(true)
	button.set_disabled(false) # true

	add_control_to_container(CONTAINER_TOOLBAR, button)
	
	
	# FIXME: WAT. The next link can't be rsun because we haven't run the previous line yet.
	# but now this creates a syntax error :'-(
	# Existing projects won't have this problem because VSKEditor is already defined as singleton
	# from the previous iteration
	call_deferred("setup_vskeditor", editor_interface.get_viewport(), button, editor_interface, undo_redo)

	button.call_deferred("set_disabled", false) # What keeps disabling this button?!

func _exit_tree() -> void:
	VSKEditor.teardown_editor_user_interfaces()

	remove_autoload_singleton("VSKEditor")
	button.queue_free()
