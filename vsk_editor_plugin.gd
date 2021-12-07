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


# autoload singletons create global scope variables, but it seems that the same
# script which calls `add_autoload_singleton` cannot reference those autoloads.
# If there's a getter like get_autoload() we could use that, but I can't find it
# so instead the last recourse is to do something like `eval` but how to do it?
# We do a stupidly complex approach modified from here:
# https://godotengine.org/qa/339/does-gdscript-have-method-to-execute-string-code-exec-python
func evaluate_gdscript_hack(input, param_dict={}):
	var script = GDScript.new()
	var src = "@tool\nextends RefCounted\n"
	src += "@export var _param_dict: Dictionary = {}\n"
	src += "func myfunction():\n"
	for param in param_dict:
		src += "\tvar " + param + ": Variant = _param_dict[" + var2str(param) + "]\n"
	src += "\t" + input
	print(src)
	script.set_source_code(src)
	script.reload()
	var obj: Object = RefCounted.new()
	obj.set_script(script)
	obj.set("_param_dict", param_dict)
	obj.call("myfunction")


func setup_vskeditor(viewport, button, editor_interface, undo_redo):
	print(get_node("/root/VSKEditor").get_path())
	$"/root/VSKEditor".setup_editor(editor_interface.get_viewport(), button, editor_interface)

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
	
	
	# FIXME: WAT. The next link can't be run because we haven't run the previous line yet.
	# but now this creates a syntax error :'-(
	# Existing projects won't have this problem because VSKEditor is already defined as singleton
	# from the previous iteration
	call_deferred("setup_vskeditor", editor_interface.get_viewport(), button, editor_interface, undo_redo)

	button.call_deferred("set_disabled", false) # What keeps disabling this button?!

func _exit_tree() -> void:
	get_node("/root/VSKEditor").teardown_editor_user_interfaces()
	# evaluate_gdscript_hack("VSKEditor.teardown_editor_user_interfaces()")

	remove_autoload_singleton("VSKEditor")
	button.queue_free()
