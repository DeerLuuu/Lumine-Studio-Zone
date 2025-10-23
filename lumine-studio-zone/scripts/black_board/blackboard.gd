class_name Blackboard extends Object

var _data: Dictionary = {}

func add_value(key: String, value : Variant) -> void:
	if _data.has(key):
		if _data[key] == value: return
		set_value(key, value)

	_data[key] = value
	EventController.push_event("event:blackboard_key_changed", [key, value])

func set_value(key: String, value: Variant) -> bool:
	if _data.has(key) and _data[key] == value:
		return false

	var old_value = _data.get(key)
	_data[key] = value

	EventController.push_event("event:blackboard_key_changed", [key, value, old_value])
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
