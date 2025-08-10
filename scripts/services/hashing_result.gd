class_name HashingResult extends RefCounted

var file_path: String
var file_hash: String
var fingerprint: String

func _init(file_path: String, file_hash: String, fingerprint: String) -> void:
    self.file_path = file_path
    self.file_hash = file_hash
    self.fingerprint = fingerprint