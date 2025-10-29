extends Node2D
@onready var background_layer: CanvasLayer = %BackgroundLayer
@onready var context_layer: CanvasLayer = %ContextLayer
@onready var tool_tip_layer: CanvasLayer = %ToolTipLayer
@onready var pop_tip_layer: CanvasLayer = %PopTipLayer
func get_input_dir() -> float:
		return  Input.get_axis(
			"ui_left",
			"ui_right"
			)

func _ready() -> void:
	BlackboardController.global_bb_init()
	BlackboardController.add_data_to_global_bb("bb:canvases", {
		"canvas:background_layer" : background_layer,
		"canvas:context_layer" : context_layer,
		"canvas:tool_tip_layer" : tool_tip_layer,
		"canvas:pop_tip_layer" : pop_tip_layer,
	})

	var canvases : Dictionary = BlackboardController.get_data_by_global_bb("bb:canvases")
	var canvas : CanvasLayer = canvases["canvas:background_layer"]
	canvas.layer = 99
