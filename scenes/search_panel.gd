class_name SearchPanel extends VBoxContainer

@onready var search_input: LineEdit = %SearchInput
@onready var search_button: Button = %SearchButton

signal results_ready(image_paths: PackedStringArray)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	search_button.pressed.connect(_on_search_pressed)
	search_input.text_submitted.connect(_on_search)

func _on_search(_query: String) -> void:
	_on_search_pressed()

func _on_search_pressed() -> void:
	var results := ProjectManager.search_images(search_input.text)
	results_ready.emit(results)
