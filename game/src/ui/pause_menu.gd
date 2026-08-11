class_name PauseMenu
extends CanvasLayer
## Pause overlay. Runs in PROCESS_MODE_ALWAYS so it works while the tree is
## paused: resume, restart from checkpoint, options, quit to title, quit.

@onready var overlay: Control = %Overlay
@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var options_button: Button = %OptionsButton
@onready var quit_title_button: Button = %QuitTitleButton
@onready var quit_button: Button = %QuitButton
@onready var options_panel: Control = %OptionsPanel

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"

var is_open := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	options_panel.visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_title_button.pressed.connect(_on_quit_title_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		_toggle()

func _toggle() -> void:
	is_open = not is_open
	overlay.visible = is_open
	get_tree().paused = is_open
	if is_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		EventBus.game_paused.emit()
		resume_button.grab_focus()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		EventBus.game_unpaused.emit()

func _on_resume_pressed() -> void:
	if is_open:
		_toggle()

func _on_restart_pressed() -> void:
	if is_open:
		_toggle()
	CheckpointManager.respawn_from_checkpoint()

func _on_options_pressed() -> void:
	options_panel.visible = not options_panel.visible
	if options_panel.visible:
		options_panel.grab_focus()

func _on_quit_title_pressed() -> void:
	get_tree().paused = false
	is_open = false
	overlay.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()
