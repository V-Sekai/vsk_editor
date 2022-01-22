@tool
extends Window

var vsk_editor: Node = null

const WINDOW_SIZE = Vector2(650, 800)

var control: Control = null

var vsk_login_control_script_const = preload("vsk_login_editor_control.gd")
var vsk_profile_control_script_const = preload("vsk_profile_editor_control.gd")

# const vsk_profile_control_const = preload("vsk_profile_editor_control.tscn")
var vsk_profile_control_const = load("res://addons/vsk_editor/vsk_profile_editor_control.tscn")

func _clear_children() -> void:
	if control:
		control.queue_free()
		control.get_parent().remove_child(control)
	control = null
		
func _instance_login_child_control() -> void:
	set_title("Sign in")
	
	if control and control.get_script() != vsk_login_control_script_const:
		_clear_children()
	
	if !control:
		control = vsk_login_control_script_const.new(vsk_editor)
		if control.connect("session_request_successful", Callable(self, "_state_changed")) != OK:
			printerr("Could not connect 'session_request_successful'")
		
		
		
		add_child(control, true)

		control.set_anchors_and_offsets_preset(Control.PRESET_WIDE, Control.PRESET_MODE_MINSIZE)
		
func _instance_profile_child_control() -> void:
	set_title("Profile")
	
	if control and not control.get_script() is vsk_profile_control_script_const:
		_clear_children()
	
	if !control:
		control = vsk_profile_control_const.instantiate()
		control.set_vsk_editor(vsk_editor)
		if control.connect("session_deletion_successful", Callable(self, "_state_changed")) != OK:
			printerr("Could not connect 'session_deletion_successful'")
		
		add_child(control, true)

		control.set_anchors_and_offsets_preset(Control.PRESET_WIDE, Control.PRESET_MODE_MINSIZE)

func _instance_child_control() -> void:
	if VSKAccountManager.signed_in:
		_instance_profile_child_control()
	else:
		_instance_login_child_control()

func _about_to_popup() -> void:
	_state_changed()

func _state_changed() -> void:
	_instance_child_control()

func _ready() -> void:
	if connect("about_to_popup", self._about_to_popup) != OK:
		printerr("Could not connect to about_to_popup")


func _init(p_vsk_editor: Node):
	vsk_editor = p_vsk_editor
	
	set_title("Sign in")
	set_size(WINDOW_SIZE)
