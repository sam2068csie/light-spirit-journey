extends Node2D
## 地圖的一層畫布：painter.call(self) 畫內容（陸地這種不常變的層，只在需要時重畫）
##   batched = true：painter 拿到的是 CanvasBatch，沒有貼圖的多邊形和線條會收成網格一次畫出去
const CanvasBatch := preload("res://data/maps/canvas_batch.gd")
var painter: Callable
var batched := false
var _keep: Array = []

func _draw() -> void:
	if not batched:
		painter.call(self)
		return
	var b := CanvasBatch.new(self)
	painter.call(b)
	b.flush()
	_keep = b.keep
