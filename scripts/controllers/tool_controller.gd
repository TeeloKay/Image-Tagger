class_name ToolController extends MenuController

const PNG := "png"
const JPG := "jpg"
const WEBP := "webp"

var type_table := {PNG: 0, JPG: 1, WEBP: 2}

const CONVERT_SUBMENU := 0
const REPAIR := 1

@export var conversion_popup: ImageConversionPopup
@export var menu_button: MenuButton
@export var directory_controller: DirectoryController
@export var file_controller: FileBrowserController
@export var selection_manager: SelectionManager

@export var _image_converter: ConversionManager = null
var _format_detector: ImageFormatDetector = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	_format_detector = ImageFormatDetector.new()

	if _image_converter:
		_image_converter.register_converter(PNG, ToPNGConverter.new())
		_image_converter.register_converter(JPG, ToJPGConverter.new())
		_image_converter.register_converter(WEBP, ToWebPConverter.new())
		_image_converter.conversion_ended.connect(func() -> void: file_controller.update_view())

	if menu_button:
		_build_menu()

func _on_conversion_item_pressed(idx: int) -> void:
	if idx > type_table.size() || idx < 0:
		return
	var type := type_table.find_key(idx) as String
	var selection := selection_manager.get_selection()
	_image_converter.enqueue_jobs(selection, type)
	_image_converter.start_processing()

func _on_item_pressed(idx: int) -> void:
	if idx == REPAIR:
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

func _build_menu() -> void:
	menu_button.disabled = true
	var popup := menu_button.get_popup()
	popup.id_pressed.connect(_on_item_pressed)
	popup.clear()

	# Build conversion submenu
	var conversion_submenu := PopupMenu.new()
	popup.add_submenu_node_item("convert selection", conversion_submenu, CONVERT_SUBMENU)
	conversion_submenu.add_item("Convert to png", type_table[PNG])
	conversion_submenu.add_item("Convert to jpeg", type_table[JPG])
	conversion_submenu.add_item("Convert to webp", type_table[WEBP])
	conversion_submenu.index_pressed.connect(_on_conversion_item_pressed)
	popup.set_item_disabled(CONVERT_SUBMENU, _image_converter == null)
	
	# Add repair selection option
	popup.add_item("Repair selection", REPAIR)
	popup.set_item_disabled(REPAIR, _format_detector == null)
