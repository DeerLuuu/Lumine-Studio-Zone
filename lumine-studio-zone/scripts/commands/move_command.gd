class_name MoveCommand extends Command

var target: Node2D = null
var original_position: Vector2 = Vector2.ZERO
var move_amount: Vector2

func _init(_target: Node2D, _original_position: Vector2, _move_amount : Vector2) -> void:
	self.target = _target
	self.original_position = _original_position
	self.move_amount = _move_amount

func execute() -> void:
	target.global_position = target.global_position + move_amount

func undo() -> void:
	target.global_position = original_position

func get_name() -> String:
	return "Move Sprite"

func get_description() -> String:
	return "Move sprite by %s" % move_amount
