class_name ProjectData extends Resource

const FAVORITES 	:= "favorites"
const IMAGES 		:= "image_data"
const TAGS 			:= "tag_data"
const INDEX 		:= "index"

## Absolute project path
@export var project_path: String = ""

# Image data dictionary <hash, image info>
var image_data : Dictionary[String, ImageInfo] = {}
# tag data, <tag, tag data>
var tag_data : Dictionary[StringName, TagData] = {}
# path to hash table: <hash, relative path>
var path_to_hash: Dictionary[String,String] = {}

# hashes
@export var favorites: Array = []
@export var folder_tags: Dictionary

signal index_updated


func add_image(hash: String, path: String) -> void:
	var rel_path = to_relative_path(path)
	if !image_data.has(hash):
		var info = ImageInfo.new()
		info.last_path = rel_path
		image_data[hash] = info
	path_to_hash[rel_path] = hash

#region Tags

func set_tags_for_hash(hash: String, tags: Array[StringName]) -> void:
	if image_data.has(hash):
		image_data[hash].tags = tags
	for tag in tags:
		if !tag in tag_data:
			add_tag(tag)
		tag_data[tag].add_hash(hash)

func tag_image_by_hash(hash: String, tag: StringName) -> void:
	if tag.is_empty() || !image_data.has(hash):
		return
	image_data[hash].add_tag(tag)
	add_tag(tag)
	tag_data[tag].add_hash(hash)

func untag_image_by_hash(hash: String, tag: StringName) -> void:
	if tag.is_empty() || !image_data.has(hash):
		return
	image_data[hash].remove_tag(tag)
	tag_data[hash].remove_hash(hash)

func get_tags_for_hash(hash: String) -> Array[StringName]:
	if image_data.has(hash):
		return image_data[hash].tags.duplicate()
	return []

func get_images_with_tag(tag: StringName) -> PackedStringArray:
	var results : PackedStringArray = []
	for hash in image_data.keys():
		if image_data[hash].tags.has(tag):
			results.append(hash)
	return results

func get_tags() -> Array[StringName]:
	return tag_data.keys()

func get_tag_data(tag: StringName) -> TagData:
	return tag_data[tag] if tag_data.has(tag) else TagData.new()

func add_tag(tag: StringName) -> void:
	if !tag_data.has(tag):
		tag_data[tag] = TagData.new()
		
#endregion
#region Favorites

func add_to_favorites(hash: String) -> void:
	if !favorites.has(hash):
		favorites.append(hash)

func remove_from_favorites(hash: String) -> void:
	if favorites.has(hash):
		favorites.erase(hash)

func is_favorited(hash: String) -> bool:
	return favorites.has(hash)

#endregion
#region Data Access

func get_hash_for_path(image_path: String) -> String:
	var rel_path := to_relative_path(image_path)
	if path_to_hash.has(rel_path):
		return path_to_hash[to_relative_path(rel_path)]
	return ProjectManager.image_hasher.hash_image(image_path)

func get_path_for_hash(hash: String) -> String:
	return image_data.get(hash, "")

func get_info_for_hash(hash: String) -> ImageInfo:
	return image_data.get(hash,null)

func move_image_data(old_path: String, new_path: String) -> void:
	old_path = to_relative_path(old_path)
	new_path = to_relative_path(new_path)

	if old_path == new_path || !path_to_hash.has(old_path):
		return
	var hash := path_to_hash[old_path]
	var data = image_data[old_path]
	path_to_hash.erase(old_path)
	path_to_hash[new_path] = hash
	image_data[hash].last_path = new_path

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
	return image_data.keys()

#endregion
#region Serialization

func serialize() -> Dictionary:
	var img_dict := {}
	var tag_dict := {}
	
	for key in image_data:
		img_dict[key] = image_data[key].serialize()
		
	for key in tag_data:
		tag_dict[key] = tag_data[key].serialize()
		
	var data := {
		IMAGES: img_dict,
		TAGS: tag_dict,
		INDEX: path_to_hash,
		FAVORITES: favorites
	}
	
	return data

func deserialize(data: Dictionary) -> void:
	for key in data.get(IMAGES, {}):
		var dat := ImageInfo.new()
		dat.deserialize(data[IMAGES][key])
		image_data[key] = dat
	
	for key in data.get(TAGS, {}):
		var dat := TagData.new()
		dat.deserialize(data[TAGS][key])
		tag_data[key] = dat
	
	for path in data.get(INDEX, {}):
		path_to_hash[path] = data[INDEX][path]
	favorites = data.get(FAVORITES, [])

#endregion
