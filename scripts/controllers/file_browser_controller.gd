class_name FileBrowserController extends MenuController

@onready var _confirm_prefab := preload("res://scenes/common/popups/confirm_dialog.tscn")

## Currently open directory.
@export_global_dir var directory: String = "":
	set = set_directory

@export var image_view: FileBrowserView
@export var sort_mode: FileDataHandler.SortMode:
	set = set_sort_mode, get = get_sort_mode

@export var extension_filter: PackedStringArray = []:
	set = set_extension_filter

@export_category("Dependencies")
var _active_dialog: ConfirmationDialog
var _viewed_files: Dictionary[String, bool] = {}

var _file_loader: FileLoader
@export var selection_manager: SelectionManager
@export var _data_handler: FileDataHandler
var _is_loading := false

signal directory_set(path: String)

func _ready() -> void:
	super._ready()

	_file_loader = FileLoader.new()
	add_child(_file_loader, INTERNAL_MODE_BACK)

	image_view.update_request.connect(update_view)
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
	ThumbnailManager.thumbnail_ready.connect(image_view._on_thumbnail_ready)

#region core view functions

func show_files_in_directory(dir_path: String) -> void:
	clear()

	_data_handler.assign_files(get_files_in_directory(dir_path))
	_file_loader.populate_queue(_data_handler.get_filtered_files())
	_is_loading = true

func show_search_results(results: Array[SearchResult]) -> void:
	clear()

	if results.is_empty():
		return
	for result in results:
		if result.image_path == "":
			_data_handler.add_file(result.image_path)
			
			# This method is put here to allow for live updating of the view.
			# when all files are loaded, the view will be reset and files
			# will be added in the right order with the right tooltips
			_add_item_to_view(result.image_path)
	_file_loader.populate_queue(_data_handler.get_filtered_files())
	_is_loading = true

func get_files_in_directory(dir_path: String) -> PackedStringArray:
	var dir := DirAccess.open(dir_path)
	var files: PackedStringArray = []
	if !dir:
		return files
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if !dir.current_is_dir() && ImageUtil.is_valid_image(file_name):
			var path := dir_path.path_join(file_name)
			files.append(path)

			# This method is put here to allow for live updating of the view.
			# when all files are loaded, the view will be reset and files
			# will be added in the right order with the right tooltips.
			_add_item_to_view(path)
		file_name = dir.get_next()
	dir.list_dir_end()

	return files

## Rebuild view from list of cached files. 
func rebuild_view_from_file_list() -> void:
	if _is_loading:
		return
	clear_view()

	_data_handler.sort_files()
	for file in _data_handler.get_filtered_files():
		_add_item_to_view(file, _data_handler.get_file_data(file))

## Update internal list of files and rebuild view.
func update_view() -> void:
	if directory:
		show_files_in_directory(directory)

func _register_file_data(file: String, file_data: FileData) -> void:
	_data_handler.register_file(file, file_data)

	if !_viewed_files.has(file) && file.get_extension() in extension_filter:
		_viewed_files[file] = true
		_add_item_to_view(file, file_data)

func _add_item_to_view(file: String, file_data: FileData = null) -> int:
	var index: int = image_view.add_item_to_list(file, file_data)
	ThumbnailManager.queue_thumbnail(file)
	return index

func _on_project_reset() -> void:
	clear_selection()
	clear_view()
	_file_loader.clear_queue()
	_file_loader.clear_cache()
	_data_handler.clear()
	_viewed_files.clear()

func clear() -> void:
	clear_selection()
	clear_view()
	_file_loader.clear_queue()
	_data_handler.clear()
	_viewed_files.clear()

func clear_view() -> void:
	_viewed_files.clear()
	image_view.clear()
	ThumbnailManager.clear_queue()
#endregion

#region File events
func _on_file_move_request(from: String, to: String) -> void:
	FileService.move_file(from, to)
	rebuild_view_from_file_list()

func _on_file_removed(_path: String) -> void:
	_data_handler.remove_file(_path)
	rebuild_view_from_file_list()

func _on_file_created(_path: String) -> void:
	if _path.get_base_dir() != directory:
		return
	_file_loader.add_file_to_queue(_path)
	rebuild_view_from_file_list()
#endregion


func clear_selection() -> void:
	selection_manager.clear_selection()

#region file operations
func _on_file_remove_request() -> void:
	var selection := selection_manager.get_selection()
	if selection.size() > 0:
		_active_dialog = _confirm_prefab.instantiate() as ConfirmationDialog
		add_child(_active_dialog)
		_active_dialog.title = "Delete file(s)"
		_active_dialog.dialog_text = "Are you certain you want to delete all %d files? This cannot be undone." % selection.size()
		_active_dialog.confirmed.connect(_on_file_remove_confirmation)
		_active_dialog.get_cancel_button().pressed.connect(_on_request_cancelled)
		_active_dialog.popup_centered()

func _on_file_remove_confirmation() -> void:
	for file in selection_manager.get_selection():
		var img_hash := _project_data.get_hash_for_path(file)
		_project_data.image_db.remove_image(img_hash)
		FileService.remove_file(file)
	rebuild_view_from_file_list()
	clear_selection()

func _on_file_rename_request() -> void:
	if selection_manager.get_selection_size() > 0:
		print("requesting file renaming")

func get_selection() -> PackedStringArray:
	return selection_manager.get_selection()

func get_selection_size() -> int:
	return selection_manager.get_selection_size()

func _on_request_cancelled() -> void:
	if _active_dialog:
		_active_dialog.queue_free()

func _on_file_loader_queue_completed() -> void:
	_is_loading = false
	rebuild_view_from_file_list()
#endregion

#region Getters & Setters

func set_directory(dir_path: String) -> void:
	if directory == dir_path:
		return
	directory = dir_path

	show_files_in_directory(directory)
	image_view.set_scroll_position(Vector2i.ZERO)
	directory_set.emit(directory)

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
