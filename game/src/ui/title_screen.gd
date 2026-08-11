class_name TitleScreen
extends Control
## Main menu / title screen. Starts a new game, opens options, or quits.

const CHAPTER_SCENE := "res://scenes/world/chapter2_choir_below.tscn"

@onready var start_button: Button = %StartButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var options_panel: Control = %OptionsPanel

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	start_button.grab_focus()

func _on_start_pressed() -> void:
	GameState.start_new_game()
	EventBus.scene_loading.emit(CHAPTER_SCENE)
	get_tree().change_scene_to_file(CHAPTER_SCENE)

func _on_options_pressed() -> void:
	options_panel.visible = not options_panel.visible
	if options_panel.visible:
		options_panel.grab_focus()

func _on_quit_pressed() -> void:
	get_tree().quit()
