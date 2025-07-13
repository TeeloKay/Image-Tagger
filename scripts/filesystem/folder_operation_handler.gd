class_name FolderOperationhandler extends Node

@export var invalid_contents: PackedStringArray = ["/", "\\", "<", ">", ":", "\"", "%", ".", "|", "?", "*"]

signal folder_created(path: String)
signal folder_deleted(path: String)
signal folder_renamed(old_path: String, new_path: String)

var _name_dialog := preload("res://scenes/common/popups/text_input_dialog.tscn")

#region Folder Creation
func request_create_folder(parent_dir: String) -> void:
	var dialog := _name_dialog.instantiate() as TextInputDialog
	add_child(dialog)
	dialog.title = "Create new folder"

	dialog.input_changed.connect(func(dir_name: String) -> void:
		dialog.is_valid = folder_name_is_valid(dir_name))
	dialog.confirmed.connect(func() -> void:
		create_folder(parent_dir, dialog.get_dir_name())
	)
	dialog.get_cancel_button().pressed.connect(dialog.queue_free)

	dialog.popup_centered()

func create_folder(parent_dir: String, dir_name: String) -> Error:
	var new_path := parent_dir.path_join(dir_name)
	if DirAccess.dir_exists_absolute(new_path):
		return ERR_ALREADY_EXISTS

	if !folder_name_is_valid(dir_name):
		return ERR_INVALID_PARAMETER

	var err := DirAccess.make_dir_absolute(new_path)
	if err != OK:
		return err

	folder_created.emit(new_path)
	return OK
#endregion

func delete_folder(path: String) -> Error:
	if !DirAccess.dir_exists_absolute(path):
		return ERR_DOES_NOT_EXIST

	var err := DirAccess.remove_absolute(path)
	if err != OK:
		return err

	folder_deleted.emit(path)
	return OK

func rename_folder(old_path: String, new_name: String) -> Error:
	var base_dir := old_path.get_base_dir()
	var new_path := base_dir.path_join(new_name)

	if DirAccess.dir_exists_absolute(new_path):
		return ERR_ALREADY_EXISTS

	var err := DirAccess.rename_absolute(old_path, new_path)
	if err != OK:
		return err

	folder_renamed.emit(old_path, new_path)
	return OK

func folder_name_is_valid(dir_name: String) -> bool:
	if dir_name == "":
		return false
	for token in invalid_contents:
		if dir_name.contains(token):
			return false
	return true
