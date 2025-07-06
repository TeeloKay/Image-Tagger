class_name ProjectIO extends RefCounted

const VERSION := "version"
const PROJECT_DIR := ".artmeta"
const PROJECT_FILE := "project.json"
const INDEX_FILE := "index.json"

const FAVORITES := "favorites"
const IMAGES := "image_data"
const TAGS := "tag_data"

## Saves the project data and its index separately inside the .artmeta directory.
func save_project(project: ProjectData) -> void:
	var version := str(ProjectSettings.get_setting("application/config/version"))
	var project_data := {
		VERSION = version,
		FAVORITES = project.favorites,
		IMAGES = project.image_db.serialize(),
		TAGS = project.tag_db.serialize()
		}
	var index_data: Dictionary = project.index.serialize()

	_save_data_as_json(project_data, project.project_path, PROJECT_FILE)
	_save_data_as_json(index_data, project.project_path, INDEX_FILE)

## Loads a ProjectData instance from disk, including index data.
func load_project(path: String) -> ProjectData:
	var project := ProjectData.new()
	project.project_path = path

	var project_data := _load_data_from_json(path.path_join(PROJECT_DIR).path_join(PROJECT_FILE))
	var index_data := _load_data_from_json(path.path_join(PROJECT_DIR).path_join(INDEX_FILE))

	project.image_db.deserialize(project_data.get(IMAGES, {}))
	project.tag_db.deserialize(project_data.get(TAGS, {}))
	project.favorites = project_data.get(FAVORITES, [])
	project.index.deserialize(index_data)

	return project

## Helper to save a Dictionary/Variant as a JSON file to a project’s data folder.
func _save_data_as_json(data: Variant, project_path: String, file_name: String) -> void:
	var dir_path := project_path.path_join(PROJECT_DIR)
	var file_path := dir_path.path_join(file_name)
	var json := JSON.stringify(data, "\t")

	# Ensure the .artmeta directory exists
	var dir := DirAccess.open(project_path)
	if dir == null:
		printerr("Failed to access directory: ", project_path)
		return
	if !dir.dir_exists(PROJECT_DIR):
		var err = dir.make_dir(PROJECT_DIR)
		if err != OK:
			printerr("Failed to create project metadata folder: ", dir_path)
			return

	# Write the file
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		printerr("Failed to save data to ", file_path)
		return

	file.store_string(json)
	file.close()

## Helper to load JSON data from a given file path.
func _load_data_from_json(file_path: String) -> Dictionary:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open file: ", file_path)
		return {}

	var content := file.get_as_text()
	var result = JSON.parse_string(content)
	if result == null:
		printerr("JSON parsing failed for: ", file_path)
		return {}

	return result
