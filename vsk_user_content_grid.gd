tool
extends Control

signal vsk_content_button_pressed(id)

export(NodePath) var grid_container_path: NodePath = NodePath()

const vsk_user_content_item_const = preload("vsk_user_content_grid_item.tscn")

func _vsk_content_button_pressed(p_id: String) -> void:
	emit_signal("vsk_content_button_pressed", p_id)

func add_item(p_id: String, p_name: String, p_url: String) -> void:
	var vsk_user_content_item: Control = vsk_user_content_item_const.instance()
	
	vsk_user_content_item.set_id(p_id)
	vsk_user_content_item.set_name(p_name)
	vsk_user_content_item.set_url(p_url)
	
	if vsk_user_content_item.connect("vsk_content_button_pressed", self, "_vsk_content_button_pressed") != OK:
		printerr("Could not connect 'vsk_content_button_pressed'")
	
	get_node(grid_container_path).add_child(vsk_user_content_item)

func clear_all() -> void:
	for child in get_node(grid_container_path).get_children():
		child.queue_free()
		child.get_parent().remove_child(child)

func _on_scroll_ended():
	pass
