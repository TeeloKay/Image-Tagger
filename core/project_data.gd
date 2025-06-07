class_name ProjectData extends Resource

const FAVORITES 	:= "favorites"
const IMAGES 		:= "image_data"
const TAGS 			:= "tag_data"
const INDEX 		:= "index"

## Absolute project path
@export var project_path: String = ""
@export var favorites: Array = []
@export var folder_tags: Dictionary

var image_manager: ImageManager
var tag_manager: TagManager

signal index_updated

func _init() -> void:
	image_manager = ImageManager.new()
	tag_manager = TagManager.new()

func add_image(hash_val: String, path: String) -> void:
	path = to_relative_path(path)
	image_manager.register_image(path,hash_val)

func clear_index() -> void:
	image_manager.clear_index()

#region Tags

func set_tags_for_hash(hash_val: String, tags: Array[StringName]) -> void:
	if !image_manager.has(hash_val):
		return
	var original_tags = image_manager.get_info_for_hash(hash_val).tags
	
	for tag in tags:
		if !tag in original_tags:
			image_manager.add_tag_to_image(hash_val,tag)
			tag_manager.add_hash_to_tag(hash_val,tag)
	
	for tag in original_tags:
		if !tag in tags:
			image_manager.remove_tag_from_image(hash_val,tag)
			tag_manager.remove_hash_from_tag(hash_val,tag)
	
	ProjectManager.save_current_project()
	

func tag_image_by_hash(hash_val: String, tag: StringName) -> void:
	if tag.is_empty() || !image_manager.has(hash_val):
		return
	tag_manager.add_tag(tag)
	tag_manager.add_hash_to_tag(hash_val,tag)
	image_manager.add_tag_to_image(hash_val,tag)

func untag_image_by_hash(hash_val: String, tag: StringName) -> void:
	if tag.is_empty() || !image_manager.has(hash_val):
		return
	tag_manager.remove_hash_from_tag(hash_val,tag)
	image_manager.remove_tag_from_image(hash_val,tag)

func get_tags_for_hash(hash_val: String) -> Array[StringName]:
	return image_manager.get_info_for_hash(hash_val).tags

func get_images_with_tag(tag: StringName) -> PackedStringArray:
	if !tag_manager.has(tag):
		return []
	return tag_manager.get_tag_data(tag).hashes

func get_tags() -> Array[StringName]:
	return tag_manager.get_tags()

func get_tag_data(tag: StringName) -> TagData:
	return tag_manager.get_tag_data(tag)

func add_tag(tag: StringName) -> void:
	tag_manager.add_tag(tag)
		
#endregion
#region Favorites

func add_to_favorites(hash_val: String) -> void:
	if !favorites.has(hash_val):
		favorites.append(hash_val)

func remove_from_favorites(hash_val: String) -> void:
	if favorites.has(hash_val):
		favorites.erase(hash_val)

func is_favorited(hash_val: String) -> bool:
	return favorites.has(hash_val)

#endregion
#region Data Access

func index_image_path(image_path: String, hash: String = "") -> void:
	image_manager.index_image(image_path, hash)

func get_hash_for_path(image_path: String) -> String:
	var hash_val = image_manager.get_hash_for_path(to_relative_path(image_path))
	return hash_val

func get_path_for_hash(hash_val: String) -> String:
	return image_manager.get_path_for_hash(hash_val)

func get_info_for_hash(hash_val: String) -> ImageInfo:
	return image_manager.get_info_for_hash(hash_val)

func move_image_data(old_path: String, new_path: String) -> void:
	old_path = to_relative_path(old_path)
	new_path = to_relative_path(new_path)
	var hash_val := image_manager.get_hash_for_path(old_path)
	image_manager.update_hash_path(hash_val, new_path)

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
	return image_manager.get_images()

func get_index() -> Dictionary:
	return image_manager.get_index()

#endregion
#region Serialization

func serialize() -> Dictionary:
	var img_dict := {}
	var tag_dict := {}
	
	for key in image_manager.get_images():
		img_dict[key] = image_manager.get_info_for_hash(key).serialize()
		
	for key in tag_manager.get_tags():
		tag_dict[key] = tag_manager.get_tag_data(key).serialize()
	
	var index = image_manager._path_to_hash

	var data := {
		IMAGES: img_dict,
		TAGS: tag_dict,
		INDEX: index,
		FAVORITES: favorites
	}
	
	return data

func deserialize(data: Dictionary) -> void:
	for key in data.get(IMAGES, {}):
		var dat := ImageInfo.new()
		dat.deserialize(data[IMAGES][key])
		image_manager._image_db[key] = dat
	
	for key in data.get(TAGS, {}):
		var dat := TagData.new()
		dat.deserialize(data[TAGS][key])
		tag_manager._tag_db[key] = dat
	
	image_manager._path_to_hash = data.get(INDEX, {})
	favorites = data.get(FAVORITES, [])

#endregion
