class_name FileMenuController extends MenuController

@export var image_view: FileListView
@export var delete_popup: ConfirmationDialog

## how many thumbnails are loaded per frame. Higher speeds can lead to performance hitches when loading a new folder.
@export_range(1, 100, 1) var lazy_load_speed: int = 5

var _current_dir: String = ""
var _file_paths_in_dir: PackedStringArray = []
var _selected_files: PackedStringArray = []
var _right_click_index: int = -1

signal image_selected(image_path: String)

func _ready() -> void:
	super._ready()

	image_view.item_selected.connect(_on_item_selected)
	image_view.selection_updated.connect(_on_selection_updated)
	image_view.update_request.connect(update)
	image_view.file_moved.connect(_on_file_move_request)
	image_view.file_remove_request.connect(_on_file_remove_request)
	image_view.file_rename_request.connect(_on_file_rename_request)

	delete_popup.confirmed.connect(_on_file_remove_confirmation)

	FileService.file_moved.connect(_on_file_moved)
	FileService.file_removed.connect(_on_file_removed)
	FileService.file_created.connect(_on_file_created)

	ProjectManager.search_engine.search_completed.connect(show_search_results)
	ThumbnailManager.thumbnail_ready.connect(_on_thumbnail_ready)
	
	delete_popup.hide()

func set_directory(dir_path: String) -> void:
	if _current_dir != dir_path:
		_current_dir = dir_path
	ThumbnailManager.clear_queue()
	show_files_in_directory(_current_dir)

func show_files_in_directory(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if !dir:
		return
	_file_paths_in_dir.clear()
	image_view.clear()
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if !dir.current_is_dir():
			var ext := file_name.get_extension()
			if ext in ImageUtil.ACCEPTED_TYPES:
				var abs_path := dir_path.path_join(file_name)
				_add_item_to_list(abs_path, file_name)
				ThumbnailManager.queue_thumbnail(abs_path)
		file_name = dir.get_next()
	dir.list_dir_end()
		
func show_search_results(results: Array[SearchResult]) -> void:
	print(results)
	_file_paths_in_dir.clear()
	image_view.clear()
	if results.is_empty():
		return
	for result in results:
		if result.image_path == "":
			continue
		var abs_path := ProjectManager.to_abolute_path(result.image_path)
		print(result.image_path)
		_add_item_to_list(abs_path, result.file_name)
		ThumbnailManager.queue_thumbnail(abs_path)

func _add_item_to_list(abs_path: String, file_name: String) -> int:
	_file_paths_in_dir.append(abs_path)
	var index: int = image_view.add_item_to_list(abs_path, file_name)
	return index

func update() -> void:
	if _current_dir:
		show_files_in_directory(_current_dir)
	image_view.update()
 
func _on_file_move_request(from: String, to: String) -> void:
	FileService.move_file(from, to)
	update()

func _on_file_moved(_from: String, _to: String) -> void:
	update()

func _on_file_removed(_path: String) -> void:
	pass

func _on_file_created(_path: String) -> void:
	update()

func _on_thumbnail_ready(path: String, thumbnail: Texture2D) -> void:
	var index := _file_paths_in_dir.find(path)
	image_view.set_item_thumbnail(index, thumbnail)

func _on_item_selected(index: int) -> void:
	if index >= 0 && index < _file_paths_in_dir.size():
		_selected_files.clear()
		_selected_files.append(_file_paths_in_dir[index])
		image_selected.emit(_selected_files[0])

func _on_selection_updated() -> void:
	_selected_files.clear()
	var selected_items := image_view.get_selected_items()
	for idx in selected_items:
		_selected_files.append(_file_paths_in_dir[idx])
	image_selected.emit(_selected_files[0])

func _on_file_remove_request() -> void:
	if _selected_files.size() > 0:
		delete_popup.popup_centered()

func _on_file_remove_confirmation() -> void:
	for file in _selected_files:
		var img_hash = _project_data.get_hash_for_path(file)
		_project_data.image_db.remove_image(img_hash)
		FileService.remove_file(file)
	update()
	image_selected.emit("")

func _on_file_rename_request() -> void:
	if _selected_files.size() > 0:
		print("requesting file renaming")

func get_selection() -> PackedStringArray:
	return _selected_files
