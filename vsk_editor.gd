extends Node
tool

const vsk_upload_dialog_const = preload("vsk_upload_dialog.gd")
var vsk_upload_dialog: vsk_upload_dialog_const = null

const vsk_progress_dialog_const = preload("vsk_progress_dialog.tscn")
var vsk_progress_dialog: Control = null

const vsk_info_dialog_const = preload("vsk_info_dialog.tscn")
var vsk_info_dialog: Control = null

const vsk_profile_dialog_const = preload("vsk_profile_dialog.gd")
var vsk_profile_dialog: vsk_profile_dialog_const = null

const vsk_types_const = preload("res://addons/vsk_importer_exporter/vsk_types.gd")

var undo_redo: UndoRedo = null
var editor_interface: EditorInterface = null

var session_request_pending: bool = true
var display_name: String

var uro_button: Button = null

signal user_content_submission_requested(p_upload_data, p_callbacks)
signal user_content_submission_cancelled()
signal user_content_new_id(p_node, p_id)

signal sign_in_submission_sent()
signal sign_in_submission_complete(p_result)

signal session_request_complete(p_code, p_message)
signal session_deletion_complete(p_code, p_message)


"""
Uro Pipeline
"""

const vsk_pipeline_uro_const = preload("res://addons/vsk_importer_exporter/vsk_uro_pipeline.gd")

static func _update_uro_pipeline(p_edited_scene: Node, p_undo_redo: UndoRedo, p_node: Node, p_id: String, p_update_id: bool) -> String:
	for pipeline_path in p_node.get("pipeline_paths"):
		var pipeline = p_node.get_node_or_null(pipeline_path)
		if pipeline is vsk_pipeline_uro_const:
			if p_update_id and pipeline.database_id != p_id:
				p_undo_redo.create_action("Add database id")
				p_undo_redo.add_do_property(pipeline, "database_id", p_id)
				p_undo_redo.add_undo_property(pipeline, "database_id", pipeline.database_id)
				p_undo_redo.commit_action()
				
				return p_id
			else:
				return pipeline.database_id
				
	var uro_pipeline: vsk_pipeline_uro_const = vsk_pipeline_uro_const.new(p_id)
	uro_pipeline.set_name("UroPipeline")
				
	p_undo_redo.create_action("Create Uro Pipeline")
	p_undo_redo.add_do_method(p_node, "add_child", uro_pipeline)
	p_undo_redo.add_do_method(uro_pipeline, "set_owner", p_edited_scene);
	p_undo_redo.add_do_method(p_node, "add_pipeline", uro_pipeline)
	
	p_undo_redo.add_undo_method(p_node, "remove_pipeline", uro_pipeline)
	p_undo_redo.add_undo_method(p_node, "remove_child", uro_pipeline)
	
	p_undo_redo.commit_action()
	
	return p_id

func user_content_new_uro_id(p_node: Node, p_id: String) -> void:
	if undo_redo:
		_update_uro_pipeline(editor_interface.get_edited_scene_root(), undo_redo, p_node, p_id, true)
	
	var inspector: EditorInspector = editor_interface.get_inspector()
	inspector.refresh()
	
func user_content_get_uro_id(p_node: Node) -> String:
	var id: String = ""
	if undo_redo:
		id = _update_uro_pipeline(editor_interface.get_edited_scene_root(), undo_redo, p_node, p_node.database_id, false)
	
	print("user_content_get_uro_id: %s" % id)
	
	var inspector: EditorInspector = editor_interface.get_inspector()
	inspector.refresh()
	
	return id
	
"""

"""

static func get_upload_data_for_packed_scene(p_packed_scene: PackedScene) -> Dictionary:
	if VSKExporter.create_temp_folder() == OK:
		if VSKExporter.save_user_content_resource("user://temp/autogen.scn", p_packed_scene) == OK:
			var file: File = File.new()
			if file.open("user://temp/autogen.scn", File.READ) == OK:
				var buffer = file.get_buffer(file.get_len())
				file.close()
				
				return {"filename":"autogen.scn", "content_type":"application/octet-stream", "data":buffer}
		
		printerr("Failed to get upload data!")
	else:
		printerr("Could not create temp directory")
	
	return {}


static func get_raw_png_from_image(p_image: Image) -> Dictionary:
	return  {"filename":"autogen.png", "content_type":"image/png", "data":p_image.save_png_to_buffer()}

"""

"""

func show_profile_panel() -> void:
	if vsk_profile_dialog:
		vsk_profile_dialog.popup_centered()


