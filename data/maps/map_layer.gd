extends Node2D
## 地圖的一層畫布：painter.call(self) 畫內容（陸地這種不常變的層，只在需要時重畫）
##   batched = true：painter 拿到的是 CanvasBatch，沒有貼圖的多邊形和線條會收成網格一次畫出去
##   cache = true（預設）：網格算一次就記著；之後重畫只是重播（invalidate() 才重算）
##     prebuild() 可以先算好（還沒出現在畫面上的時候），第一次出現就不會卡
##   cache = false：每幀都重算（會動的那層）；lines_native：細線直接交給畫布
const CanvasBatch := preload("res://data/maps/canvas_batch.gd")
var painter: Callable
var batched := false
var cache := true
var lines_native := false
var _keep: Array = []
var _ops: Array = []
var built := false


func prebuild() -> void:
	if built or not batched:
		return
	var b := CanvasBatch.new(self)
	b.record = true
	b.lines_native = lines_native
	painter.call(b)
	b.flush()
	_ops = b.ops
	_keep = b.keep
	built = true


func invalidate() -> void:
	built = false
	_ops = []
	queue_redraw()


func _draw() -> void:
	if not batched:
		painter.call(self)
		return
	if not cache:
		var b := CanvasBatch.new(self)
		b.lines_native = lines_native
		painter.call(b)
		b.flush()
		_keep = b.keep
		return
	prebuild()
	var tex := CanvasBatch.atlas()
	for op in _ops:
		if op is Mesh:
			draw_mesh(op, tex)
		else:
			(op as Callable).call()
