extends Node3D

const ZOOM_FACTOR = 1.2
const ROTATE_SPEED = 0.1
const PAN_SPEED = 0.005

@export var UiNode: Control

@onready var CamRotHelper = $CamRotHelper

var enable_cam_control: bool = true

func _ready():
	var _discard = UiNode.connect("mouse_entered", _ui_mouse_entered)
	_discard = UiNode.connect("mouse_exited", _ui_mouse_exited)
	
	GlobalSignal.reposition_camera.connect(_on_reposition_camera)
	
func _ui_mouse_entered():
	enable_cam_control = false
	
func _ui_mouse_exited():
	enable_cam_control = true
	
func _on_reposition_camera(aabb:AABB):
	if aabb.size.length() > 0:
		scale = Vector3.ONE * (aabb.size.length() * 0.2)
	else:
		scale = Vector3.ONE
		
	rotation = Vector3.ZERO
	CamRotHelper.rotation = Vector3.ZERO

func _unhandled_input(event):
	if not enable_cam_control:
		return
		
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_RIGHT:
			# Rotate
			self.rotate_y(deg_to_rad(-1 * event.get_relative().x * ROTATE_SPEED))
			CamRotHelper.rotate_x(deg_to_rad(-1 * event.get_relative().y * ROTATE_SPEED))

			#Stop rotation over top or bottom
			var camera_rot = CamRotHelper.rotation
			camera_rot.x = clamp(camera_rot.x, -90, 90)
			CamRotHelper.rotation = camera_rot
		elif event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			# Pan
			self.translate(Vector3(
				-1 * event.get_relative().x * PAN_SPEED,
				event.get_relative().y * PAN_SPEED,
				0.0
			))
	elif event is InputEventMouseButton and event.is_pressed():
		# Zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			self.scale_object_local(Vector3.ONE * (ZOOM_FACTOR))
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			self.scale_object_local(Vector3.ONE * (1/ZOOM_FACTOR))


func _on_root_gltf_is_loaded(_success, _gltf):
	# Reset camera local scale
	scale = Vector3.ONE
	rotation.y = 0
	CamRotHelper.rotation.x = 0