func show_upload_panel(p_callback: FuncRef, p_user_content: int) -> void:
	if vsk_upload_dialog:
		if editor_interface:
			vsk_upload_dialog.set_reference_viewport(editor_interface.get_edited_scene_root().get_viewport())
		else:
			vsk_upload_dialog.set_reference_viewport(null)
			
		vsk_upload_dialog.set_export_data_callback(p_callback)
		vsk_upload_dialog.set_user_content_type(p_user_content)
		vsk_upload_dialog.popup_centered()


func set_session_request_pending(p_is_pending: bool) -> void:
	print("VSKEditor::set_session_request_pending")
	session_request_pending = p_is_pending
	if uro_button:
		uro_button.set_disabled(session_request_pending)


func sign_out() -> void:
	print("VSKEditor::sign_out")
	
	VSKAccountManager.sign_out()


func sign_in(username_or_email: String, password: String) -> void:
	print("VSKEditor::sign_in")
	
	VSKAccountManager.sign_in(username_or_email, password)
	emit_signal("sign_in_submission_complete", OK)


func _submit_button_pressed(p_upload_data: Dictionary) -> void:
	print("VSKEditor::_submit_button_pressed")
	
	if vsk_progress_dialog:
		vsk_progress_dialog.popup_centered()
		vsk_progress_dialog.set_progress_label_text("")
		vsk_progress_dialog.set_progress_bar_value(0.0)
		
		var packed_scene_created_callback: FuncRef = FuncRef.new()
		packed_scene_created_callback.set_instance(self)
		packed_scene_created_callback.set_function("_packed_scene_created_callback")
		
		var packed_scene_creation_failed_callback: FuncRef = FuncRef.new()
		packed_scene_creation_failed_callback.set_instance(self)
		packed_scene_creation_failed_callback.set_function("_packed_scene_creation_failed_callback")
		
		var packed_scene_pre_uploading_callback: FuncRef = FuncRef.new()
		packed_scene_pre_uploading_callback.set_instance(self)
		packed_scene_pre_uploading_callback.set_function("_packed_scene_pre_uploading_callback")
		
		var packed_scene_uploaded_callback: FuncRef = FuncRef.new()
		packed_scene_uploaded_callback.set_instance(self)
		packed_scene_uploaded_callback.set_function("_packed_scene_uploaded_callback")

		var packed_scene_upload_failed_callback: FuncRef = FuncRef.new()
		packed_scene_upload_failed_callback.set_instance(self)
		packed_scene_upload_failed_callback.set_function("_packed_scene_upload_failed_callback")

		emit_signal("user_content_submission_requested", p_upload_data, 
		{
			"packed_scene_created":packed_scene_created_callback,
			"packed_scene_creation_failed":packed_scene_creation_failed_callback,
			"packed_scene_pre_uploading":packed_scene_pre_uploading_callback,
			"packed_scene_uploaded":packed_scene_uploaded_callback,
			"packed_scene_upload_failed":packed_scene_upload_failed_callback
		})
	else:
		printerr("Progress dialog is null!")


func _cancel_button_pressed() -> void:
	emit_signal("user_content_submission_cancelled")
	
	
func _user_content_get_failed(p_error_code: int) -> void:
	vsk_upload_dialog.hide()
	vsk_progress_dialog.hide()
	
	vsk_info_dialog.set_info_text("Failed with error code: %s" % str(p_error_code))
	vsk_info_dialog.popup_centered()
	
func _requesting_user_content(p_user_content_type: int, p_database_id: String, p_callback: FuncRef) -> void:
	var user_content: Dictionary = {}
	
	match p_user_content_type:
		vsk_types_const.UserContentType.Avatar:
			if p_database_id != "":
				var result = yield(
					GodotUro.godot_uro_api.dashboard_get_avatar_async(p_database_id),
					"completed"
				)
				if result["code"] == HTTPClient.RESPONSE_OK:
					var output: Dictionary = result["output"]
					var data: Dictionary = output["data"]
					if data.has("avatar"):
						user_content = data["avatar"]
				else:
					_user_content_get_failed(result["code"])
					return
		vsk_types_const.UserContentType.Map:
			if p_database_id != "":
				var result = yield(
					GodotUro.godot_uro_api.dashboard_get_map_async(p_database_id),
					"completed"
				)
				if result["code"] == HTTPClient.RESPONSE_OK:
					var output: Dictionary = result["output"]
					var data: Dictionary = output["data"]
					if data.has("map"):
						user_content = data["map"]
				else:
					_user_content_get_failed(result["code"])
					return
				
	p_callback.call_func(p_database_id, p_user_content_type, user_content)


