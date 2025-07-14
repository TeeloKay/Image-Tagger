extends Node

const TEST_DB_PATH := "e://test_db.db"

@onready var db_bridge: DatabaseBridge

func _ready():
	db_bridge = DatabaseBridge.new()
	add_child(db_bridge)
	if !db_bridge.is_node_ready():
		await db_bridge.ready
	run_tests()
	

func run_tests():
	print("--- Starting DatabaseBridge Tests ---")

	var image_hash := "abc123"
	var path := "e://images/sample.png"
	var fingerprint := "fp_001"
	var tags := [&"tag1", &"tag2", &"tag3"]

	# 1. Open test database
	db_bridge.open_database(TEST_DB_PATH)
	# await db_bridge.database_loaded
	print("✅ Database loaded")

	# 2. Add image
	db_bridge.add_image(image_hash, path, fingerprint)
	print("✅ Image added")

	# 3. Add tags
	for tag: StringName in tags:
		db_bridge.add_tag(tag, Color(1, 0, 0)) # red
	print("✅ Tags added")

	# 4. Tag image
	for tag: StringName in tags:
		db_bridge.tag_image(image_hash, tag)
	print("✅ Image tagged")

	# 5. Verify tag retrieval
	var fetched_tags := db_bridge.get_tags_for_image(image_hash)
	print("Fetched tags:", fetched_tags)
	assert(fetched_tags.size() == tags.size())
	for tag in fetched_tags:
		assert(tag in tags)
	print("✅ Tags verified")

	# 6. Untag image
	db_bridge.untag_image(image_hash, "tag2")
	var updated_tags := db_bridge.get_tags_for_image(image_hash)
	print("After untagging:", updated_tags)
	assert(!updated_tags.has("tag2"))
	assert(updated_tags.size() == 2)
	print("✅ Tag untagging verified")

	# 7. Update image path
	var new_path := "user://images/new_sample.png"
	db_bridge.update_image_path(image_hash, new_path)
	var image_info := db_bridge.get_image_info(image_hash)
	assert(image_info != null)
	assert(image_info.last_path == new_path)
	print("✅ Image path update verified")

	# 8. Check tag string update
	print(image_info.tags)
	assert(image_info.tags.size() == 2)
	assert(&"tag2" not in image_info.tags)
	print("✅ Tag string column updated correctly")

	print("--- All tests passed ---")
