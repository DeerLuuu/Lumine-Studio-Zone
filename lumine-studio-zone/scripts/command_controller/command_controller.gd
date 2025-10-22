extends Node

var undo_stack: Array[Command] = []
var redo_stack: Array[Command] = []
var max_history_length: int = 500

func execute(command: Command) -> void:
	command.execute()
	undo_stack.append(command)

	if max_history_length > 0 and undo_stack.size() > max_history_length:
		undo_stack.pop_front()

	redo_stack.clear()

	EventController.push_event("command_executed", [command])

func undo() -> void:
	if undo_stack.size() == 0:
		push_warning("Nothing to undo")
		return

	var command = undo_stack.pop_back()
	command.undo()
	redo_stack.append(command)

	EventController.push_event("command_undone")

func redo() -> void:
	if redo_stack.size() == 0:
		push_warning("Nothing to redo")
		return

	var command = redo_stack.pop_back()
	command.execute()
	undo_stack.append(command)

	EventController.push_event("command_redone")
