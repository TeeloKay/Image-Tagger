extends Node

const CONFIG_PATH 	:= "user://settings.cfg"
const UI 			:= "UI"
const PREFERENCES	:= "PREFERENCES"

var _cfg: ConfigFile = null

var save_thumbs: bool = false

signal config_loaded
signal config_saved

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_cfg = ConfigFile.new()
	var err := _cfg.load(CONFIG_PATH)
	if err != OK:
		push_warning("failed to load project config file.")
		return
	load_config()


func load_config() -> void:
	save_thumbs = _cfg.get_value(UI, "save_thumbnails", false) as bool
	config_loaded.emit()


func save_config() -> void:
	_cfg.save(CONFIG_PATH)
	config_saved.emit()


func _exit_tree() -> void:
	save_config()