class_name FolderOperationhandler extends Node

@export var invalid_contents: PackedStringArray = ["/", "\\", "<", ">", ":", "\"", "%", ".", "|", "?", "*"]

signal folder_created(path: String)
signal folder_deleted(path: String)
signal folder_renamed(old_path: String, new_path: String)

var _name_dialog := preload("res://scenes/common/popups/text_input_dialog.tscn")

#region Folder Creation
func request_create_folder(parent_dir: String) -> void:
	var dialog: TextInputDialog = _name_dialog.instantiate()
	add_child(dialog)

	dialog.title = "Create new folder"

	dialog.input_changed.connect(func(dir_name: String) -> void: dialog.is_valid = folder_name_is_valid(dir_name))
	dialog.confirmed.connect(func() -> void: create_folder(parent_dir, dialog.get_input_text()))
	dialog.get_cancel_button().pressed.connect(dialog.queue_free)

	dialog.popup_centered()

func create_folder(parent_dir: String, dir_name: String) -> Error:
	var new_path := parent_dir.path_join(dir_name)
	if DirAccess.dir_exists_absolute(new_path):
		push_error("Folder already exists: ", new_path)
		return ERR_ALREADY_EXISTS

	if !folder_name_is_valid(dir_name):
		push_error("Folder name is not valid: ", dir_name)
		return ERR_INVALID_PARAMETER

	var err := DirAccess.make_dir_absolute(new_path)
	if err != OK:
		push_error("Could not create folder: ", new_path)
		return err

	folder_created.emit(new_path)
	return OK
#endregion

#region Folder Deletion
func request_delete_folder(path: String) -> void:
	var dialog := ConfirmationDialog.new()
	add_child(dialog)

	dialog.title = "Delete folder"
	dialog.dialog_text = "Are you certain you want to delete the selected folder(s)?"

	dialog.confirmed.connect(func() -> void: delete_folder(path))
	dialog.get_cancel_button().pressed.connect(dialog.queue_free)

	dialog.popup_centered()

func delete_folder(path: String) -> Error:
	if !DirAccess.dir_exists_absolute(path):
		push_error("Folder does not exist: ", path)
		return ERR_DOES_NOT_EXIST

	var err := DirAccess.remove_absolute(path)
	if err != OK:
		push_error("Can't remove folder: ", err)
		return err

	folder_deleted.emit(path)
	return OK

#region Folder Renaming
func request_rename_folder(old_path: String) -> void:
	var dialog: TextInputDialog = _name_dialog.instantiate()
	add_child(dialog)

	dialog.title = "Rename folder"
	# dialog.set_input_text = old_path.get_base_dir()

	dialog.confirmed.connect(func() -> void: rename_folder(old_path, dialog.get_input_text()))
	dialog.get_cancel_button().pressed.connect(dialog.queue_free)

	dialog.popup_centered()

func rename_folder(old_path: String, new_name: String) -> Error:
	var base_dir := old_path.get_base_dir()
	var new_path := base_dir.path_join(new_name)

	if DirAccess.dir_exists_absolute(new_path):
		push_error("Folder already exists: ", new_path)
		return ERR_ALREADY_EXISTS

	var err := DirAccess.rename_absolute(old_path, new_path)
	if err != OK:
		push_error("Can't rename folder: ", err)
		return err

	folder_renamed.emit(old_path, new_path)
	return OK

#endregion

func folder_name_is_valid(dir_name: String) -> bool:
	if dir_name == "":
		return false
	for token in invalid_contents:
		if dir_name.contains(token):
			return false
	return true
