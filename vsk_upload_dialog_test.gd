extends Control

const vsk_types_const = preload("res://addons/vsk_importer_exporter/vsk_types.gd")

func export_data() -> Dictionary:
	return {}

func _on_ShowDialogButton_pressed():
	var func_ref: FuncRef = FuncRef.new()
	func_ref.set_instance(self)
	func_ref.set_function("export_data")
	
	VSKEditor.show_upload_panel(func_ref, vsk_types_const.UserContentType.Avatar)

func _ready():
	VSKEditor.setup_user_interfaces(self, null, null)
	
static func generate_test_image() -> Dictionary:
	var new_image: Image = Image.new()
	new_image.resize(128, 128,Image.INTERPOLATE_NEAREST)
	
	return  {"filename":"autogen.png", "content_type":"image/png", "data":new_image.save_png_to_buffer()}
	
static func generate_test_binary_data() -> Dictionary:
	var data: PoolByteArray = "TestBinary".to_utf8()
	
	return {"filename":"autogen.scn", "content_type":"application/octet-stream", "data":data}

func _on_TestUploadButton_pressed():
	if GodotUro.godot_uro_api:
		var result = yield(
			GodotUro.godot_uro_api.dashboard_create_avatar_async(
			{
				"name":"test_avatar",
				"description":"test_avatar_description",
				"user_content_data":generate_test_binary_data(),
				"user_content_preview":generate_test_image()
			}), "completed"
		)
		
		print(result)
