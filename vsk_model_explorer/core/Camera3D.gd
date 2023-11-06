extends Camera3D

const ZOOM_FACTOR = 1.2
const ROTATE_SPEED = 0.5
const PAN_SPEED = 0.005

func _ready():
	pass # Replace with function body.

func _input(event):
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			# Rotate
			self.rotate_y(deg_to_rad(event.get_relative().x * ROTATE_SPEED))
			$CamRotHelper.rotate_x(deg_to_rad(event.get_relative().y * ROTATE_SPEED))

			#Stop rotation over top or bottom
			var camera_rot = $CamRotHelper.rotation_degrees
			camera_rot.x = clamp(camera_rot.x, -90, 90)
			$CamRotHelper.rotation_degrees = camera_rot
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			# Pan
			self.translate(Vector3(
				event.get_relative().x * PAN_SPEED,
				event.get_relative().y * PAN_SPEED,
				0.0
			))
	elif event is InputEventMouseButton and event.is_pressed():
		# Zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			self.scale_object_local(Vector3.ONE * (ZOOM_FACTOR))
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			self.scale_object_local(Vector3.ONE * (1/ZOOM_FACTOR))

