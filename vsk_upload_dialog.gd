extends WindowDialog
tool

signal submit_button_pressed(p_submission_data)
signal requesting_user_content(user_content_type, p_database_id, p_callback)

const LOGIN_REQUIRED_STRING = "Please log in to upload content"
const TITLE_STRING = "Upload"
const WINDOW_RESOLUTION = Vector2(1280, 720)

const upload_panel_content_const = preload("vsk_upload_panel_contents.tscn")

var export_data_callback: FuncRef = null
var user_content_type: int = -1
var current_database_id: String = ""

var control: Control = null
var reference_viewport: Viewport = null

var upload_data: Dictionary = {}

func _submit_pressed(p_submission_data: Dictionary) -> void:
	print("Submitting " + str(p_submission_data))
	emit_signal("submit_button_pressed", p_submission_data)


func set_export_data_callback(p_callback: FuncRef) -> void:
	export_data_callback = p_callback


func set_user_content_type(p_user_content_type: int) -> void:
	user_content_type = p_user_content_type


func set_reference_viewport(p_reference_viewport: Viewport) -> void:
	reference_viewport = p_reference_viewport


func _clear_children() -> void:
	print(control)
	if control:
		control.queue_free()
		control.get_parent().remove_child(control)
	control = null

func _instance_upload_panel_child_control() -> void:
	set_title(TITLE_STRING)
	
	_clear_children()
	
	if !control:
		control = upload_panel_content_const.instance()
		control.set_export_data_callback(export_data_callback)
		control.set_user_content_type(user_content_type)
		control.set_reference_viewport(reference_viewport)
		add_child(control)
		
		control.connect("submit_button_pressed", self, "_submit_pressed")
		
		var user_content_node: Node = null
		var export_data: Dictionary = export_data_callback.call_func()
		user_content_node = export_data.get("node")
		
		if user_content_node:
			current_database_id = VSKEditor.user_content_get_uro_id(user_content_node)
		else:
			current_database_id = ""
			
		
		_request_user_content(user_content_type, current_database_id)

		control.set_anchors_and_margins_preset(PRESET_WIDE, PRESET_MODE_MINSIZE)

func _instance_login_required_child_control() -> void:
	set_title(TITLE_STRING)
	
	_clear_children()
	
	if !control:
		var info_label: Label = Label.new()
		info_label.set_text(LOGIN_REQUIRED_STRING)
		info_label.set_align(Label.ALIGN_CENTER)
		info_label.set_valign(Label.VALIGN_CENTER)
		
		control = info_label
		add_child(info_label)
		
		control.set_anchors_and_margins_preset(PRESET_WIDE, PRESET_MODE_MINSIZE)

func _received_user_content_data(p_database_id: String, p_user_content_type: int, p_user_content_data: Dictionary) -> void:
	if p_database_id == current_database_id:
		control.update_user_content_data(p_user_content_data, p_database_id != "")

func _request_user_content(p_user_content_type: int, p_database_id: String) -> void:
	var callback: FuncRef = FuncRef.new()
	callback.set_instance(self)
	callback.set_function("_received_user_content_data")
	
	emit_signal(
		"requesting_user_content",\
		p_user_content_type,\
		p_database_id,\
		callback\
	)

func _instance_child_control() -> void:
	if VSKAccountManager.signed_in:
		_instance_upload_panel_child_control()
	else:
		_instance_login_required_child_control()

func _about_to_show() -> void:
	_state_changed()

func _state_changed() -> void:
	_instance_child_control()

func _ready() -> void:
	if connect("about_to_show", self, "_about_to_show") != OK:
		printerr("Could not connect to about_to_show")


func _init() -> void:
	set_title(TITLE_STRING)
	set_size(WINDOW_RESOLUTION)
	
func _enter_tree():
	pass
	#VSKAccountManager.connect("session_renew_started", self, "_session_renew_started")
	#VSKAccountManager.connect("session_request_complete", self, "_session_request_complete")
	#VSKAccountManager.connect("session_deletion_complete", self, "_session_deletion_complete")


func _exit_tree():
	pass
	#VSKAccountManager.disconnect("session_renew_started", self, "_session_renew_started")
	#VSKAccountManager.disconnect("session_request_complete", self, "_session_request_complete")
	#VSKAccountManager.disconnect("session_deletion_complete", self, "_session_deletion_complete")
