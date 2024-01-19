extends Node3D

signal gltf_start_to_load
signal gltf_is_loaded(success:bool, gltf:Node)
signal fbx_start_to_load
signal fbx_is_loaded(success:bool, fbx:Node)


const Worker = preload("res://vsk_model_explorer/core/Worker.gd")
var worker: Worker
	
const gltf_vrm_extension_const = preload("res://addons/vrm/vrm_extension.gd")

var gltf_doc = GLTFDocument.new()
var gltf_vrm_extension = gltf_vrm_extension_const.new()

var fbx_doc: Object = null
# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().files_dropped.connect(_on_file_dropped)
	if ClassDB.get_class_list().find("FBXDocument") != -1:
		fbx_doc = ClassDB.instantiate("FBXDocument")


func _on_file_dropped(files:PackedStringArray):
	if files.size() == 1:
		var ext = files[0].get_extension()
		if ext == "glb" or ext == "gltf" or ext == "vrm":
			gltf_start_to_load.emit()
			
			# unload previous loaded scene
			var loaded_nodes = []
			loaded_nodes.append_array(get_tree().get_nodes_in_group(GlobalSignal.GLTF_GROUP))
			loaded_nodes.append_array(get_tree().get_nodes_in_group(GlobalSignal.FBX_GROUP))
			for n in loaded_nodes:
				n.queue_free()

			worker = Worker.new(Callable(self, "_load_gltf").bind(files[0]))
			worker.start()
			
			gltf_start_to_load.emit()
		elif ext == "fbx":
			if ClassDB.get_class_list().find("FBXDocument") == -1:
				printerr("Use the godot-ufbx branch of Godot Engine for the new FBX Importer.")
				return
			fbx_start_to_load.emit()
			
			# unload previous loaded scene
			var loaded_nodes = []
			loaded_nodes.append_array(get_tree().get_nodes_in_group(GlobalSignal.GLTF_GROUP))
			loaded_nodes.append_array(get_tree().get_nodes_in_group(GlobalSignal.FBX_GROUP))
			for n in loaded_nodes:
				n.queue_free()

			var fbx_state: Object = ClassDB.instantiate("FBXState")
			var handle_binary_image_enum: StringName  = ClassDB.class_get_integer_constant_enum("FBXState", "HANDLE_BINARY_EMBED_AS_UNCOMPRESSED")
			fbx_state.set("handle_binary_image", handle_binary_image_enum)
			var err = ERR_FILE_CANT_OPEN

			err = fbx_doc.append_data_from_file(files[0], fbx_state)
			
			var fbx:Node = null
			
			if err == OK:
				fbx = fbx_doc.create_scene(fbx_state)
				if fbx != null:
					fbx.add_to_group(GlobalSignal.FBX_GROUP)
					add_child.call_deferred(fbx)
					_emit_fbx_load.call_deferred(fbx)
				else:
					_emit_fbx_load_failed.call_deferred()
			else:
				_emit_fbx_load_failed.call_deferred()
					
			fbx_start_to_load.emit()


func _emit_fbx_load(fbx) -> void:
	fbx_is_loaded.emit(true, fbx)


func _emit_fbx_load_failed() -> void:
	fbx_is_loaded.emit(false, null)


func _load_gltf(file:String):
	var gltf_state: GLTFState = GLTFState.new()
	gltf_state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	var err = ERR_FILE_CANT_OPEN
	if file.ends_with("vrm"):
		GLTFDocument.register_gltf_document_extension(gltf_vrm_extension, true)

	err = gltf_doc.append_from_file(file, gltf_state)
	
	var gltf:Node = null
	
	if err == OK:
		gltf = gltf_doc.generate_scene(gltf_state)
		gltf.add_to_group(GlobalSignal.GLTF_GROUP)
		add_child.call_deferred(gltf)
		_emit_gltf_load.call_deferred(gltf)
	else:
		_emit_gltf_load_failed.call_deferred()

func _emit_gltf_load(gltf) -> void:
	gltf_is_loaded.emit(true, gltf)


func _emit_gltf_load_failed() -> void:
	gltf_is_loaded.emit(false, null)


func _exit_tree():
	GLTFDocument.unregister_gltf_document_extension(gltf_vrm_extension)