"""
Setup user interfaces
"""

func _setup_progress_panel(p_root: Control) -> void:
	print("VSKEditor::_setup_progress_panel")
	
	vsk_progress_dialog = vsk_progress_dialog_const.instance()
	p_root.add_child(vsk_progress_dialog)
	
	vsk_progress_dialog.connect("cancel_button_pressed", self, "_cancel_button_pressed")


func _setup_info_panel(p_root: Control) -> void:
	print("VSKEditor::_setup_info_panel")
	
	vsk_info_dialog = vsk_info_dialog_const.instance()
	p_root.add_child(vsk_info_dialog)

func _setup_upload_panel(p_root: Control) -> void:
	print("VSKEditor::_setup_upload_panel")
	
	vsk_upload_dialog = vsk_upload_dialog_const.new()
	p_root.add_child(vsk_upload_dialog)
	
	vsk_upload_dialog.connect("submit_button_pressed", self, "_submit_button_pressed")
	vsk_upload_dialog.connect("requesting_user_content", self, "_requesting_user_content")


func _setup_profile_panel(p_root: Control) -> void:
	print("VSKEditor::_setup_profile_panel")
	
	vsk_profile_dialog = vsk_profile_dialog_const.new()
	p_root.add_child(vsk_profile_dialog)


func setup_editor(p_root: Control, p_uro_button: Button, p_editor_interface: EditorInterface, p_undo_redo: UndoRedo) -> void:
	print("VSKEditor::setup_editor")
	
	if p_uro_button:
		uro_button = p_uro_button
		uro_button.set_disabled(session_request_pending)
	
	_setup_profile_panel(p_root)
	_setup_upload_panel(p_root)
	_setup_progress_panel(p_root)
	_setup_info_panel(p_root)
	
	editor_interface = p_editor_interface
	undo_redo = p_undo_redo

"""
Teardown user interfaces
"""

func _teardown_progress_panel() -> void:
	print("VSKEditor::_teardown_progress_panel")
	
	if vsk_progress_dialog:
		vsk_progress_dialog.queue_free()


func _teardown_info_panel() -> void:
	print("VSKEditor::_teardown_info_panel")
	
	if vsk_info_dialog:
		vsk_info_dialog.queue_free()


func _teardown_upload_panel() -> void:
	print("VSKEditor::_teardown_upload_panel")
	
	if vsk_upload_dialog:
		vsk_upload_dialog.queue_free()


func _teardown_profile_panel() -> void:
	print("VSKEditor::_teardown_profile_panel")
	
	if vsk_profile_dialog:
		vsk_profile_dialog.queue_free()


func teardown_editor_user_interfaces():
	print("VSKEditor::teardown_editor_user_interfaces")
	
	_teardown_profile_panel()
	_teardown_upload_panel()
	_teardown_progress_panel()
	_teardown_info_panel()
		
		
"""
Submission callbacks
"""

func _packed_scene_created_callback(p_packed_scene: PackedScene) -> void:
	print("VSKEditor::_packed_scene_created_callback")
	
	vsk_progress_dialog.set_progress_label_text("Scene packaging complete!")
	vsk_progress_dialog.set_progress_bar_value(50.0)


func _packed_scene_creation_failed_created_callback(p_error_message: String) -> void:
	printerr("VSKEditor::_packed_scene_creation_failed_created_callback: " + p_error_message)
	
	vsk_upload_dialog.hide()
	vsk_progress_dialog.hide()
	
	vsk_info_dialog.set_info_text(p_error_message)
	vsk_info_dialog.popup_centered()
	
func _create_upload_dictionary(p_name: String, p_description: String,\
	p_packed_scene: PackedScene, p_image: Image) -> Dictionary:
	
	var dictionary: Dictionary = {"name":p_name, "description":p_description}
	if p_packed_scene:
		var user_content_data: Dictionary = get_upload_data_for_packed_scene(p_packed_scene)
		if !user_content_data.empty():
			dictionary["user_content_data"] = user_content_data
		else:
			return {}
			
	if p_image:
		dictionary["user_content_preview"] = get_raw_png_from_image(p_image)
	
	return dictionary

