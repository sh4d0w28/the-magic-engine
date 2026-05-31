extends Node

signal diagram_changed(diagram_result: Dictionary)

var _is_drawing := false
var _points: Array[Vector2] = []
var _last_result := {
	"shape_type": "none",
	"accuracy": 0.0,
	"size": 0.0,
	"point_count": 0
}


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_start_drawing(event.position)
			get_viewport().set_input_as_handled()
		else:
			_finish_drawing()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _is_drawing:
		_points.append(event.position)
		get_viewport().set_input_as_handled()


func get_diagram_result() -> Dictionary:
	return _last_result.duplicate(true)


func _start_drawing(start_position: Vector2) -> void:
	_is_drawing = true
	_points.clear()
	_points.append(start_position)


func _finish_drawing() -> void:
	if not _is_drawing:
		return

	_is_drawing = false
	_last_result = _classify_points()
	diagram_changed.emit(get_diagram_result())


func _classify_points() -> Dictionary:
	if _points.size() < 3:
		return {
			"shape_type": "none",
			"accuracy": 0.0,
			"size": 0.0,
			"point_count": _points.size()
		}

	var min_x := _points[0].x
	var max_x := _points[0].x
	var min_y := _points[0].y
	var max_y := _points[0].y
	var center := Vector2.ZERO
	for point in _points:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)
		center += point

	center /= float(_points.size())
	var width := max_x - min_x
	var height := max_y - min_y
	var max_dimension := max(width, height)
	var size := clamp(max_dimension / 300.0, 0.0, 1.0)
	var closed := _points[0].distance_to(_points[_points.size() - 1]) <= max(20.0, max_dimension * 0.25)

	var radius_sum := 0.0
	for point in _points:
		radius_sum += point.distance_to(center)
	var average_radius := radius_sum / float(_points.size())

	var deviation_sum := 0.0
	var central_point_count := 0
	for point in _points:
		var radius := point.distance_to(center)
		deviation_sum += abs(radius - average_radius)
		if radius <= average_radius * 0.35:
			central_point_count += 1
	var radius_deviation := 0.0
	if average_radius > 0.0:
		radius_deviation = deviation_sum / float(_points.size()) / average_radius

	var corner_count := _estimate_corner_count()
	var central_ratio := float(central_point_count) / float(_points.size())

	if closed and central_ratio >= 0.12 and radius_deviation <= 0.55:
		return {
			"shape_type": "circle_with_dot",
			"accuracy": clamp((1.0 - radius_deviation) * 0.7 + central_ratio, 0.0, 1.0),
			"size": size,
			"point_count": _points.size()
		}

	if closed and corner_count >= 3 and corner_count <= 4:
		return {
			"shape_type": "triangle",
			"accuracy": clamp(1.0 - abs(corner_count - 3) * 0.35, 0.0, 1.0),
			"size": size,
			"point_count": _points.size()
		}

	if closed:
		return {
			"shape_type": "circle",
			"accuracy": clamp(1.0 - radius_deviation, 0.0, 1.0),
			"size": size,
			"point_count": _points.size()
		}

	return {
		"shape_type": "none",
		"accuracy": 0.2,
		"size": size,
		"point_count": _points.size()
	}


func _estimate_corner_count() -> int:
	if _points.size() < 5:
		return 0

	var corner_count := 0
	for index in range(2, _points.size() - 2, 3):
		var previous_direction := (_points[index - 1] - _points[index - 2]).normalized()
		var next_direction := (_points[index + 1] - _points[index]).normalized()
		if previous_direction == Vector2.ZERO or next_direction == Vector2.ZERO:
			continue

		var turn_angle := abs(previous_direction.angle_to(next_direction))
		if turn_angle >= deg_to_rad(35.0):
			corner_count += 1

	return corner_count
