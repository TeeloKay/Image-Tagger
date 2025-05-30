class_name ThumbnailGenerator extends RefCounted

var max_size: Vector2 = Vector2(128,128)

func generate(image: Image) -> Texture2D:
	var size := image.get_size()
	var scale = min(max_size.x / size.x, max_size.y / size.y)
	var thumb_size = (size * scale).floor()
	
	image.resize(thumb_size.x,thumb_size.y, image.INTERPOLATE_BILINEAR)
	return ImageTexture.create_from_image(image)
