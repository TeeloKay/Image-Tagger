class_name ProjectData extends Resource

const FAVORITES 	:= "favorites"
const IMAGES 		:= "image_data"
const TAGS 			:= "tag_data"
const INDEX 		:= "index"

## Absolute project path
@export var project_path: String = ""
@export var favorites: Array = []
@export var folder_tags: Dictionary

var image_db: ImageDB
var tag_db: TagDB

signal index_updated

func _init() -> void:
	image_db = ImageDB.new()
	tag_db = TagDB.new()

func add_image(image_hash: String, path: String) -> void:
	path = to_relative_path(path)
	image_db.register_image(path,image_hash)

func clear_index() -> void:
	image_db.clear_index()

#region Tags

func set_tags_for_hash(image_hash: String, tags: Array[StringName]) -> void:
	if !image_db.has(image_hash):
		return
	var original_tags = image_db.get_info_for_hash(image_hash).tags
	
	for tag in tags:
		if !tag in original_tags:
			image_db.add_tag_to_image(image_hash,tag)
			tag_db.add_hash_to_tag(image_hash,tag)
	
	for tag in original_tags:
		if !tag in tags:
			image_db.remove_tag_from_image(image_hash,tag)
			tag_db.remove_hash_from_tag(image_hash,tag)
	
	ProjectManager.save_current_project()
	

func tag_image_by_hash(image_hash: String, tag: StringName) -> void:
	if tag.is_empty() || !image_db.has(image_hash):
		return
	tag_db.add_tag(tag)
	tag_db.add_hash_to_tag(image_hash,tag)
	image_db.add_tag_to_image(image_hash,tag)

func untag_image_by_hash(image_hash: String, tag: StringName) -> void:
	if tag.is_empty() || !image_db.has(image_hash):
		return
	tag_db.remove_hash_from_tag(image_hash,tag)
	image_db.remove_tag_from_image(image_hash,tag)

func get_tags_for_hash(image_hash: String) -> Array[StringName]:
	return image_db.get_info_for_hash(image_hash).tags

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
	image_db.index_image(image_path, image_hash)

func get_hash_for_path(image_path: String) -> String:
	var image_hash = image_db.get_hash_for_path(to_relative_path(image_path))
	return image_hash

func get_path_for_hash(image_hash: String) -> String:
	return image_db.get_path_for_hash(image_hash)

func get_info_for_hash(image_hash: String) -> ImageData:
	return image_db.get_info_for_hash(image_hash)

func move_image_data(old_path: String, new_path: String) -> void:
	old_path = to_relative_path(old_path)
	new_path = to_relative_path(new_path)
	var image_hash := image_db.get_hash_for_path(old_path)
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
#region Image Index

## returns packed array of image hashes
func get_images() -> PackedStringArray:
	return image_db.get_images()

func get_index() -> Dictionary:
	return image_db.get_index()

#endregion
#region Serialization

func serialize() -> Dictionary:
	var img_dict := {}
	var tag_dict := {}
	
	for key in image_db.get_images():
		img_dict[key] = image_db.get_info_for_hash(key).serialize()
		
	for key in tag_db.get_tags():
		tag_dict[key] = tag_db.get_tag_data(key).serialize()
	
	var index = image_db._index

	var data := {
		IMAGES: img_dict,
		TAGS: tag_dict,
		INDEX: index,
		FAVORITES: favorites
	}
	
	return data

func deserialize(data: Dictionary) -> void:
	for key in data.get(IMAGES, {}):
		var dat := ImageData.new()
		dat.deserialize(data[IMAGES][key])
		image_db._image_db[key] = dat
	
	for key in data.get(TAGS, {}):
		var dat := TagData.new()
		dat.deserialize(data[TAGS][key])
		tag_db._db[key] = dat
	
	image_db._index = data.get(INDEX, {})
	favorites = data.get(FAVORITES, [])

#endregion
