class_name SearchEngine extends Node

var project: ProjectData:
	set = set_project

var _thread: Thread
var _mutex: Mutex
var _semaphore: Semaphore
var _cancelled := false

var use_threading: bool = true

signal search_started
signal search_result(result: SearchResult)
signal search_finished
## Returns start_search progress as a value from 0 - 1
signal search_progress(progress: float)
signal search_cancelled


signal search_completed(results: Array[SearchResult])

func _ready() -> void:
	_thread = Thread.new()

func set_project(_project: ProjectData) -> void:
	project = _project

func start_search(query: SearchQuery) -> void:
	if project == null:
		return
	search_started.emit()
	var hashes: Array[String] = []

	# Phase 1: retrieve all matching hashes based on inclusive and exclusive tags
	var matches := find_hashes_by_tags(query.inclusive_tags, [])
	
	# Phase 2: validate last paths for matches

	var search_list: Array[String] = []
	var found_list: Dictionary[String, String] = {}

	for file_hash in matches:
		var path := project.get_path_for_hash(file_hash)
		path = project.to_abolute_path(path)
		print(path)
		if !FileAccess.file_exists(path):
			search_list.append(file_hash)
			continue
		found_list[file_hash] = path
		
	for file_hash in found_list:
		var result := SearchResult.new(found_list[file_hash], file_hash)
		print(result.image_hash, result.path)
		search_result.emit(result)

func find_hashes_by_tags(inclusive_tags: Array[StringName], exclusive_tags: Array[StringName]) -> PackedStringArray:
	var matches: PackedStringArray = []
	for file_hash in project.image_db.get_images():
		var tags := project.get_image_data(file_hash).tags

		if inclusive_tags.all(func(t: StringName) -> bool: return tags.has(t)) \
		&& exclusive_tags.all(func(t: StringName) -> bool: return !tags.has(t)) \
		:
			matches.append(file_hash)
	return matches

func validate_paths(hashes: PackedStringArray) -> Dictionary:
	var results := {}
	var to_search := []
	for file_hash: String in hashes:
		var path := project.get_image_data(file_hash).last_path
		if FileAccess.file_exists(path):
			results[hash] = path
		else:
			to_search.append(hash)
	return {"found": results, "missing": to_search}
