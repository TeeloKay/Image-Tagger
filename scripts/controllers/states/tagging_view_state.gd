class_name TaggingViewState extends Node

var _view: TaggingView
var _controller: TaggingViewController

func initialize(view: TaggingView, controller: TaggingViewController) -> void:
    _view = view
    _controller = controller