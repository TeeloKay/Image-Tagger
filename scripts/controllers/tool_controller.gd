class_name ToolController extends MenuController

enum {PNG = 0, WEBP = 1, JPEG = 2}

@export var conversion_popup: ImageConversionPopup
@export var menu_button: MenuButton
@export var directory_controller: DirectoryController
@export var file_controller: FileBrowserController

var _image_converter: ImageConverter = null
var _format_detector: ImageFormatDetector = null
var _strategies: Dictionary[int, ImageConversionStrategy] = {}

signal conversion_started
signal conversion_ended
signal conversion_progressed(current: String, completed: int, total: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	_strategies[PNG] = ToPNGStrategy.new()
	_strategies[WEBP] = ToWebPStrategy.new()
	_strategies[JPEG] = ToJPEGStrategy.new()
	_image_converter = ImageConverter.new(_strategies[PNG])
	_format_detector = ImageFormatDetector.new()

	if menu_button:
		menu_button.disabled = true
		var popup := menu_button.get_popup()
		popup.id_pressed.connect(_on_item_pressed)
		popup.clear()

		# Build conversion submenu
		var conversion_submenu := PopupMenu.new()
		popup.add_submenu_node_item("convert selection", conversion_submenu)
		conversion_submenu.add_item("Convert to png", PNG)
		conversion_submenu.add_item("Convert to webp", WEBP)
		conversion_submenu.add_item("Convert to jpeg", JPEG)
		conversion_submenu.index_pressed.connect(_on_conversion_item_pressed)
		
		popup.add_item("Repair selection",1)

func _on_conversion_item_pressed(idx: int) -> void:
	print(idx)
	if _strategies.has(idx) && _strategies[idx] != null:
		_image_converter.strategy = _strategies[idx]
	_convert_selection()

func _on_item_pressed(idx: int) -> void:
	if idx == 1:
		_repair_selection()

func _convert_selection() -> void:
	var selection := file_controller.get_selection()
	print(selection)

	var completed: int = 0
	var total := selection.size()
	conversion_popup.popup()
	conversion_started.emit()

	for path in selection:
		var new_path := _image_converter.convert(path)
		if new_path != null && !new_path.is_empty():
			var old_hash := _project_data.get_hash_for_path(path)
			var new_hash := _project_data.get_hash_for_path(new_path, true)

			print("old hash: ", old_hash)
			print("new_hash: ", new_hash)

			var image_data := _project_data.get_image_data(old_hash)
			print(image_data.tags)
			for tag in image_data.tags:
				_project_data.image_db.add_tag_to_image(new_hash,tag)
			_project_data.image_db.update_image_path(new_hash,new_path)
			_project_data.image_db.remove_image(old_hash)

			FileService.remove_file(path)
		completed += 1
		conversion_progressed.emit(path, completed, total)
		conversion_popup.update_progress(path, completed, total)
	
	conversion_ended.emit()
	conversion_popup.hide()
	file_controller.update()
	
	ProjectManager.save_current_project()

func _repair_selection() -> void:
	var selection := file_controller.get_selection()
	for path in selection:
		var ext := path.get_extension()
		var detected_ext := _format_detector.detect_image_format(path)
		if ext.to_lower() != detected_ext.to_lower() && !detected_ext.is_empty():
			print(detected_ext)
			var image_hash := _project_data.get_hash_for_path(path)
			var new_path := path.get_basename() + "." + detected_ext
			FileService.move_file(path,new_path)
			_project_data.image_db.update_image_path(image_hash, new_path)
	
func _on_project_loaded() -> void:
	super._on_project_loaded()
	enable()

func enable() -> void:
	menu_button.disabled = false
