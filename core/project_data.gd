class_name ProjectData extends Resource

const FAVORITES := "favorites"
const IMAGES := "image_data"
const TAGS := "tag_data"

## Absolute project path
@export var project_path: String = ""
@export var favorites: Array = []
@export var folder_tags: Dictionary

var image_db: ImageDB
var index: FileIndex
var tag_db: TagDB

func _init() -> void:
	image_db = ImageDB.new()
	tag_db = TagDB.new()
	index = FileIndex.new()

func add_image(image_hash: String, path: String) -> void:
	path = to_relative_path(path)
	image_db.register_image(path, image_hash)
	index.add(path, image_hash)

func remove_image(image_hash: String) -> void:
	if image_db.has(image_hash):
		for tag in image_db.get_image_data(image_hash).tags:
			tag_db.remove_hash_from_tag(image_hash, tag)
		image_db.remove_image(image_hash)
		index.erase(image_hash)

func clear_index() -> void:
	index.clear()

#region Tags

func set_tags_for_hash(image_hash: String, tags: Array[StringName]) -> void:
	if !image_db.has(image_hash):
		return
	var original_tags = image_db.get_image_data(image_hash).tags
	
	for tag in tags:
		if !tag in original_tags:
			image_db.add_tag_to_image(image_hash, tag)
			tag_db.add_hash_to_tag(image_hash, tag)
	
	for tag in original_tags:
		if !tag in tags:
			image_db.remove_tag_from_image(image_hash, tag)
			tag_db.remove_hash_from_tag(image_hash, tag)
	
	ProjectManager.save_current_project()

func tag_image_by_hash(image_hash: String, tag: StringName) -> void:
	if tag.is_empty() || !image_db.has(image_hash):
		return
	tag_db.add_tag(tag)
	tag_db.add_hash_to_tag(image_hash, tag)
	image_db.add_tag_to_image(image_hash, tag)

func untag_image_by_hash(image_hash: String, tag: StringName) -> void:
	if tag.is_empty() || !image_db.has(image_hash):
		return
	tag_db.remove_hash_from_tag(image_hash, tag)
	image_db.remove_tag_from_image(image_hash, tag)

func get_tags_for_hash(image_hash: String) -> Array[StringName]:
	return image_db.get_image_data(image_hash).tags

func get_images_with_tag(tag: StringName) -> PackedStringArray:
	if !tag_db.has(tag):
		return []
	return tag_db.get_tag_data(tag).hashes

func get_tags() -> Array[StringName]:
	return tag_db.get_tags()

func get_tag_data(tag: StringName) -> TagData:
	return tag_db.get_tag_data(tag)

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
	index.add(image_path, image_hash)

func get_hash_for_path(image_path: String, _force_new: bool = false) -> String:
	return index.get_hash_for_file(image_path)

func get_path_for_hash(image_hash: String) -> String:
	return image_db.get_path_for_hash(image_hash)

func move_image_data(old_path: String, new_path: String) -> void:
	old_path = to_relative_path(old_path)
	new_path = to_relative_path(new_path)
	var image_hash := get_hash_for_path(old_path)
	if image_hash.is_empty():
		image_hash = ProjectManager.image_hasher.hash_file(new_path)
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
	return index.get_index()

#endregion
#region Serialization

func serialize() -> Dictionary:
	var data := {
		IMAGES: image_db.serialize(),
		TAGS: tag_db.serialize(),
		FAVORITES: favorites
	}
	return data

func deserialize(data: Dictionary) -> void:
	image_db = ImageDB.new()
	image_db.deserialize(data.get(IMAGES, {}))

	tag_db = TagDB.new()
	tag_db.deserialize(data.get(TAGS))

	favorites = data.get(FAVORITES, [])

#endregion
