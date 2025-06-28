class_name FileBrowserController extends MenuController

@onready var _confirm_prefab := preload("res://scenes/common/popups/confirm_dialog.tscn")

@export var image_view: FileBrowserView
@export var sort_mode: FileDataHandler.SortMode:
	set = set_sort_mode, get = get_sort_mode

@export var extension_filter: PackedStringArray = []:
	set = set_extension_filter

var _active_dialog: ConfirmationDialog
## Currently open directory.
var _current_dir: String = ""
## list of currently selected files.
var _selected_files: PackedStringArray = []

var _viewed_files: Dictionary[String, bool] = {}


var _file_loader: FileLoader
var _data_handler: FileDataHandler

var _is_loading := false
var _selection_update_pending := false

signal image_selected(image_path: String)
signal selection_changed()

func _ready() -> void:
	super._ready()

	_file_loader = FileLoader.new()
	_data_handler = FileDataHandler.new()

	image_view.item_selected.connect(_on_item_selected)
	image_view.selection_updated.connect(_on_selection_updated)

	image_view.update_request.connect(rebuild_view_from_file_list)
	image_view.sort_mode_changed.connect(set_sort_mode)
	image_view.filter_item_pressed.connect(_on_filter_item_pressed)

	_file_loader.file_loaded.connect(_register_file_data)
	_file_loader.queue_complete.connect(_on_file_loader_queue_completed)

	image_view.file_moved.connect(_on_file_move_request)
	image_view.file_remove_request.connect(_on_file_remove_request)
	image_view.file_rename_request.connect(_on_file_rename_request)

	FileService.file_removed.connect(_on_file_removed)
	FileService.file_created.connect(_on_file_created)

	ProjectManager.search_engine.search_completed.connect(show_search_results)
	# ThumbnailManager.thumbnail_ready.connect(_on_thumbnail_ready)

func _process(delta: float) -> void:
	_file_loader.process(delta)

func set_directory(dir_path: String) -> void:
	if _current_dir != dir_path:
		_current_dir = dir_path

	show_files_in_directory(_current_dir)
	image_view.set_scroll_position(Vector2i.ZERO)

func show_files_in_directory(dir_path: String) -> void:
	clear()

	_data_handler.assign_files(get_files_in_directory(dir_path))
	_file_loader.populate_queue(_data_handler.get_files_filtered(extension_filter))
	_is_loading = true
		
func show_search_results(results: Array[SearchResult]) -> void:
	clear()

	if results.is_empty():
		return
	for result in results:
		if result.image_path == "":
			_data_handler.add_file(result.image_path)
	_file_loader.populate_queue(_data_handler.get_files_filtered(extension_filter))
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
	_data_handler.register_file(path, file_data)

	if !_viewed_files.has(path) && path.get_extension() in extension_filter:
		_viewed_files[path] = true
		_add_item_to_view(path, file_data)

func _add_item_to_view(abs_path: String, file_data: FileData) -> int:
	var index: int = image_view.add_item_to_list(abs_path, file_data)
	return index

#region File events
func _on_file_move_request(from: String, to: String) -> void:
	FileService.move_file(from, to)
	rebuild_view_from_file_list()

func _on_file_removed(_path: String) -> void:
	_data_handler.remove_file(_path)
	rebuild_view_from_file_list()

func _on_file_created(_path: String) -> void:
	if _path.get_base_dir() != _current_dir:
		return
	_file_loader.add_file_to_queue(_path)
	rebuild_view_from_file_list()
#endregion

#region selection
func _on_item_selected(index: int) -> void:
	print("item selected")
	if index >= 0 && index < _data_handler.get_file_count():
		_selected_files.clear()
		_selected_files.append(_data_handler.get_files_filtered(extension_filter)[index])
		if !_selected_files.is_empty():
			image_selected.emit(_selected_files[0])
		else:
			image_selected.emit("")
		selection_changed.emit()

func _on_selection_updated() -> void:
	if _selection_update_pending:
		return
	_selection_update_pending = true
	call_deferred("_apply_selection_update")
	
func _apply_selection_update() -> void:
	_selection_update_pending = false
	_selected_files.clear()
	var selected_items := image_view.get_selected_items()
	var items := _data_handler.get_files_filtered(extension_filter)
	for idx in selected_items:
		_selected_files.append(items[idx])
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
	_data_handler.clear()
	_viewed_files.clear()

func clear_view() -> void:
	_viewed_files.clear()
	image_view.clear()

#region Getters & Setters
func set_sort_mode(mode: FileDataHandler.SortMode) -> void:
	_data_handler.sort_mode = mode
	## cannot sort while loading files
	if _file_loader.is_working():
		return
	_data_handler.sort_files()
	rebuild_view_from_file_list()

func get_sort_mode() -> FileDataHandler.SortMode:
	if _data_handler:
		return _data_handler.sort_mode
	return FileDataHandler.SortMode.SORT_BY_NAME_ASC

func set_extension_filter(filter: PackedStringArray) -> void:
	extension_filter = filter

#endregion

func rebuild_view_from_file_list() -> void:
	if _is_loading:
		return
	clear_view()

	_data_handler.sort_files()
	for file in _data_handler.get_files_filtered(extension_filter):
		_add_item_to_view(file, _data_handler.get_file_data(file))

func _on_project_reset() -> void:
	clear_selection()
	clear_view()
	_file_loader.clear_queue()
	_file_loader.clear_cache()
	_data_handler.clear()
	_viewed_files.clear()

#region UI callbacks
func _on_filter_item_pressed(id: int) -> void:
	var valid_types := ImageUtil.ACCEPTED_TYPES
	var selected_type = valid_types[id]
	var index := extension_filter.find(selected_type)
	if index == -1:
		extension_filter.append(selected_type)
	else:
		extension_filter.remove_at(index)
	rebuild_view_from_file_list()

#endregion
