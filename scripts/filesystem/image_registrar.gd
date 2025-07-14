class_name ImageRegistrar extends Node

var project: ProjectData
@export var file_hasher: ImageHasher

signal image_registered(file_hash: String, file_path: String)

func _ready() -> void:
    if file_hasher:
        file_hasher.file_hashed.connect(_on_file_hashed)

func _on_file_hashed(path: String, file_hash: String) -> void:
    if project.image_db.has(file_hash):
        return
    
    var image_data := ImageData.new()
    var fingerprint := file_hasher.fingerprint_file(path)

    image_data.fingerprint = fingerprint
    image_data.last_path = project.to_relative_path(path)
    print(image_data.last_path)
    project.image_db.register_image(path, file_hash, image_data)

    image_registered.emit(file_hash, path)

func register_image(path: String) -> void:
    ProjectManager.file_hasher.hash_file(path)