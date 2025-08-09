class_name ToolController extends MenuController

const PNG := "png"
const JPG := "jpg"
const WEBP := "webp"

var type_table := {PNG: 0, JPG: 1, WEBP: 2}

@export var conversion_popup: ImageConversionPopup
@export var menu_button: MenuButton
@export var directory_controller: DirectoryController
@export var file_controller: FileBrowserController
@export var selection_manager: SelectionManager

var _image_converter: ConversionManager = null
var _format_detector: ImageFormatDetector = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()

	_format_detector = ImageFormatDetector.new()
	_image_converter = ConversionManager.new()
	add_child(_image_converter, true, INTERNAL_MODE_BACK)
	_image_converter.register_converter(PNG, ToPNGConverter.new())
	_image_converter.register_converter(JPG, ToJPGConverter.new())
	_image_converter.register_converter(WEBP, ToWebPConverter.new())

	if menu_button:
		menu_button.disabled = true
		var popup := menu_button.get_popup()
		popup.id_pressed.connect(_on_item_pressed)
		popup.clear()

		# Build conversion submenu
		var conversion_submenu := PopupMenu.new()
		popup.add_submenu_node_item("convert selection", conversion_submenu)
		conversion_submenu.add_item("Convert to png", type_table[PNG])
		conversion_submenu.add_item("Convert to jpeg", type_table[JPG])
		conversion_submenu.add_item("Convert to webp", type_table[WEBP])
		conversion_submenu.index_pressed.connect(_on_conversion_item_pressed)
		
		popup.add_item("Repair selection", 1)

func _on_conversion_item_pressed(idx: int) -> void:
	if idx > type_table.size() || idx < 0:
		return
	var type := type_table.find_key(idx) as String
	var selection := selection_manager.get_selection()
	_image_converter.enqueue_jobs(selection, type)
	_image_converter.start_processing()

func _on_item_pressed(idx: int) -> void:
	if idx == 1:
		_repair_selection()

func _repair_selection() -> void:
	var selection := file_controller.get_selection()
	for path in selection:
		var ext := path.get_extension()
		var detected_ext := _format_detector.detect_image_format(path)
		if ext.to_lower() != detected_ext.to_lower() && !detected_ext.is_empty():
			print(detected_ext)
			var image_hash := _database.get_hash_for_path(path)
			var new_path := path.get_basename() + "." + detected_ext
			FileService.move_file(path, new_path)
			_database.update_image_path(image_hash, new_path)
	
func _on_project_loaded() -> void:
	super._on_project_loaded()
	enable()

func enable() -> void:
	menu_button.disabled = false
