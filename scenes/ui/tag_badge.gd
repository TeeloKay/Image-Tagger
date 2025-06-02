@tool class_name TagBadge extends PanelContainer

@export var tag: StringName:
	set = set_tag

@onready var _tag_label: Label = $MarginContainer/HBoxContainer/Label

signal remove_requested(tag: StringName)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_display()

func set_tag(val: String) -> void:
	tag = val
	_update_display()

func _update_display() -> void:
	_tag_label.text = tag

func _on_remove_pressed() -> void:
	remove_requested.emit(tag)
