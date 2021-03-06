tool
extends Control

const VIEWPORT_SIZE = Vector2(1280, 720)

signal submit_button_pressed(p_submission_data)

export(NodePath) var name_line_edit_path: NodePath = NodePath()
export(NodePath) var description_text_edit_path: NodePath = NodePath()
export(NodePath) var saved_preview_texture_rect_path: NodePath = NodePath()
export(NodePath) var new_preview_texture_rect_path: NodePath = NodePath()
export(NodePath) var update_preview_checkbox_path: NodePath = NodePath()

export(NodePath) var submit_button_path: NodePath = NodePath()

var viewport: Viewport = null
var new_preview_texture: Texture = null

var export_data_callback: FuncRef = null
var user_content_type: int = -1
var user_content_data: Dictionary = {}

var updating_content: bool = false

func _update_preview(p_preview_toggled: bool) -> void:
	if p_preview_toggled:
		get_node(new_preview_texture_rect_path).show()
		get_node(saved_preview_texture_rect_path).hide()
	else:
		get_node(new_preview_texture_rect_path).hide()
		get_node(saved_preview_texture_rect_path).show()
		
func _on_UpdatePreviewCheckbox_toggled(button_pressed):
	_update_preview(button_pressed)

func update_user_content_data(p_dictionary: Dictionary, p_updating_content: bool) -> void:
	updating_content = p_updating_content
	user_content_data = p_dictionary
	
	if updating_content:
		get_node(name_line_edit_path).text = user_content_data.get("name", "NAME_NOT_FOUND")
		get_node(description_text_edit_path).text = user_content_data.get("description", "DESC_NOT_FOUND")
		
		get_node(saved_preview_texture_rect_path).textureUrl = GodotUro.get_base_url() + user_content_data.get("user_content_preview", "")
		
		get_node(update_preview_checkbox_path).pressed = false
		get_node(update_preview_checkbox_path).disabled = false
	else:
		get_node(name_line_edit_path).text = ""
		get_node(description_text_edit_path).text = ""
		
		get_node(saved_preview_texture_rect_path).textureUrl = ""
		
		get_node(update_preview_checkbox_path).pressed = true
		get_node(update_preview_checkbox_path).disabled = true
		
	get_node(name_line_edit_path).editable = true
	get_node(description_text_edit_path).readonly = false
		
	_update_submit_button()
	_update_preview(get_node(update_preview_checkbox_path).pressed)


func set_export_data_callback(p_callback: FuncRef) -> void:
	export_data_callback = p_callback
	var export_data: Dictionary = export_data_callback.call_func()
	
	var node: Node = export_data.get("node")
	
	new_preview_texture = null
	
	if node:
		if node.get("vskeditor_preview_type")  == "Camera":
			var camera_preview_path = node.get("vskeditor_preview_camera_path")
			if camera_preview_path is NodePath:
				var camera: Camera = node.get_node_or_null(camera_preview_path)
				if camera:
					VisualServer.viewport_attach_camera(viewport.get_viewport_rid(), camera.get_camera_rid())
					new_preview_texture = viewport.get_texture()
					if new_preview_texture:
						get_node(new_preview_texture_rect_path).set_texture(new_preview_texture)
		else:
			var vskeditor_preview_texture = node.get("vskeditor_preview_texture")
			if vskeditor_preview_texture is Texture:
				new_preview_texture = vskeditor_preview_texture
				if new_preview_texture:
					get_node(new_preview_texture_rect_path).set_texture(new_preview_texture)
		

func set_user_content_type(p_user_content_type: int) -> void:
	user_content_type = p_user_content_type
	

func _get_submission_data() -> Dictionary:
	var name_line_edit: LineEdit = get_node(name_line_edit_path)
	var description_text_edit: TextEdit = get_node(description_text_edit_path)
	var update_preview_checkbox: CheckBox = get_node(update_preview_checkbox_path)
	
	if name_line_edit\
	and description_text_edit\
	and update_preview_checkbox:
		var submission_data: Dictionary = {
			"name":name_line_edit.text,\
			"description":description_text_edit.text,\
			"update_preview":update_preview_checkbox.pressed,\
			"export_data_callback":export_data_callback,\
			"user_content_type":user_content_type
		}
		
		if update_preview_checkbox.pressed and new_preview_texture:
			submission_data["preview_image"] = new_preview_texture.get_data()
			
		return submission_data
	else:
		printerr("Invalid nodepaths!")
		
	return {}


func _update_submit_button() -> void:
	var name_line_edit: LineEdit = get_node(name_line_edit_path)
	var submit_button: Button = get_node(submit_button_path)
	
	if submit_button:
		submit_button.disabled = true
		if name_line_edit and name_line_edit.text.length() > 0:
			submit_button.disabled = false


func _on_SubmitButton_pressed():
	emit_signal("submit_button_pressed", _get_submission_data())


func _on_NameEditField_text_changed(_new_text):
	_update_submit_button()


static func _update_viewport_from_project_settings(p_viewport: Viewport) -> Viewport:
	var new_viewport = p_viewport
	
	new_viewport.shadow_atlas_size = ProjectSettings.get_setting("rendering/quality/shadow_atlas/size")
	new_viewport.shadow_atlas_quad_0 = ProjectSettings.get_setting("rendering/quality/shadow_atlas/quadrant_0_subdiv")
	new_viewport.shadow_atlas_quad_1 = ProjectSettings.get_setting("rendering/quality/shadow_atlas/quadrant_1_subdiv")
	new_viewport.shadow_atlas_quad_2 = ProjectSettings.get_setting("rendering/quality/shadow_atlas/quadrant_2_subdiv")
	new_viewport.shadow_atlas_quad_3 = ProjectSettings.get_setting("rendering/quality/shadow_atlas/quadrant_3_subdiv")
	
	new_viewport.msaa = ProjectSettings.get_setting("rendering/quality/filters/msaa")
	new_viewport.fxaa = ProjectSettings.get_setting("rendering/quality/filters/use_fxaa")
	new_viewport.debanding = ProjectSettings.get_setting("rendering/quality/filters/use_debanding")
	new_viewport.hdr = ProjectSettings.get_setting("rendering/quality/depth/hdr")
	
	return new_viewport

func _ready() -> void:
	add_child(viewport)
	viewport = _update_viewport_from_project_settings(viewport)
	
	
func _init():
	viewport = Viewport.new()
	viewport.set_size(VIEWPORT_SIZE)
	viewport.set_vflip(true)
