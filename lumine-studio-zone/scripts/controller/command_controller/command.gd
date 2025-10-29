# Command.gd
@abstract
class_name Command extends Object

@abstract
func execute() -> void

@abstract
func undo() -> void

func get_name() -> String:
	return "Command"

func get_description() -> String:
	return "Default command"
