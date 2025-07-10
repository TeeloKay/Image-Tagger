@tool class_name ResponsiveItemList extends ItemList

enum ViewMode {GRID, LIST}

@export var list_view: FileBrowserView
@export var view_mode: ViewMode = ViewMode.GRID:
	set = set_view_mode

@export_range(0,1000,1) var min_column_width: int = 128
@export var icon_size := Vector2i(64,64)

var drag_start_pos := Vector2.ZERO

var drag_preview := preload("res://scenes/common/image_drag_preview.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	resized.connect(_on_resize)

func _on_resize() -> void:
	if view_mode == ViewMode.GRID:
		var spacing: int = get_theme_constant("h_separation", &"ItemList")
		var column_count := int(size.x / (min_column_width + spacing))
		max_columns = column_count
		fixed_column_width = (size.x - (column_count) * spacing) / column_count

func set_view_mode(mode: ViewMode) -> void:
	view_mode = mode
	_update_view_mode()

func set_icon_size(size: Vector2i) -> void:
	icon_size = size
	_update_view_mode()

func _get_icon_size() -> Vector2i:
	return icon_size

func _update_view_mode() -> void:
	match view_mode:
		ViewMode.GRID:
			icon_mode = ItemList.ICON_MODE_TOP
			fixed_icon_size = icon_size
			fixed_column_width = min_column_width
			max_columns = 0
		ViewMode.LIST:
			icon_mode = ItemList.ICON_MODE_LEFT
			fixed_icon_size = icon_size
			max_columns = 1
			fixed_column_width = 0

#region Drag and Drop
func _get_drag_data(at_position: Vector2) -> Variant:
	var index := get_item_at_position(at_position,true)
	if index < 0:
		return null
	var files := list_view.get_selected_item_paths()

	_build_drag_preview(index, files)
	
	var drag_data := ImageDragData.new(self, files)
	return drag_data

func _build_drag_preview(index: int, files: PackedStringArray) -> void:
	var preview := TextureRect.new()
	preview 				= drag_preview.instantiate() as ImageDragPreview
	preview.pivot_offset 	= preview.size/2
	preview.texture 		=  get_item_icon(index)
	preview.modulate 		= Color(1,1,1,0.75)
	preview.files 			= files.size()
	
	preview.set_size(_get_icon_size())
	set_drag_preview(preview)	

#endregion
