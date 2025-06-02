class_name HelpMenu extends MenuButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_build_menu()

func _build_menu() -> void:
	var popup := self.get_popup()
	popup.add_item("About", 0)
