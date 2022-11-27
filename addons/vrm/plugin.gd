@tool
extends EditorPlugin

var import_plugin = preload("res://addons/vrm/import_vrm.gd").new()

func _enter_tree():
	add_scene_format_importer_plugin(import_plugin)


func _exit_tree():
	remove_scene_format_importer_plugin(import_plugin)
	import_plugin = null
