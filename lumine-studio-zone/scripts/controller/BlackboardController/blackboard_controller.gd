extends Node

var _all_black_board : Dictionary[String, Blackboard]

var _global_bb : Blackboard

# FUNC 初始化全局黑板
func global_bb_init() -> void:
	_global_bb = Blackboard.new("")

# FUNC 向全局黑板添加数据
func add_data_to_global_bb(k : String, v : Variant) -> void:
	_global_bb.add_value(k, v)

func set_data_to_global_bb(k : String, v : Variant) -> void:
	_global_bb.set_value(k, v)

func get_data_by_global_bb(k : String) -> Variant:
	return _global_bb.get_value(k)

func remove_data_by_global_bb(k: String) -> void:
	_global_bb.remove(k)

# FUNC 添加黑板
func add_bb(bb_name : String, bb : Blackboard) -> bool:
	if bb in _all_black_board.values(): return false
	if bb_name in _all_black_board.keys(): return false
	_all_black_board[bb_name] = bb
	return true

# FUNC 根据黑板名称移除黑板
func remove_bb_by_name(bb_name : String) -> bool:
	if find_bb_by_name(bb_name): return false
	var bb : Blackboard = _all_black_board[bb_name]
	_all_black_board.erase(bb_name)
	bb.free()
	return true

# FUNC 移除黑板
func remove_bb(bb : Blackboard) -> bool:
	if find_bb(bb): return false
	_all_black_board.erase(bb)
	bb.free()
	return true

# FUNC 是否存在对应名称的黑板
func find_bb_by_name(bb_name : String) -> bool:
	return bb_name in _all_black_board.keys()

# FUNC 是否存在黑板
func find_bb(bb : Blackboard) -> bool:
	return bb in _all_black_board.values()

# FUNC 清除对应黑板的数据
func clear_bb_data(bb_name : String) -> void:
	if find_bb_by_name(bb_name):
		_all_black_board[bb_name].clear()

# FUNC 清楚所有黑板的数据
func clear_all_bb_data() -> void:
	for bb : Blackboard in _all_black_board.values():
		bb.clear()
