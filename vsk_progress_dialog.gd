tool
extends PopupDialog


signal cancel_button_pressed()

export(NodePath) var progress_dialog_body: NodePath = NodePath()

func set_progress_bar_value(p_value: float) -> void:
	get_node(progress_dialog_body).set_progress_bar_value(p_value)


func set_progress_label_text(p_text: String) -> void:
	get_node(progress_dialog_body).set_progress_label_text(p_text)


func _on_cancel_button_pressed() -> void:
	emit_signal("cancel_button_pressed")
