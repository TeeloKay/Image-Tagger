class_name FileRenamer extends Node

@export var _dialog: AcceptDialog

func rename_file(file: String, new_file: String) -> Error:
	var err := FileService.move_file(file, new_file, true)
	if err == OK:
		return err
	match err:
		ERR_FILE_NOT_FOUND:
			await _show_popup(
				"File does not exist",
				"The selected file does not exist, or no longer exists in this location."
				)
		ERR_FILE_BAD_PATH:
			await _show_popup(
				"Invalid filename",
				"The file name provided is not valid. Please avoid the following characters:
				<, >, :, \", /, \\, |, ?, *"
			)
		ERR_FILE_ALREADY_IN_USE:
			await _show_popup(
				"File already exists",
				"A file with this name already exists. Please try a different name."
			)
		_:
			await _show_popup(
				"Error!",
				"An unknown error occured when trying to rename file. error code %d" % err
			)
			
	return err

func _show_popup(title: String, text: String) -> void:
	_dialog.title = title
	_dialog.dialog_text = text
	_dialog.popup_centered()
	await _dialog.confirmed
