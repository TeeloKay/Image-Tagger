class_name ToolController extends MenuController

enum {PNG = 0, WEBP = 1, TGA = 2}

@export var conversion_popup: ImageConversionPopup
@export var menu_button: MenuButton
@export var directory_controller: DirectoryController
@export var file_controller: FileMenuController

var _image_converter : ImageConverter = null
var _strategies: Dictionary[int,ImageConversionStrategy] = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	_strategies[PNG] = ToPNGStrategy.new()
	_strategies[WEBP] = ToWebPStrategy.new()
	_image_converter = ImageConverter.new(_strategies[PNG])

	if menu_button:
		menu_button.disabled = true
		var popup := menu_button.get_popup()
		popup.clear()

		# Build conversion submenu
		var conversion_submenu := PopupMenu.new()
		popup.add_submenu_node_item("convert selection", conversion_submenu)
		conversion_submenu.add_item("Convert to png", PNG)
		conversion_submenu.add_item("Convert to webp", WEBP)
		conversion_submenu.add_item("Convert to tga", TGA)
		conversion_submenu.index_pressed.connect(_on_conversion_item_pressed)

func _on_conversion_item_pressed(idx: int) -> void:
	if _strategies.has(idx) && _strategies[idx] != null:
		_image_converter.strategy = _strategies[idx]

func _convert_selection() -> void:
	var selection := file_controller.get_selection()
	print(selection)
	for path in selection:
		_image_converter.convert(path)
	conversion_popup.popup()
	conversion_popup.set_progress(0.5)

func _on_project_loaded() -> void:
	super._on_project_loaded()
	enable()

func enable() -> void:
	menu_button.disabled = false
