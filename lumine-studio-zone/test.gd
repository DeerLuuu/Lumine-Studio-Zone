extends Node2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var text_edit: TextEdit = $TextEdit

var text_arr : Array
var undo_text_arr : Array

func _ready() -> void:
	EventController.subscribe("signal:command_executed", _on_command_executed)
	EventController.subscribe("signal:command_undone", _on_command_undone)
	EventController.subscribe("signal:command_redone", _on_command_redone)

func _process(_delta: float) -> void:
	var dir : Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir != Vector2.ZERO: move_excuted(dir)
	if Input.is_action_pressed("ui_accept"): move_undo()
	if Input.is_action_pressed("ui_cancel"): move_redo()

func move_excuted(vec : Vector2) -> void:
	var command = MoveCommand.new(sprite_2d, sprite_2d.global_position, vec * 30)
	CommandController.execute(command)

func move_undo() -> void:
	CommandController.undo()

func move_redo() -> void:
	CommandController.redo()

func _on_command_executed(command: Command) -> void:
	text_arr.append(command.get_description())
	var text : String
	for i in text_arr: text = text + i + "\n"
	text_edit.text = text

func _on_command_undone() -> void:
	undo_text_arr.append(text_arr.pop_back())
	var text : String
	for i in text_arr: text = text + i + "\n"
	text_edit.text = text

func _on_command_redone() -> void:
	text_arr.append(undo_text_arr.pop_back())
	var text : String
	for i in text_arr: text = text + i + "\n"
	text_edit.text = text
