class_name SearchEngine extends Node

var _db: DatabaseAdapter
var _thread: Thread
var _mutex: Mutex
var _semaphore: Semaphore
var _cancelled := false

var use_threading: bool = true

signal search_started
signal search_result(result: SearchResult)
signal search_finished
## Returns start_search progress as a value from 0 - 1

signal search_completed(results: Array[SearchResult])

func _ready() -> void:
	_thread = Thread.new()

func set_database(db: DatabaseAdapter) -> void:
	_db = db

func start_search(query: SearchQuery) -> void:
	search_started.emit()

	# Phase 1: retrieve all matching hashes based on inclusive and exclusive tags
	var db_results: Array[ImageData] = ProjectContext.db.search(query)
	
	print("db search results: ", db_results.size())
	# Phase 2: validate last paths for matches
	var valid_results: Dictionary[String, String] = {}
	var missing_hashes: Array[String] = []

	for result in db_results:
		var path := result.last_path
		path = ProjectContext.to_abolute_path(path)
		if !FileAccess.file_exists(path):
			missing_hashes.append(result.image_hash)
			continue
		valid_results[result.image_hash] = path
	
	# Emit signals for all valid found results
	for file_hash in valid_results:
		var result := SearchResult.new(valid_results[file_hash], file_hash)
		search_result.emit(result)

	# look for untracked files.
	if !query.filter.is_empty() && query.inclusive_tags.is_empty():
		var untracked_results := scan_for_untracked_files(query.filter)
		print("untracked search result size: ", untracked_results.size())
		for file in untracked_results:
			var result := SearchResult.new(file, "");
			search_result.emit(result)

	search_finished.emit()


func scan_for_missing_files(hashes: Array[String]) -> Dictionary:
	var results: Dictionary

	return results;

func scan_for_untracked_files(name_filter: String) -> PackedStringArray:
	name_filter = name_filter.strip_edges().to_lower()
	var source_dir: String = ProjectContext.project_path

	var files: PackedStringArray = []

	_scan_for_untracked_files_recursively(source_dir, name_filter, files)

	return files

func _scan_for_untracked_files_recursively(dir_path: String, name_filter: String, files: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Failed to open directory: ", dir_path)
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		
		var full_path := dir_path.path_join(file_name)

		if dir.current_is_dir():
			_scan_for_untracked_files_recursively(full_path, name_filter, files)
		else:
			if ImageUtil.is_valid_image(file_name):
				if full_path.to_lower().contains(name_filter):
					files.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()
