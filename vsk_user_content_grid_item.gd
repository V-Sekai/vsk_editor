tool
extends Control

signal vsk_content_button_pressed(id)

export(NodePath) var name_label_path: NodePath = NodePath()
export(NodePath) var texture_rect_url_path: NodePath = NodePath()

var id: String = ""
var vsk_name: String = ""
var vsk_url: String = ""

func set_id(p_id: String) -> void:
	id = p_id

func set_name(p_name: String) -> void:
	vsk_name = p_name
	var label: Label = get_node_or_null(name_label_path)
	if label:
		label.set_text(vsk_name)

func set_url(p_url: String) -> void:
	vsk_url = p_url
	var texture_rect: TextureRect = get_node_or_null(texture_rect_url_path)
	if texture_rect:
		texture_rect.textureUrl = p_url

func _ready():
	set_name(vsk_name)
	set_url(vsk_url)


func _on_pressed():
	emit_signal("vsk_content_button_pressed", id)
