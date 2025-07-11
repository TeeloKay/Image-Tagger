class_name SelectionManager extends Node

@export var view: FileBrowserView
@export var _selection: PackedStringArray = []
@export var data_handler: FileDataHandler

var _selection_update_pending: bool = false

signal selection_changed
signal cleared
signal file_selected(file: String)

func _ready() -> void:
	if view:
		view.item_selected.connect(_on_item_selected)
		view.multi_item_selected.connect(_on_multi_item_selected)
		view.selection_updated.connect(_schedule_selection_update)
		selection_changed.connect(view.update_selection_count)

func get_selection_size() -> int:
	return _selection.size()

func set_selection(arr: PackedStringArray) -> void:
	_selection = arr

func get_selection() -> PackedStringArray:
	return _selection.duplicate()

func _on_item_selected(index: int) -> void:
	print(index)
	if index >= 0 && index < data_handler.get_file_count():
		_selection.append(data_handler.get_filtered_files()[index])
		if !_selection.is_empty():
			file_selected.emit(_selection[0])
		else:
			file_selected.emit("")
		selection_changed.emit()

func _on_multi_item_selected(index: int, _selected: bool) -> void:
	_on_item_selected(index)

func _schedule_selection_update() -> void:
	if _selection_update_pending:
		return
	_selection_update_pending = true
	call_deferred("_apply_selection_update")

func _apply_selection_update() -> void:
	clear_selection()
	var selected_items := view.get_selected_items()
	var items := data_handler.get_filtered_files()
	for index in selected_items:
		_selection.append(items[index])

	_selection_update_pending = false
	selection_changed.emit()

func clear_selection() -> void:
	_selection.clear()
	cleared.emit()
