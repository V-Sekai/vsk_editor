extends Control
tool

signal session_request_successful()

const MARGIN_SIZE = 32

var vbox_container: VBoxContainer = null

var sign_in_label: Label = null

var sign_in_vbox_container: VBoxContainer = null
var username_or_email_label: Label = null
var username_or_email_lineedit: LineEdit = null
var password_label: Label = null
var password_lineedit: LineEdit = null

var submit_button: Button = null
var result_label: Label = null


func _session_request_submitted() -> void:
	username_or_email_lineedit.editable = false
	password_lineedit.editable = false

	submit_button.disabled = true


func _session_request_complete(p_result: int, p_message: String) -> void:
	username_or_email_lineedit.editable = true
	password_lineedit.editable = true

	submit_button.disabled = false

	result_label.set_text(p_message)

	if p_result == GodotUro.godot_uro_helper_const.RequesterCode.OK:
		emit_signal("session_request_successful")
	else:
		password_lineedit.text = ""
	

func _submit_button_pressed() -> void:
	var username_or_email: String = username_or_email_lineedit.text
	var password: String = password_lineedit.text

	_session_request_submitted()
	VSKEditor.sign_in(username_or_email, password)
		
	
func _init() -> void:
	vbox_container = VBoxContainer.new()
	vbox_container.alignment = VBoxContainer.ALIGN_BEGIN

	add_child(vbox_container)

	sign_in_label = Label.new()
	sign_in_label.set_text("")
	sign_in_label.align = Label.ALIGN_CENTER
	vbox_container.add_child(sign_in_label)

	sign_in_vbox_container = VBoxContainer.new()
	sign_in_vbox_container.alignment = VBoxContainer.ALIGN_CENTER
	sign_in_vbox_container.size_flags_vertical = SIZE_EXPAND_FILL

	username_or_email_label = Label.new()
	username_or_email_label.set_text("Email/Username")

	username_or_email_lineedit = LineEdit.new()

	password_label = Label.new()
	password_label.set_text("Password")

	password_lineedit = LineEdit.new()
	password_lineedit.secret = true

	sign_in_vbox_container.add_child(username_or_email_label)
	sign_in_vbox_container.add_child(username_or_email_lineedit)
	sign_in_vbox_container.add_child(password_label)
	sign_in_vbox_container.add_child(password_lineedit)

	vbox_container.add_child(sign_in_vbox_container)

	submit_button = Button.new()
	submit_button.set_text("Submit")
	submit_button.connect("pressed", self, "_submit_button_pressed")

	vbox_container.add_child(submit_button)

	result_label = Label.new()
	result_label.set_text("")
	result_label.align = HALIGN_CENTER
	vbox_container.add_child(result_label)

	vbox_container.set_anchors_and_margins_preset(PRESET_WIDE, PRESET_MODE_MINSIZE, 0)
	vbox_container.margin_top = 0
	vbox_container.margin_left = MARGIN_SIZE
	vbox_container.margin_bottom = -MARGIN_SIZE
	vbox_container.margin_right = -MARGIN_SIZE

	VSKEditor.connect("session_request_complete", self, "_session_request_complete")
