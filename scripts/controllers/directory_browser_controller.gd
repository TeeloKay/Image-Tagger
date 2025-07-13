class_name DirectoryController extends MenuController

@export var directory_browser: DirectoryBrowser
@export_global_dir var _current_directory: String
@export var scan_interval: float = 12
@export var folder_operation_handler: FolderOperationhandler

var _active_folder_dialog: TextInputDialog

signal path_selected(path: String)

func _ready() -> void:
	super._ready()

	if directory_browser:
		directory_browser.folder_selected.connect(_on_folder_selected)
		directory_browser.image_data_dropped.connect(_on_image_data_dropped)
		directory_browser.folder_data_dropped.connect(_on_folder_data_dropped)

		directory_browser.update_request.connect(_update_view)
		directory_browser.create_subfolder_request.connect(_on_create_subfolder_request)
		directory_browser.rename_request.connect(_on_rename_request)
		directory_browser.delete_request.connect(_on_delete_request)
	
	if folder_operation_handler:
		folder_operation_handler.folder_created.connect(_on_subfolder_created)
		folder_operation_handler.folder_renamed.connect(_on_folder_renamed)
		folder_operation_handler.folder_deleted.connect(_on_folder_deleted)

	get_window().files_dropped.connect(_on_files_dropped)

func _on_project_loaded() -> void:
	super._on_project_loaded()
	_current_directory = _project_data.project_path
	_update_view()
	path_selected.emit(_current_directory)

func _on_folder_selected(path: String) -> void:
	_current_directory = path
	if _current_directory == "":
		path_selected.emit(_project_data.project_path)
	path_selected.emit(_current_directory)

## Method for handling files dropped into a directory through the internal drag & drop system
## Will attempt to move all the files from their original location to the new directory.
func _on_image_data_dropped(files: PackedStringArray, target_dir: String) -> void:
	print("moving %d files" % files.size())
	for file in files:
		var new_path := target_dir.path_join(file.get_file())
		print(file, " -> ", new_path)
		FileService.move_file(file, new_path, true)

func _on_folder_data_dropped(target_dir: String, source_dir: String) -> void:
	print(source_dir, " -> ", target_dir)
	var new_dir := target_dir.path_join(source_dir.get_file())
	if DirAccess.dir_exists_absolute(new_dir):
		return
	var err := DirAccess.rename_absolute(source_dir, new_dir)
	_update_view()
	
func _on_create_subfolder_request() -> void:
	folder_operation_handler.request_create_folder(_current_directory)

func _on_rename_request() -> void:
	folder_operation_handler.request_rename_folder(_current_directory)

func _on_delete_request() -> void:
	folder_operation_handler.request_delete_folder(_current_directory)
	
func _on_subfolder_created(_subfolder: String) -> void:
	_update_view()

func _on_folder_renamed(_old_folder: String, _new_folder: String) -> void:
	_update_view()

func _on_folder_deleted(_folder: String) -> void:
	_update_view()

func _update_view() -> void:
	print("updating view")
	directory_browser.build_directory_tree(_project_data.project_path)
	directory_browser.clear_filter()

## Method for handling files dropped into the project from outside.
## Will attempt to copy and save all files in the currently open directory.
func _on_files_dropped(files: PackedStringArray) -> void:
	if _project_data == null || _current_directory == "":
		return
	for file in files:
		if !ImageUtil.is_valid_image(file):
			continue

		var file_exists := true
		var counter := 0
		var extension := file.get_extension()
		var file_path := ""
		var file_name := file.get_file().get_basename()
		var new_name := file_name

		while file_exists:
			file_path = _current_directory.path_join(new_name + "." + extension)
			file_exists = FileAccess.file_exists(file_path)
			if file_exists:
				counter += 1
				new_name = "%s_%d" % [file_name, counter]
		FileService.copy_file(file, file_path)

#region Folder Operations

func _on_folder_dialog_input_changed(folder_name: String) -> void:
	if !_active_folder_dialog:
		return
	var name_is_valid := folder_operation_handler.folder_name_is_valid(folder_name)
	var folder_exists := DirAccess.dir_exists_absolute(_current_directory.path_join(folder_name))
	_active_folder_dialog.is_valid = name_is_valid && !folder_exists

func _on_folder_dialog_confirmed() -> void:
	if !_active_folder_dialog:
		return
	var dir_name := _active_folder_dialog.get_input_text()
	var err := folder_operation_handler.create_folder(_current_directory, dir_name)
	if err != OK:
		push_error(err)
	_update_view()
	pass

func move_folder(old_path: String, new_path: String) -> void:
	if !DirAccess.dir_exists_absolute(old_path) || DirAccess.dir_exists_absolute(new_path):
		return
	var err := DirAccess.rename_absolute(old_path, new_path)
	if err != OK:
		push_error("Could not rename directory: ", err)

#endregion
