class_name DatabaseAdapter extends Node

const NO_ALPHA: bool = false

@export_color_no_alpha var default_tag_color := Color.SLATE_GRAY

var _db_manager: Node

signal database_opened(path: String)
signal database_closed

signal image_registered(image_hash: String)
signal image_changed(image_hash: String)
signal image_moved(from: String, to: String)

signal tags_changed
signal tag_added(tag: StringName)
signal tag_removed(tag: StringName)
signal tag_updated(tag: StringName)

func _ready() -> void:
	_db_manager = preload("res://data/DatabaseManager.cs").new()
	add_child(_db_manager, INTERNAL_MODE_BACK)

	_db_manager.DatabaseOpened.connect(func(path: String) -> void: database_opened.emit(path))
	_db_manager.DatabaseClosed.connect(func() -> void: database_closed.emit())

func set_database_path(path: String) -> void:
	_db_manager.SetDatabasePath(path)

func open_database() -> void:
	_db_manager.OpenDatabase()

func close_database() -> void:
	_db_manager.CloseDatabase()

func is_database_open() -> bool:
	return _db_manager.IsDatabaseOpen

#region Image Operations
func add_image(img_hash: String, path: String, fingerprint: String, metadata: Dictionary) -> void:
	var json := JSON.stringify(metadata)
	var rel_path: String = ProjectContext.to_relative_path(path)
	_db_manager.AddImage(img_hash, rel_path, fingerprint, json)
	image_registered.emit(img_hash)

func delete_image(img_hash: String) -> void:
	_db_manager.DeleteImage(img_hash)
	image_changed.emit(img_hash)

func get_image_info(img_hash: String) -> ImageData:
	var img_data := ImageData.new()
	if img_hash.is_empty():
		return img_data
	var data: Dictionary = _db_manager.GetImageInfo(img_hash)
	var tags := get_tags_for_image(img_hash)

	if data.is_empty():
		return img_data

	img_data.image_hash = data.get("hash", "")
	img_data.last_path = data.get("path", "")
	img_data.fingerprint = data.get("fingerprint", "")
	img_data.favorited = bool(data.get("favorited", 0))

	for tag_info in tags:
		img_data.add_tag(tag_info.tag)

	return img_data

func get_all_images() -> Array[String]:
	return _db_manager.GetAllImages()

func update_image_path(img_hash: String, to: String) -> void:
	var rel_path: String = ProjectContext.to_relative_path(to)
	var paths: Dictionary = _db_manager.UpdateImagePath(img_hash, rel_path)
	image_moved.emit(paths.get("old_path", ""), paths.get("new_path", ""))

func get_hash_for_path(path: String) -> String:
	var rel_path: String = ProjectContext.to_relative_path(path)
	return _db_manager.GetHashForPath(rel_path)

func set_image_favorited(img_hash: String, favorited: bool = true) -> void:
	_db_manager.SetImageFavorited(img_hash, favorited)
#endregion

#region Tag Operations
func add_tag(tag: StringName, color: Color) -> void:
	var hex := color.to_html(NO_ALPHA)
	_db_manager.AddTag(tag, hex)
	tag_added.emit(tag)
	tags_changed.emit()

func delete_tag(tag: StringName) -> void:
	print("deleting tag: ", tag)
	_db_manager.DeleteTag(tag)
	tag_removed.emit(tag)
	tags_changed.emit()

func get_image_count_for_tag(tag: StringName) -> int:
	return _db_manager.GetImageCountForTag(tag)

func get_tag_info(tag: StringName) -> TagData:
	var data := TagData.new()
	var dict: Dictionary = _db_manager.GetTagInfo(tag)
	data.tag = tag
	if dict.is_empty():
		return data
	data.color = Color.from_string("#" + str(dict.color), default_tag_color)

	return data
	
func get_all_tags() -> Dictionary[StringName, TagData]:
	var results: Dictionary[StringName, TagData] = {}
	var tags: Array[Dictionary] = _db_manager.GetAllTags()
	for tag in tags:
		var data := TagData.new()
		data.tag = tag.tag
		data.color = Color.from_string("#" + str(tag.color), default_tag_color)
		results[tag.tag] = data
	return results

func update_tag_color(tag: StringName, color: Color) -> void:
	_db_manager.UpdateTagField(tag, "color", color.to_html(NO_ALPHA))
#endregion

#region Core Operations
func tag_image(img_hash: String, tag: StringName) -> void:
	_db_manager.TagImage(img_hash, tag)
	image_changed.emit(img_hash)
	tag_updated.emit(tag)

func multi_tag_image(img_hash: String, tags: Array[StringName]) -> void:
	for tag in tags:
		_db_manager.TagImage(img_hash, tag)
		tag_updated.emit(tag)
	image_changed.emit(img_hash)

func untag_image(img_hash: String, tag: StringName) -> void:
	_db_manager.UntagImage(img_hash, tag)
	image_changed.emit(img_hash)
	tag_updated.emit(tag)

func get_images_with_tag(tag: StringName) -> Array[String]:
	return _db_manager.GetImagesWithTag(tag)

func get_tags_for_image(img_hash: String) -> Array[TagData]:
	var tags: Array[TagData] = []
	var result: Array[Dictionary] = _db_manager.GetTagsForImage(img_hash)
	for tag in result:
		var tag_data := TagData.new()
		tag_data.tag = tag.get("tag", &"")
		tag_data.color = Color.from_string("#" + str(tag.get("color")), default_tag_color)
		tags.append(tag_data)
	
	return tags
	
#endregion

#region Search
func search(search_query: SearchQuery) -> Array[ImageData]:
	if search_query.is_empty():
		return []
	var results: Array[Dictionary] = _db_manager.ImageSearch(
		search_query.inclusive_tags,
		search_query.exclusive_tags,
	 	search_query.filter
		)
	var image_data_array: Array[ImageData]
	for result in results:
		var info := ImageData.new()
		info.image_hash = result["hash"]
		info.last_path = result["path"]
		info.fingerprint = result["fingerprint"]
		image_data_array.append(info)
	return image_data_array
#endregion
