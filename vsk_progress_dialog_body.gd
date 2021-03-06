tool
extends Control

signal cancel_button_pressed()

export(NodePath) var progress_label_nodepath: NodePath = NodePath()
export(NodePath) var progress_bar_nodepath: NodePath = NodePath()
export(NodePath) var cancel_button_nodepath: NodePath = NodePath()


func set_progress_label_text(p_text: String) -> void:
	get_node(progress_label_nodepath).set_text(p_text)


func set_progress_bar_value(p_value: float) -> void:
	get_node(progress_bar_nodepath).set_value(p_value)


func _on_CancelButton_pressed() -> void:
	emit_signal("cancel_button_pressed")
