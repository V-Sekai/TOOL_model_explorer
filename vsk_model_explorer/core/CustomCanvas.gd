extends Control

class_name CustomCanvas

var _drawData;

func set_draw_data(data):
	_drawData = data
	queue_redraw()

func _draw():
	if _drawData is ImageTexture:
		draw_texture_rect_region(_drawData, get_rect(), Rect2(Vector2.ZERO, _drawData.get_size()))
	elif _drawData is PackedVector2Array:
		draw_set_transform(Vector2.ZERO, 0, size)
		draw_multiline(_drawData, Color.WHITE)
