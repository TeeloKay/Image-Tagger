class_name ThemeController extends MenuController

@export var dark_theme: Theme
@export var light_theme: Theme

@export var toggle: CheckButton
@export var root: Control

@export var dark_mode: bool = true:
	set = set_dark_mode

func _ready() -> void:
	super._ready()
	toggle.button_pressed = dark_mode
	toggle.toggled.connect(set_dark_mode)
	
func set_dark_mode(mode: bool) -> void:
	dark_mode = mode
	if root:
		root.theme = dark_theme if dark_mode else light_theme