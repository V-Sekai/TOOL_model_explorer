extends Node3D

signal gltf_start_to_load
signal gltf_is_loaded(success:bool, gltf:Node)

const Worker = preload("res://script/Worker.gd")
var worker: Worker
	
const gltf_vrm_extension_const = preload("res://addons/vrm/vrm_extension.gd")

var gltf_doc = GLTFDocument.new()
var gltf_vrm_extension = gltf_vrm_extension_const.new()
	
# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().files_dropped.connect(_on_file_dropped)

func _on_file_dropped(files:PackedStringArray):
	if files.size() == 1:
		var ext = files[0].get_extension()
		if ext == "glb" or ext == "gltf" or ext == "vrm":
			gltf_start_to_load.emit()
			
			# unload previous loaded scene
			var gltf_nodes = get_tree().get_nodes_in_group(GlobalSignal.GLTF_GROUP)
			for n in gltf_nodes:
				n.queue_free()

			worker = Worker.new(Callable(self, "_load_gltf").bind(files[0]))
			worker.start()
			
			gltf_start_to_load.emit()


func _load_gltf(file:String):
	var gltf_state: GLTFState = GLTFState.new()
	gltf_state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	if file.ends_with("vrm"):
		GLTFDocument.register_gltf_document_extension(gltf_vrm_extension, true)
	
	var err = gltf_doc.append_from_file(file, gltf_state)
	
	var success = false
	var gltf:Node = null
	
	if err == OK:
		success = true
		gltf = gltf_doc.generate_scene(gltf_state)
		gltf.add_to_group(GlobalSignal.GLTF_GROUP)
		call_deferred("add_child", gltf)
	
	gltf_is_loaded.emit(success, gltf)

func _exit_tree():
	GLTFDocument.unregister_gltf_document_extension(gltf_vrm_extension)
