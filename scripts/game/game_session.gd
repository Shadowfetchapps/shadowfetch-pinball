extends Node

const Types = preload("res://scripts/pin/pin_types.gd")

var mode: Types.Mode = Types.Mode.CLASSIC
var self_test: bool = false


func reset_defaults() -> void:
	mode = Types.Mode.CLASSIC
	self_test = false


func mode_name() -> String:
	return Types.mode_name(mode)
