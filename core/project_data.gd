class_name ProjectData extends Resource

## Absolute project path
@export var project_path: String = ""
@export var favorites: Array = []
@export var folder_tags: Dictionary

var image_db: ImageDB
var tag_db: TagDB

func _init() -> void:
	image_db = ImageDB.new()
	tag_db = TagDB.new()

func add_image(image_hash: String, path: String) -> void:
	path = to_relative_path(path)
	image_db.register_image(path, image_hash)

func remove_image(file_hash: String) -> void:
	if image_db.has(file_hash):
		for tag in image_db.get_image_data(file_hash).tags:
			tag_db.remove_hash_from_tag(file_hash, tag)
		image_db.remove_image(file_hash)

func clear_index() -> void:
	pass

#region Tags

## Sets the exact tags for an image by hash.
## Adds missing tags and removes any not in the provided list.
func set_tags_for_hash(file_hash: String, tags: Array[StringName]) -> void:
	if !image_db.has(file_hash):
		return
	var original_tags := image_db.get_image_data(file_hash).tags
	
	for tag in tags:
		if !tag in original_tags:
			tag_file(file_hash, tag)
	
	for tag in original_tags:
		if !tag in tags:
			untag_file(file_hash, tag)
	
	ProjectContext.save_current_project()

## Adds tags to an image by hash, preserving existing tags.
## Only new tags are applied and recorded in the tag database.
func add_tags_for_hash(file_hash: String, tags: Array[StringName]) -> void:
	if !image_db.has(file_hash):
		return
	var original_tags := image_db.get_image_data(file_hash).tags

	for tag in tags:
		if !tag in original_tags:
			tag_file(file_hash, tag)
	
	ProjectContext.save_current_project()

## Adds a single tag to a file by hash.
## Automatically creates the tag in the database if it doesn't exist.
func tag_file(file_hash: String, tag: StringName) -> void:
	if tag.is_empty() || !image_db.has(file_hash):
		return
	tag_db.add_tag(tag)
	tag_db.add_hash_to_tag(file_hash, tag)
	image_db.add_tag_to_image(file_hash, tag)

## Removes a tag from a file by hash.
## Also updates the tag database to remove the hash from the tag's list.
func untag_file(file_hash: String, tag: StringName) -> void:
	if tag.is_empty() || !image_db.has(file_hash):
		return
	tag_db.remove_hash_from_tag(file_hash, tag)
	image_db.remove_tag_from_image(file_hash, tag)

## Returns all tags associated with a file by hash.
func get_tags_for_hash(file_hash: String) -> Array[StringName]:
	return image_db.get_image_data(file_hash).tags

## Returns all file hashes associated with the given tag.
func get_files_with_tag(tag: StringName) -> PackedStringArray:
	if !tag_db.has(tag):
		return []
	return tag_db.get_tag_data(tag).hashes

## Returns the list of all tags known to the tag database.
func get_tags() -> Array[StringName]:
	return tag_db.get_tags()

## Returns tag metadata for a given tag.
func get_tag_data(tag: StringName) -> TagData:
	return tag_db.get_tag_data(tag)

## Registers a new tag in the tag database if it doesn't already exist.
func add_tag(tag: StringName) -> void:
	tag_db.add_tag(tag)
		
#endregion
#region Favorites

func add_to_favorites(image_hash: String) -> void:
	if !favorites.has(image_hash):
		favorites.append(image_hash)

func remove_from_favorites(image_hash: String) -> void:
	if favorites.has(image_hash):
		favorites.erase(image_hash)

func is_favorited(image_hash: String) -> bool:
	return favorites.has(image_hash)

#endregion
#region Data Access

func get_image_data(image_hash: String) -> ImageData:
	return image_db.get_image_data(image_hash)

func index_image_path(image_path: String, image_hash: String) -> void:
	pass

func get_hash_for_path(image_path: String, _force_new: bool = false) -> String:
	return ""

func get_path_for_hash(image_hash: String) -> String:
	return image_db.get_path_for_hash(image_hash)

func move_image_data(old_path: String, new_path: String) -> void:
	old_path = to_relative_path(old_path)
	new_path = to_relative_path(new_path)
	var image_hash := get_hash_for_path(old_path)
	if image_hash.is_empty():
		image_hash = ProjectContext.importer.hash_file(new_path)
	image_db.update_image_path(image_hash, new_path)

#endregion
#region Paths

func to_relative_path(abs_path: String) -> String:
	if abs_path.begins_with(project_path):
		return abs_path.replace(project_path + "/", "")
	return abs_path

func to_abolute_path(rel_path: String) -> String:
	if rel_path.begins_with(project_path + "/"):
		return rel_path
	return project_path.path_join(rel_path)

#endregion
#region Full data

## returns packed array of image hashes
func get_images() -> PackedStringArray:
	return image_db.get_images()

func get_index() -> Dictionary:
	return {}

#endregion
