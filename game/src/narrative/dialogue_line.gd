class_name DialogueLine
extends RefCounted
## One spoken subtitle line for the DialogueRunner. `seconds` of 0.0 means the
## runner derives a reading duration from the text length; empty text is a
## silence beat (cut-off, held pause).

var speaker := ""
var text := ""
var seconds := 0.0

func _init(line_speaker: String = "", line_text: String = "", line_seconds: float = 0.0) -> void:
	speaker = line_speaker
	text = line_text
	seconds = line_seconds

func is_silence() -> bool:
	return text.strip_edges() == ""
