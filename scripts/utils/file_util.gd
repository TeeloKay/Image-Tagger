class_name FileUtil extends Object

const KB := 1024
const MB := 1024 * KB
const GB := 1024 * MB
const TB := 1024 * GB

static func human_readable_size(size_bytes: int, precision: int = 2) -> String:
	if size_bytes < KB:
		return "%d B" % size_bytes
	if size_bytes < MB:
		return "%.*f KB" % [precision, (size_bytes / float(KB))]
	if size_bytes < GB:
		return "%.*f MB" % [precision, (size_bytes / float(MB))]
	return "%.*f GB" % [precision, (size_bytes / float(GB))]