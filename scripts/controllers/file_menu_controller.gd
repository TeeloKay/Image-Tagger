class_name FileMenuController extends MenuController

@export var image_view: FileListView

## how many thumbnails are loaded per frame. Higher speeds can lead to performance hitches when loading a new folder.
@export_range(1, 100, 1) var lazy_load_speed: int = 5

var _current_dir: String = ""
var _file_paths_in_dir: PackedStringArray = []
var _lazy_load_index: int = 0
var _right_click_index: int = -1

signal image_selected(image_path: String)

func _ready() -> void:
	super._ready()
	image_view.item_selected.connect(_on_item_selected)

	FileService.file_moved.connect(_on_file_moved)
	FileService.file_removed.connect(_on_file_removed)

func set_directory(dir_path: String) -> void:
	_file_paths_in_dir.clear()
	if _current_dir != dir_path:
		_current_dir = dir_path
	show_files_in_directory(_current_dir)

func show_files_in_directory(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if !dir:
		return
	image_view.clear()
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if !dir.current_is_dir():
			var ext := file_name.get_extension()
			if ext in ImageUtil.ACCEPTED_TYPES:
				var full_path := dir_path.path_join(file_name)
				_add_item_to_list(full_path, file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
		
func _add_item_to_list(full_path: String, file_name: String) -> int:
	_file_paths_in_dir.append(full_path)
	var index: int = image_view.add_item_to_list(full_path, file_name)
	return index

func refresh() -> void:
	if _current_dir:
		show_files_in_directory(_current_dir)
	image_view.refresh()

func show_files(file_hashes: Array[String]) -> void:
	pass

func _on_file_moved(from: String, to: String) -> void:
	pass

func _on_file_removed(path: String) -> void:
	pass

func _on_thumbnail_ready(path: String, thumbnail: Texture2D) -> void:
	pass

func _on_item_selected(index: int) -> void:
	if index >= 0 && index < _file_paths_in_dir.size():
		image_selected.emit(_file_paths_in_dir[index])