func _packed_scene_pre_uploading_callback(p_packed_scene: PackedScene, p_upload_data: Dictionary, p_callbacks: Dictionary) -> void:
	print("VSKEditor::_packed_scene_pre_uploading_callback")
	
	vsk_progress_dialog.set_progress_label_text("Scene uploading...")
	vsk_progress_dialog.set_progress_bar_value(50.0)
	
	###
	var export_data_callback = p_upload_data["export_data_callback"]
	var export_data: Dictionary = export_data_callback.call_func()

	var root: Node = export_data["root"]
	var node: Node = export_data["node"]
	
	var database_id: String = user_content_get_uro_id(node)
	
	if GodotUro.godot_uro_api:
		var name: String = p_upload_data.get("name", "")
		var description: String = p_upload_data.get("description", "")
		var preview_image: Image = p_upload_data.get("preview_image", null)
		
		var result: Dictionary = {}
		var type: int = p_upload_data["user_content_type"]
		var upload_dictionary: Dictionary = _create_upload_dictionary(name, description, p_packed_scene, preview_image)
		
		if !upload_dictionary.empty():
			if database_id == "":
				match type:
					vsk_types_const.UserContentType.Avatar:
						result = yield(
							GodotUro.godot_uro_api.dashboard_create_avatar_async(
							upload_dictionary), "completed"
						)
					vsk_types_const.UserContentType.Map:
						result = yield(
							GodotUro.godot_uro_api.dashboard_create_map_async(
							upload_dictionary), "completed"
						)
			else:
				match type:
					vsk_types_const.UserContentType.Avatar:
						result = yield(
							GodotUro.godot_uro_api.dashboard_update_avatar_async(database_id,
							upload_dictionary), "completed"
						)
					vsk_types_const.UserContentType.Map:
						result = yield(
							GodotUro.godot_uro_api.dashboard_update_map_async(database_id,
							upload_dictionary), "completed"
						)
			
			var code: int = result["code"]
			print("User content upload response code: %s" % str(code))
			
			if code == HTTPClient.RESPONSE_OK:
				var output: Dictionary = result["output"]
				var data: Dictionary = output["data"]
				database_id = data["id"]
				
				p_callbacks["packed_scene_uploaded"].call_func(database_id)
				
				user_content_new_uro_id(node, database_id)
			else:
				p_callbacks["packed_scene_upload_failed"].call_func("Upload failed with error code: %s" % str(code))
		else:
			p_callbacks["packed_scene_upload_failed"].call_func("Could not process upload data!")
	else:
		p_callbacks["packed_scene_upload_failed"].call_func("Could not load Godot Uro API")


func _packed_scene_uploaded_callback(p_database_id: String) -> void:
	print("VSKEditor::_packed_scene_uploaded_callback: " + p_database_id)
	
	vsk_progress_dialog.hide()
	vsk_upload_dialog.hide()
	
	vsk_info_dialog.set_info_text("Uploaded successfully!")
	vsk_info_dialog.popup_centered()


func _packed_scene_upload_failed_callback(p_error_message: String) -> void:
	printerr("VSKEditor::_packed_scene_upload_failed_callback: " + str(p_error_message))
	
	vsk_progress_dialog.hide()
	vsk_upload_dialog.hide()
	
	vsk_info_dialog.set_info_text(p_error_message)
	vsk_info_dialog.popup_centered()
		
"""
Session callbacks
"""
		
func _session_renew_started() -> void:
	print("VSKEditor::_session_renew_started")
	set_session_request_pending(true)

func _session_request_complete(p_code: int, p_message: String) -> void:
	print("VSKEditor::_session_request_complete")
	
	if p_code == HTTPClient.RESPONSE_OK:
		display_name = VSKAccountManager.account_display_name
		print("Logged into V-Sekai as %s" % display_name)
	else:
		display_name = ""
		print("Could not log into V-Sekai(%s)..." % p_message)
	
	set_session_request_pending(false)
	emit_signal("session_request_complete", p_code, p_message)


func _session_deletion_complete(p_code: int, p_message: String) -> void:
	print("VSKEditor::_session_deletion_complete")
	
	display_name = ""
	
	emit_signal("session_deletion_complete", p_code, p_message)
	
"""
Tree functions
"""

func _enter_tree():
	VSKAccountManager.connect("session_renew_started", self, "_session_renew_started")
	VSKAccountManager.connect("session_request_complete", self, "_session_request_complete")
	VSKAccountManager.connect("session_deletion_complete", self, "_session_deletion_complete")


func _exit_tree():
	VSKAccountManager.disconnect("session_renew_started", self, "_session_renew_started")
	VSKAccountManager.disconnect("session_request_complete", self, "_session_request_complete")
	VSKAccountManager.disconnect("session_deletion_complete", self, "_session_deletion_complete")
	
func _ready():
	pass
