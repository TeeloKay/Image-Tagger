class_name ThemeController extends MenuController

@export var dark_theme: Theme
@export var light_theme: Theme

@export var root: Control

func _ready() -> void:
	super._ready()
	if root:
		root.theme = light_theme
	
	
