class_name FileMenuController extends MenuController

enum SortMode {
	SORT_BY_NAME_ASC,
	SORT_BY_NAME_DESC,
	SORT_BY_SIZE_ASC,
	SORT_BY_SIZE_DESC,
	SORT_BY_DATE_ASC,
	SORT_BY_DATE_DESC,
	SORT_BY_TYPE_ASC,
	SORT_BY_TYPE_DESC
}

@onready var _confirm_prefab := preload("res://scenes/common/popups/confirm_dialog.tscn")
@onready var _file_loader: FileLoader = %FileLoader

@export var image_view: FileListView

var _active_dialog: ConfirmationDialog

@export var sort_mode: SortMode = SortMode.SORT_BY_NAME_ASC:
	set = set_sort_mode

@export var extension_filter: PackedStringArray = ImageUtil.ACCEPTED_TYPES:
	set = set_extension_filter

## Currently open directory.
var _current_dir: String = ""
## Array of file paths in the current directory or search result.
var _files: Array[String] = []
## Dictionary of image meta data.
var _file_data: Dictionary[String, FileData] = {}
## list of currently selected files.
var _selected_files: PackedStringArray = []

var _viewed_files: Dictionary[String, bool] = {}

var _is_loading := false

signal image_selected(image_path: String)
signal selection_changed()

func _ready() -> void:
	super._ready()

	image_view.item_selected.connect(_on_item_selected)
	image_view.selection_updated.connect(_on_selection_updated)
	image_view.update_request.connect(rebuild_view_from_file_list)
	image_view.file_moved.connect(_on_file_move_request)
	image_view.file_remove_request.connect(_on_file_remove_request)
	image_view.file_rename_request.connect(_on_file_rename_request)
	image_view.sort_mode_changed.connect(set_sort_mode)

	_file_loader.file_loaded.connect(_register_file_data)
	_file_loader.queue_complete.connect(_on_file_loader_queue_completed)

	FileService.file_removed.connect(_on_file_removed)
	FileService.file_created.connect(_on_file_created)

	ProjectManager.search_engine.search_completed.connect(show_search_results)
	# ThumbnailManager.thumbnail_ready.connect(_on_thumbnail_ready)

func set_directory(dir_path: String) -> void:
	if _current_dir != dir_path:
		_current_dir = dir_path

	show_files_in_directory(_current_dir)
	image_view.set_scroll_position(Vector2i.ZERO)

func show_files_in_directory(dir_path: String) -> void:
	clear()

	_files.assign(get_files_in_directory(dir_path))
	_file_loader.populate_queue(_files)
	_is_loading = true
		
func show_search_results(results: Array[SearchResult]) -> void:
	clear()

	if results.is_empty():
		return
	for result in results:
		if result.image_path == "":
			_files.append(result)
	_file_loader.populate_queue(_files)
	_is_loading = true

