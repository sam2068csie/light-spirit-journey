extends HSlider
## 手機友善的滑桿：直接看手指「現在在哪裡」決定數值（不用相對位移推算，觸控模擬滑鼠時也不會亂跳）
## 用 UITheme.touch_slider() 建立。

var _drag := false

func _gui_input(e: InputEvent) -> void:
	if not editable:
		return
	var x := NAN
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_drag = e.pressed
		if e.pressed:
			x = e.position.x
	elif e is InputEventMouseMotion:
		if not _drag:
			return
		x = e.position.x
	elif e is InputEventScreenTouch:
		_drag = e.pressed
		if e.pressed:
			x = e.position.x
	elif e is InputEventScreenDrag:
		if not _drag:
			return
		x = e.position.x
	else:
		return
	if not is_nan(x):
		var gw := float(get_theme_icon("grabber").get_width())
		var area := maxf(1.0, size.x - gw)
		set_as_ratio(clampf((x - gw / 2.0) / area, 0.0, 1.0))
	accept_event()
