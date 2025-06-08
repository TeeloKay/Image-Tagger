@tool class_name ResponsiveItemList extends ItemList

enum ViewMode {GRID, LIST}
enum IconSizes {SMALL, MEDIUM, LARGE}

@export var list_view: FileListView
@export var view_mode: ViewMode = ViewMode.GRID:
	set = set_view_mode
@export var icon_size: IconSizes = IconSizes.MEDIUM:
	set = set_icon_size

@export_range(0,1000,1) var min_column_width: int = 128
@export_group("icon sizes")
@export var small := Vector2(64,64)
@export var medium := Vector2(96,96)
@export var large := Vector2(128,128)

var drag_start_pos := Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_view_mode()
	resized.connect(_on_resize)

func _update_view_mode() -> void:
	match view_mode:
		ViewMode.GRID:
			icon_mode = ItemList.ICON_MODE_TOP
			fixed_icon_size = _get_icon_size()
			fixed_column_width = min_column_width
			max_columns = 0
		ViewMode.LIST:
			icon_mode = ItemList.ICON_MODE_LEFT
			fixed_icon_size = _get_icon_size()
			max_columns = 1
			fixed_column_width = 0

func _on_resize() -> void:
	if view_mode == ViewMode.GRID:
		var spacing: int = get_theme_constant("h_separation", &"ItemList")
		var column_count: int = size.x / min_column_width
		max_columns = column_count
		fixed_column_width = (size.x - (column_count + 2) * spacing) / column_count

func set_view_mode(mode: ViewMode) -> void:
	view_mode = mode
	_update_view_mode()

func _get_drag_data(at_position: Vector2) -> Variant:
	var index := get_item_at_position(at_position,true)
	if index < 0:
		return null
	var abs_path := list_view.get_file_paths_in_dir()[index]
	print(list_view.get_file_paths_in_dir())
	print(index, ": ", abs_path)

	_build_drag_preview(index)
	
	var drag_data = ImageDragData.new(self,abs_path)
	return drag_data

func _build_drag_preview(index: int) -> void:
	var preview = TextureRect.new()
	preview.pivot_offset = preview.size/2
	preview.texture =  get_item_icon(index)
	preview.set_size(_get_icon_size())
	preview.modulate = Color(1,1,1,0.75)
	set_drag_preview(preview)

func set_icon_size(size: IconSizes) -> void:
	icon_size = size
	_update_view_mode()

func _get_icon_size() -> Vector2i:
	match icon_size:
		IconSizes.SMALL:
			return small
		IconSizes.MEDIUM:
			return medium
		IconSizes.LARGE:
			return large
		_: 
			return medium