func get_files_in_directory(dir_path: String) -> PackedStringArray:
	var dir = DirAccess.open(dir_path)
	var files: PackedStringArray = []
	if !dir:
		return files
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if !dir.current_is_dir() && ImageUtil.is_valid_image(file_name):
			files.append(dir_path.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

	return files

func _register_file_data(path: String, file_data: FileData) -> void:
	_file_data[path] = file_data
	# _add_item_to_view(path, file_data)

	if !_viewed_files.has(path) && path.get_extension() in extension_filter:
		_viewed_files[path] = true
		_add_item_to_view(path, file_data)

func _add_item_to_view(abs_path: String, file_data: FileData) -> int:
	var index: int = image_view.add_item_to_list(abs_path, file_data)
	return index

func _sort_files() -> void:
	match sort_mode:
		SortMode.SORT_BY_NAME_ASC:
			_files.sort_custom(func(a, b): return _file_data[a].name < _file_data[b].name)
		SortMode.SORT_BY_NAME_DESC:
			_files.sort_custom(func(a, b): return _file_data[a].name > _file_data[b].name)
	
		SortMode.SORT_BY_SIZE_ASC:
			_files.sort_custom(func(a, b): return _file_data[a].size < _file_data[b].size)
		SortMode.SORT_BY_SIZE_DESC:
			_files.sort_custom(func(a, b): return _file_data[a].size > _file_data[b].size)
	
		SortMode.SORT_BY_DATE_ASC:
			_files.sort_custom(func(a, b): return _file_data[a].modified < _file_data[b].modified)
		SortMode.SORT_BY_DATE_DESC:
			_files.sort_custom(func(a, b): return _file_data[a].modified > _file_data[b].modified)
		
		SortMode.SORT_BY_TYPE_ASC:
			_files.sort_custom(func(a, b): return _file_data[a].get_extension() < _file_data[b].get_extension())
		SortMode.SORT_BY_TYPE_DESC:
			_files.sort_custom(func(a, b): return _file_data[a].get_extension() > _file_data[b].get_extension())

#region File events
func _on_file_move_request(from: String, to: String) -> void:
	FileService.move_file(from, to)
	rebuild_view_from_file_list()

func _on_file_moved(_from: String, _to: String) -> void:
	rebuild_view_from_file_list()

func _on_file_removed(_path: String) -> void:
	rebuild_view_from_file_list()

func _on_file_created(_path: String) -> void:
	rebuild_view_from_file_list()
#endregion

#region selection
func _on_item_selected(index: int) -> void:
	if index >= 0 && index < _files.size():
		_selected_files.clear()
		_selected_files.append(_files[index])
		if !_selected_files.is_empty():
			image_selected.emit(_selected_files[0])
		else:
			image_selected.emit("")
		selection_changed.emit()

func _on_selection_updated() -> void:
	_selected_files.clear()
	var selected_items := image_view.get_selected_items()
	for idx in selected_items:
		_selected_files.append(_files[idx])
	image_selected.emit(_selected_files[0])
	selection_changed.emit()

func clear_selection() -> void:
	_selected_files.clear()
	image_selected.emit("")
	selection_changed.emit()
#endregion

#region file operations
func _on_file_remove_request() -> void:
	if _selected_files.size() > 0:
		_active_dialog = _confirm_prefab.instantiate() as ConfirmationDialog
		add_child(_active_dialog)
		_active_dialog.title = "Delete file(s)"
		_active_dialog.dialog_text = "Are you certain you want to delete all %d files? This cannot be undone." % _selected_files.size()
		_active_dialog.confirmed.connect(_on_file_remove_confirmation)
		_active_dialog.get_cancel_button().pressed.connect(_on_request_cancelled)
		_active_dialog.popup_centered()

func _on_file_remove_confirmation() -> void:
	for file in _selected_files:
		var img_hash = _project_data.get_hash_for_path(file)
		_project_data.image_db.remove_image(img_hash)
		FileService.remove_file(file)
	rebuild_view_from_file_list()
	image_selected.emit("")

func _on_file_rename_request() -> void:
	if _selected_files.size() > 0:
		print("requesting file renaming")

func get_selection() -> PackedStringArray:
	return _selected_files

func _on_request_cancelled() -> void:
	if _active_dialog:
		_active_dialog.queue_free()

#endregion

func _on_file_loader_queue_completed() -> void:
	_is_loading = false
	rebuild_view_from_file_list()

func clear() -> void:
	clear_selection()
	clear_view()
	_file_loader.clear_queue()
	_files.clear()
	_file_data.clear()
	_viewed_files.clear()

func clear_view() -> void:
	_viewed_files.clear()
	image_view.clear()

func set_sort_mode(mode: SortMode) -> void:
	sort_mode = mode
	## cannot sort while loading files
	if _file_loader.is_working():
		return
	_sort_files()
	rebuild_view_from_file_list()

func set_extension_filter(filter: PackedStringArray) -> void:
	extension_filter = filter

func rebuild_view_from_file_list() -> void:
	clear_view()

	_sort_files()
	for file in _files:
		if file in _file_data && file.get_extension() in extension_filter:
			_add_item_to_view(file, _file_data[file])

func _on_project_reset() -> void:
	clear_selection()
	clear_view()
	_file_loader.clear_queue()
	_file_loader.clear_cache()
	_files.clear()
	_file_data.clear()
	_viewed_files.clear()
