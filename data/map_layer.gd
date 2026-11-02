extends Node2D
## 地圖的一層畫布：painter.call(self) 畫內容（陸地這種不常變的層，只在需要時重畫）
var painter: Callable

func _draw() -> void:
	painter.call(self)
