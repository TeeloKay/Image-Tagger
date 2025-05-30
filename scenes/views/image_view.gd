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
	current_hash = ProjectManager.image_hasher.hash_image(path)
	var abs_path := ProjectManager.current_project.to_abolute_path(current_image)
	var img = Image.new()
	var err = img.load(path)
	if err != OK:
		push_warning("Failed to load full image for preview: %s" % path)
		return
	
	var tex = ImageTexture.create_from_image(img)
	image_preview.texture = tex
	explorer_button.disabled = false
	file_name_label.text = path.get_file()
	
	_tag_editor.set_image_path(path)

func _on_explorer_button_pressed() -> void:
	if current_image.is_empty():
		return
	
	var folder_path := current_image.get_base_dir()
	OS.shell_open(folder_path)
