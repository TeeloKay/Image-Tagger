class_name DatabaseAdapter extends Node

var _db_manager: Node

signal database_opened(path: String)
signal database_closed

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
	
#region Image Operations
func add_image(img_hash: String, path: String, fingerprint: String, metadata: Dictionary) -> void:
	var json := JSON.stringify(metadata)
	_db_manager.AddImage(img_hash, path, fingerprint, json)

func delete_image(img_hash: String) -> void:
	_db_manager.DeleteImage(img_hash)

func get_image_info(img_hash: String) -> Dictionary:
	return _db_manager.GetImageInfo(img_hash)

func get_all_images() -> Array[String]:
	return _db_manager.GetAllImages()
#endregion

#region Tag Operations
func add_tag(tag: StringName, color: Color) -> void:
	var hex := color.to_html(false)
	_db_manager.AddTag(tag, hex)

func delete_tag(tag: StringName) -> void:
	_db_manager.DeleteTag(tag)

func get_image_count_for_tag(tag: StringName) -> int:
	return _db_manager.GetImageCountForTag(tag)

func get_tag_info(tag: StringName) -> Dictionary:
	return _db_manager.GetTagInfo(tag)
	
func get_all_tags() -> Array[StringName]:
	return _db_manager.GetAllTags()
#endregion

#region Core Operations
func tag_image(img_hash: String, tag: StringName) -> void:
	_db_manager.TagImage(img_hash, tag)

func untag_image(img_hash: String, tag: StringName) -> void:
	_db_manager.UntagImage(img_hash, tag)

func get_images_with_tag(tag: StringName) -> Array[String]:
	return _db_manager.GetImagesWithTag(tag)

func get_tags_for_image(img_hash: String) -> Array[StringName]:
	return _db_manager.GetTagsForImage(img_hash)
#endregion

#region Search
func search(search_query: SearchQuery) -> Array[Dictionary]:
	return _db_manager.Search(search_query.inclusive_tags, [], search_query.filter)
#endregion