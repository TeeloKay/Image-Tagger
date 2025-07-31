class_name TagData extends RefCounted

var tag: StringName = &""
var color: Color = Color.SLATE_GRAY

func duplicate() -> TagData:
	var copy := TagData.new()
	copy.color = color
	copy.tag = tag
	return copy
