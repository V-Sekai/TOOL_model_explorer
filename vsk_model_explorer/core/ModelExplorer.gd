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
	
	# Check for command-line arguments (files opened via file association)
	call_deferred("_check_command_line_args")


func _check_command_line_args():
	# Get command-line arguments (excludes engine-specific args)
	var args = OS.get_cmdline_user_args()
	
	# Also check all command-line args in case user args don't capture it
	if args.is_empty():
		var all_args = OS.get_cmdline_args()
		for arg in all_args:
			# Skip engine-specific arguments
			if arg.begins_with("--") or arg.begins_with("-"):
				continue
			# Remove quotes that might wrap file paths
			var clean_arg = arg.strip_edges().trim_prefix("\"").trim_suffix("\"")
			# Check if it's a file path
			if FileAccess.file_exists(clean_arg):
				args.append(clean_arg)
				break
	
	# Process the first valid file argument
	for arg in args:
		# Remove quotes that might wrap file paths
		var file_path = arg.strip_edges().trim_prefix("\"").trim_suffix("\"")
		
		# Convert to absolute path if needed
		if not file_path.is_absolute_path():
			file_path = ProjectSettings.globalize_path(file_path)
		
		# Verify the file exists and has a supported extension
		if FileAccess.file_exists(file_path):
			var ext = file_path.get_extension().to_lower()
			if ext == "glb" or ext == "gltf" or ext == "vrm" or ext == "fbx":
				_load_file(file_path)
				break


func _on_file_dropped(files:PackedStringArray):
	if files.size() == 1:
		_load_file(files[0])


func _load_file(file_path: String):
	# Normalize the file path
	var normalized_path = file_path
	if not normalized_path.is_absolute_path():
		normalized_path = ProjectSettings.globalize_path(normalized_path)
	
	# Verify file exists
	if not FileAccess.file_exists(normalized_path):
		printerr("File not found: ", normalized_path)
		return
	
	var ext = normalized_path.get_extension().to_lower()
	
	if ext == "glb" or ext == "gltf" or ext == "vrm":
		gltf_start_to_load.emit()
		
		# unload previous loaded scene
		var loaded_nodes = []
		loaded_nodes.append_array(get_tree().get_nodes_in_group(GlobalSignal.GLTF_GROUP))
		loaded_nodes.append_array(get_tree().get_nodes_in_group(GlobalSignal.FBX_GROUP))
		for n in loaded_nodes:
			n.queue_free()

		worker = Worker.new(Callable(self, "_load_gltf").bind(normalized_path))
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

		err = fbx_doc.append_data_from_file(normalized_path, fbx_state)
		
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
	else:
		printerr("Unsupported file format: ", ext)


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
