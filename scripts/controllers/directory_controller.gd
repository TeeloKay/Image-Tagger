class_name DirectoryController extends MenuController

@export var directory_view: DirectoryView
@export_global_dir var _current_directory: String
@export var scan_interval: float = 12

var _confirm_dialog := preload("res://scenes/common/popups/confirm_dialog.tscn")
var _active_dialog: ConfirmationDialog

signal path_selected(path: String)

func _ready() -> void:
	super._ready()

	directory_view.folder_selected.connect(_on_folder_selected)
	directory_view.data_dropped.connect(_on_data_dropped)
	directory_view.update_request.connect(_update_view)

	get_window().files_dropped.connect(_on_files_dropped)


func _on_project_loaded() -> void:
	super._on_project_loaded()
	_current_directory = _project_data.project_path
	_update_view()
	path_selected.emit(_current_directory)

func _on_folder_selected(path: String) -> void:
	_current_directory = path
	path_selected.emit(_current_directory)

func _on_data_dropped(from: String, to: String) -> void:
	print(from, " -> ", to)
	FileService.move_file(from, to)

func _on_delete_request(path: String) -> void:
	var dir := DirAccess.open(path)
	if !dir:
		push_error("Error opening directory at path: ", path)
		return
	_active_dialog = _confirm_dialog.instantiate() as ConfirmationDialog
	add_child(_active_dialog)
	_active_dialog.title = "Delete folder"
	_active_dialog.dialog_text = "Are you certain you want to delete this folder and all of its contents?: " + path
	_active_dialog.confirmed.connect(func(): delete_folder(path))
	_active_dialog.get_cancel_button().pressed.connect(_on_request_cancelled)
	print("deleting directory and all its contents (not)")

func _update_view() -> void:
	print("updating view")
	directory_view.build_directory_tree(_current_directory)
	directory_view.clear_filter()

func _on_files_dropped(files: PackedStringArray) -> void:
	if _project_data == null || _current_directory == "":
		return
	print(files)
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
				print(new_name)
		FileService.copy_file(file, file_path)

#region Folder Operations	
func create_new_folder(new_path: String) -> void:
	new_path = _project_data.to_abolute_path(new_path)
	var err := DirAccess.make_dir_absolute(new_path)
	if err != OK:
		push_error("Could not generate directory: ", err)


func delete_folder(path: String) -> void:
	if !DirAccess.dir_exists_absolute(path):
		return
	var err := DirAccess.remove_absolute(path)
	if err != OK:
		push_error("Could not delete directory: ", err)
	if _active_dialog:
		_active_dialog.queue_free()


func move_folder(old_path: String, new_path: String) -> void:
	if !DirAccess.dir_exists_absolute(old_path) || DirAccess.dir_exists_absolute(new_path):
		return
	var err := DirAccess.rename_absolute(old_path, new_path)
	if err != OK:
		push_error("Could not rename directory: ", err)

#endregion

func _on_request_cancelled() -> void:
	if _active_dialog:
		_active_dialog.queue_free()
