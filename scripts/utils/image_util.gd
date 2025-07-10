class_name ImageUtil extends Object

const ACCEPTED_TYPES: PackedStringArray = ["jpg","jpeg","png","webp","gif","tga"]
const THUMB_SIZE: Vector2 = Vector2(128,128)

static func load_image(abs_path: String) -> Texture2D:
	var type := abs_path.get_extension()
	if !type in ACCEPTED_TYPES:
		return null
	if type == "gif":
		return _load_gif(abs_path)
	return _load_image(abs_path)

static func _load_gif(path: String) -> AnimatedTexture:
	return GifManager.animated_texture_from_file(path)

static func _load_image(path: String) -> Texture2D:
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		push_warning("Failed to load full image for preview: %s" % path)
		return null
	
	return ImageTexture.create_from_image(img)

static func generate_thumbnail_from_path(path: String) -> Texture2D:
	var type := path.get_extension()
	if !type in ACCEPTED_TYPES:
		return null
	if type == "gif":
		var tex := _load_gif(path)
		return generate_thumbnail_from_texture(tex.get_frame_texture(0))
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		return null
	return generate_thumbnail(img)

static func generate_thumbnail_from_texture(texture: Texture2D) -> Texture2D:
	if texture is AnimatedTexture:
		texture = texture.get_frame_texture(0)
	var img := texture.get_image()
	return generate_thumbnail(img)

static func generate_thumbnail(image: Image) -> Texture2D:
	var size := image.get_size()
	var scale : float = min(THUMB_SIZE.x / size.x, THUMB_SIZE.y / size.y)
	var thumb_size := (size * scale).floor()
	
	image.resize(thumb_size.x,thumb_size.y, image.INTERPOLATE_BILINEAR)
	return ImageTexture.create_from_image(image)

static func is_valid_image(file_name: String) -> bool:
	return file_name.get_extension() in ACCEPTED_TYPES
