class_name TitleCard
extends CanvasLayer
## End-of-slice title card: a full-screen fade with the title, driven by
## EventBus.title_card_requested. Pure overlay — gameplay keeps running behind it
## (the slice keeps the question on screen, not a loading wall).

@export var hold_seconds := 4.0
@export var fade_seconds := 1.0

enum State { IDLE, FADE_IN, HOLD, FADE_OUT }

@onready var overlay: ColorRect = $Overlay
@onready var title_label: Label = $Overlay/TitleLabel

var _state := State.IDLE
var _timer := 0.0

func _ready() -> void:
	overlay.visible = false
	EventBus.title_card_requested.connect(_on_title_card_requested)

func _exit_tree() -> void:
	EventBus.title_card_requested.disconnect(_on_title_card_requested)

func _on_title_card_requested(title: String) -> void:
	title_label.text = title
	overlay.visible = true
	overlay.modulate = Color(0.02, 0.023, 0.027, 0.0)
	title_label.modulate = Color(0.72, 0.95, 0.86, 0.0)
	_timer = 0.0
	_state = State.FADE_IN

func _process(delta: float) -> void:
	match _state:
		State.FADE_IN:
			var t := _timer / fade_seconds
			overlay.modulate.a = t
			title_label.modulate.a = t
			_timer += delta
			if _timer >= fade_seconds:
				_timer = 0.0
				_state = State.HOLD
		State.HOLD:
			_timer += delta
			if _timer >= hold_seconds:
				_timer = 0.0
				_state = State.FADE_OUT
		State.FADE_OUT:
			var t := 1.0 - (_timer / fade_seconds)
			overlay.modulate.a = t
			title_label.modulate.a = t
			_timer += delta
			if _timer >= fade_seconds:
				overlay.visible = false
				_state = State.IDLE
