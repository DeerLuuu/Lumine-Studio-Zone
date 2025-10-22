extends Node

var _event_metadata: Dictionary = {}
var _sorted_connections_cache: Dictionary = {}
var _connection_cache_dirty: Dictionary = {}

## 信号：事件被推送时触发
signal event_pushed(event_name: String, payload: Array)
## 信号：事件处理完成时触发
signal event_handled(event_name: String, payload: Array)

## 推送事件
func push_event(
	event_name: String,
	payload: Variant = [],
	immediate: bool = true,
	emit_signals: bool = true
) -> void:
	if not payload is Array:
		payload = [payload]

	if emit_signals:
		event_pushed.emit(event_name, payload)

	if not _event_metadata.has(event_name):
		if not emit_signals: return
		event_handled.emit(event_name, payload)
		return

	var connections = _get_sorted_connections(event_name)
	var filtered_connections: Array = []
	var to_disconnect: Array = []

	for conn in connections:
		var callable = conn["callable"]
		if not callable.is_valid():
			to_disconnect.append(conn)
			continue

		var object = callable.get_object()
		var method = callable.get_method()

		if not is_instance_valid(object):
			to_disconnect.append(conn)
			continue

		var obj_id = _get_object_id(object, method)
		var metadata = _event_metadata[event_name].get(obj_id, null)

		if metadata:
			var filter_callable = metadata["filter"]
			if filter_callable.is_valid() and not filter_callable.call(payload):
				continue
			if metadata["once"]:
				to_disconnect.append(conn)

		filtered_connections.append(conn)

	for conn in filtered_connections:
		if immediate:
			if conn["callable"].is_valid():
				conn["callable"].callv(payload)
		else:
			_schedule_deferred_call(conn["callable"], payload)

	for conn in to_disconnect:
		var callable = conn["callable"]
		var object = callable.get_object()
		var method = callable.get_method()

		if is_instance_valid(object):
			disconnect(event_name, callable)

		var obj_id = _get_object_id(object, method)
		if _event_metadata[event_name].has(obj_id):
			_event_metadata[event_name].erase(obj_id)
			if _event_metadata[event_name].is_empty():
				_event_metadata.erase(event_name)
				_sorted_connections_cache.erase(event_name)
				_connection_cache_dirty.erase(event_name)

	if _event_metadata.has(event_name) and _event_metadata[event_name].is_empty():
		_event_metadata.erase(event_name)
		_sorted_connections_cache.erase(event_name)
		_connection_cache_dirty.erase(event_name)

	if emit_signals:
		event_handled.emit(event_name, payload)

## 订阅事件
func subscribe(
	event_name: String,
	callback: Callable,
	priority: int = 0,
	once: bool = false,
	filter: Callable = func(_p): return true
) -> void:
	if not callback.is_valid():
		push_error("[EventBus] Invalid callback provided for event: %s" % event_name)
		return

	if not has_signal(event_name):
		add_user_signal(event_name)

	# 防止重复订阅
	for conn in get_signal_connection_list(event_name):
		if conn["callable"] == callback:
			push_warning("Callback already subscribed to event: %s" % event_name)
			return

	connect(event_name, callback)

	var object = callback.get_object()
	var method = callback.get_method()
	var obj_id = _get_object_id(object, method)

	if not _event_metadata.has(event_name):
		_event_metadata[event_name] = {}

	_event_metadata[event_name][obj_id] = {
		"priority": priority,
		"once": once,
		"filter": filter
	}

	_mark_cache_dirty(event_name)

## 一次性订阅
func subscribe_once(
	event_name: String,
	callback: Callable,
	priority: int = 0,
	filter: Callable = func(_p): return true
) -> void:
	subscribe(event_name, callback, priority, true, filter)

## 取消订阅
func unsubscribe(event_name: String, callback: Callable) -> void:
	if not has_signal(event_name) or not is_connected(event_name, callback):
		return

	disconnect(event_name, callback)

	var object = callback.get_object()
	var method = callback.get_method()
	var obj_id = _get_object_id(object, method)

	if _event_metadata.has(event_name) and _event_metadata[event_name].has(obj_id):
		_event_metadata[event_name].erase(obj_id)
		if _event_metadata[event_name].is_empty():
			_event_metadata.erase(event_name)
			_sorted_connections_cache.erase(event_name)
			_connection_cache_dirty.erase(event_name)
	_mark_cache_dirty(event_name)

## 取消对象所有订阅
func unsubscribe_all(callback: Callable) -> void:
	for event_name in _event_metadata.keys():
		if is_connected(event_name, callback):
			disconnect(event_name, callback)
			var obj_id = _get_object_id(callback.get_object(), callback.get_method())
			if _event_metadata.has(event_name) and _event_metadata[event_name].has(obj_id):
				_event_metadata[event_name].erase(obj_id)
				if _event_metadata[event_name].is_empty():
					_event_metadata.erase(event_name)
				_mark_cache_dirty(event_name)

## 移除所有 事件管线 的链接
func clear_subscriptions_for_object(object: Object) -> void:
	for event_name in _event_metadata.keys():
		var metadata = _event_metadata[event_name]
		var keys = metadata.keys()
		for obj_id in keys:
			var parts = obj_id.split("_")
			if parts.size() < 2: continue
			if int(parts[0]) != object.get_instance_id(): continue
			var method = parts[1]
			disconnect(event_name, Callable(object, method))
			metadata.erase(obj_id)
			if metadata.is_empty():
				_event_metadata.erase(event_name)
			_mark_cache_dirty(event_name)

## 获取订阅者数量
func get_subscriber_count(event_name: String) -> int:
	if not _event_metadata.has(event_name): return 0
	return get_signal_connection_list(event_name).size()

## 内部：生成唯一ID
func _get_object_id(object: Object, method: StringName) -> String:
	if not is_instance_valid(object):
		push_warning("Invalid object passed to _get_object_id")
		return "invalid"
	return "%d_%s" % [object.get_instance_id(), method]

## 内部：标记缓存脏
func _mark_cache_dirty(event_name: String) -> void:
	_connection_cache_dirty[event_name] = true

## 内部：获取已排序连接
func _get_sorted_connections(event_name: String) -> Array:
	if not _connection_cache_dirty.get(event_name, true):
		return _sorted_connections_cache[event_name]

	var connections = get_signal_connection_list(event_name)
	if connections.size() == 0:
		_sorted_connections_cache[event_name] = []
		return []

	_sorted_connections_cache[event_name] = _sort_connections_by_priority(event_name, connections)
	_connection_cache_dirty[event_name] = false
	return _sorted_connections_cache[event_name]

## 内部：按优先级排序
func _sort_connections_by_priority(event_name: String, connections: Array) -> Array:
	var metadata = _event_metadata.get(event_name, {})
	var result = connections.duplicate()
	result.sort_custom(func(a, b):
		var get_prio = func(conn):
			var obj = conn["callable"].get_object()
			var meth = conn["callable"].get_method()
			var id = _get_object_id(obj, meth)
			if metadata.has(id): return metadata[id]["priority"]
			return 0
		var a_p = get_prio.call(a)
		var b_p = get_prio.call(b)
		return b_p - a_p
	)
	return result

## 内部：延迟调用
func _schedule_deferred_call(callable: Callable, payload: Array) -> void:
	call_deferred("_do_deferred_call", callable, payload.duplicate(true))

func _do_deferred_call(callable: Callable, payload: Array) -> void:
	if not callable.is_valid() or not is_instance_valid(callable.get_object()):
		return
	callable.callv(payload)
