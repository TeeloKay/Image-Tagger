class_name ProgressPopup extends Window

@onready var Label_status: Label = %Label
@onready var progress_bar: ProgressBar = %ProgressBar

@export var total_jobs := 0:
	set = set_total_jobs
@export var current_index := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_total_jobs(count: int) -> void:
	total_jobs = count
	current_index = 0
	progress_bar.max_value = total_jobs
	progress_bar.value = current_index

func increment() -> void:
	current_index += 1
	progress_bar.value = current_index

func finish() -> void:
	progress_bar.value = total_jobs
