extends Node2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var text_edit: TextEdit = $TextEdit

var text_arr : Array
var undo_text_arr : Array
var bb : Blackboard
var a : int = 0

func _ready() -> void:
	BlackboardController.global_bb_init()
	bb = Blackboard.new("test")
	EventController.subscribe("event:blackboard_key_changed:test", aaa)
	EventController.subscribe("event:blackboard_key_changed", bbb)
	EventController.subscribe("event:command_executed", _on_command_executed)
	EventController.subscribe("event:command_undone", _on_command_undone)
	EventController.subscribe("event:command_redone", _on_command_redone)

func aaa(key : String, value : Variant, old_value : Variant) -> void:
		print(key, value)

func bbb(key : String, value : Variant, old_value : Variant) -> void:
		print("这是测试" + key, value)

func _process(_delta: float) -> void:
	bb.add_value("bb:dir", Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down"))
	if bb._data["bb:dir"] != Vector2.ZERO: move_excuted(bb._data["bb:dir"])
	if Input.is_action_just_pressed("ui_accept"):
		a += 1
		BlackboardController.set_data_to_global_bb("bb:dir", Vector2(12 + a, 12 + a))
		move_undo()
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
