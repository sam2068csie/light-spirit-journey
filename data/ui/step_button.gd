extends Button
## 滑桿旁的 ‹ › 按鈕：按一下調一格；按住不放會連續調整。用 UITheme.add_step_buttons() 建立。

var slider: Range
var dir := 1
var _down := false
var _hold := 0.0

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	button_down.connect(func():
		_down = true
		_hold = 0.0
		_nudge())
	button_up.connect(func(): _down = false)

func _process(delta: float) -> void:
	if not is_instance_valid(slider):
		return
	var room: bool = slider.value < slider.max_value - 1e-9 if dir > 0 else slider.value > slider.min_value + 1e-9
	var can: bool = slider.editable and room
	if disabled == can:
		disabled = not can
	if disabled:
		_down = false
	elif _down:
		_hold += delta
		if _hold > 0.45:      # 按住 0.45 秒後開始連續調整
			_hold -= 0.08
			_nudge()

func _nudge() -> void:
	if not is_instance_valid(slider) or not slider.editable:
		return
	var stp: float = slider.step if slider.step > 0.0 else (slider.max_value - slider.min_value) / 100.0
	slider.value = clampf(slider.value + dir * stp, slider.min_value, slider.max_value)
