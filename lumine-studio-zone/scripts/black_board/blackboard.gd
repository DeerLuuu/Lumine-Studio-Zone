class_name Blackboard extends Object

var _data: Dictionary = {}
var bb_name : String

func _init(_bb_name : String) -> void:
	bb_name = _bb_name

func clear() -> void:
	_data = {}

func add_value(key: String, value : Variant) -> void:
	if _data.has(key):
		if _data[key] == value: return
		set_value(key, value)
		return

	_data[key] = value
	push_event("event:blackboard_key_changed", [key, value])

func set_value(key: String, value: Variant) -> bool:
	if _data.has(key) and _data[key] == value:
		return false

	var old_value = _data.get(key)
	_data[key] = value

	push_event("event:blackboard_key_changed", [key, value, old_value])
	return true

func get_value(key: String, default: Variant = null) -> Variant:
	return _data.get(key, default)

func remove(key: String) -> bool:
	if _data.has(key):
		_data.erase(key)
		return true
	return false

func has_key(key: String) -> bool:
	return _data.has(key)

func push_event(event_name: String,
	payload: Variant = [],
	immediate: bool = true,
	emit_signals: bool = true
	) -> void:
		var _str : String = ":" + bb_name if not bb_name.is_empty() else ""
		EventController.push_event(event_name + _str, payload, immediate, emit_signals)
