extends PanelContainer

@onready var BtnClose:Button = $Row/HBoxContainer/Button
@onready var Canvas = $Row/Panel/Canvas

var _draw_data

# Called when the node enters the scene tree for the first time.
func _ready():
	BtnClose.pressed.connect(_on_btn_close_pressed)
	Canvas.set_draw_data(_draw_data)
		
func _process(_delta):
	if Input.is_action_just_released("close_popup"):
		queue_free()

func set_draw_data(data):
	_draw_data = data

func _on_btn_close_pressed():
	queue_free()
