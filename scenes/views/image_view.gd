class_name ImageDataView extends VSplitContainer

@onready var file_name_label: Label = %FileName
@onready var image_preview: TextureRect = %ImagePreview
@onready var explorer_button: Button = %ExplorerButton

@onready var _tag_editor: ImageTagEditor = %ImageTagEditor

@export var current_image: String = ""
@export var current_hash: String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	explorer_button.pressed.connect(_on_explorer_button_pressed)
	ProjectManager.project_loaded.connect(_enable)

func _enable() -> void:
	explorer_button.disabled = false
	
func _disable() -> void:
	explorer_button.disabled = true

func _on_image_selected(path: String) -> void:
	# TODO: hash and cross-reference data.
	# the system should be fed a path. it should return a hash.
	current_image = path
	current_hash = ProjectManager.current_project.get_hash_for_path(path)
	
	var texture = ImageUtil.load_image(path)
	image_preview.texture = texture
	
	explorer_button.disabled = false
	file_name_label.text = path.get_file()
	
	_tag_editor.set_image_path(path)
	_tag_editor.current_image_hash = current_hash
	
func _on_explorer_button_pressed() -> void:
	if current_image.is_empty():
		return
	
	var folder_path := current_image.get_base_dir()
	OS.shell_open(folder_path)

func apply_changes() -> void:
	return
