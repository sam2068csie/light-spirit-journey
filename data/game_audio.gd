extends "game_state.gd"
## 遊戲管家（第 2 層）：音量、音效（程式合成的水晶音色）、背景音樂、按鈕音效、省電（閒置降幀）

func set_volume(kind: String, v: float) -> void:
	match kind:
		"master":
			master_vol = v
		"music":
			music_vol = v
		"sfx":
			sfx_vol = v
	_apply_audio()


func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus_name)
			AudioServer.set_bus_send(i, "Master")
			# 一點殘響讓水晶音色更有空間感（手機上音效不加殘響，省一點運算）
			if bus_name == "SFX" and OS.has_feature("mobile"):
				continue
			var rv := AudioEffectReverb.new()
			rv.room_size = 0.8 if bus_name == "Music" else 0.55
			rv.damping = 0.35
			rv.spread = 1.0
			rv.wet = 0.3 if bus_name == "Music" else 0.16
			rv.dry = 0.9
			AudioServer.add_bus_effect(i, rv)


func _apply_audio() -> void:
	for pair in [["Master", master_vol], ["Music", music_vol], ["SFX", sfx_vol]]:
		var i := AudioServer.get_bus_index(pair[0])
		if i == -1:
			continue
		var v: float = pair[1]
		AudioServer.set_bus_mute(i, v <= 0.001)
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))


# ================= 音效 =================

static func semi(s: float) -> float:
	return pow(2.0, s / 12.0)


## 五聲音階第 i 個音（相對 D5 的半音數）
static func scale_semi(i: int) -> int:
	return 12 * int(floor(i / 5.0)) + PENTA[posmod(i, 5)]


func play(snd: String, pitch: float = 1.0, db: float = 0.0, delay: float = 0.0) -> void:
	if not is_inside_tree() or not _snd.has(snd):
		return
	if delay > 0.0:
		get_tree().create_timer(delay, true).timeout.connect(play.bind(snd, pitch, db, 0.0))
		return
	var p: AudioStreamPlayer = _pool[_pool_i]
	_pool_i = (_pool_i + 1) % _pool.size()
	p.stream = _snd[snd]
	p.pitch_scale = pitch
	p.volume_db = db
	p.play()


## 常用音效。i 為額外參數（例如第幾顆寶石，音會越來越高）
## 有操作或動畫：保持 60 幀一段時間（ms 毫秒）
func wake(ms: int = IDLE_AFTER_MS) -> void:
	_active_until = maxi(_active_until, Time.get_ticks_msec() + ms)
	if Engine.max_fps != FPS_ACTIVE:
		Engine.max_fps = FPS_ACTIVE


func set_power_save(on: bool) -> void:
	power_save = on
	wake()
	save_settings()


## 碰螢幕、滑鼠、鍵盤：回到 60 幀
func _input(e: InputEvent) -> void:
	if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
		_last_press = e.position
	if e is InputEventScreenTouch or e is InputEventScreenDrag or e is InputEventMouseButton or e is InputEventKey \
			or (e is InputEventMouseMotion and e.button_mask != 0):
		wake()


func sfx(kind: String, i: int = 0) -> void:
	# 有音效通常也有動畫（答對、過關、開寶箱…）：動畫播完之前維持 60 幀
	wake(2200)
	match kind:
		"click":
			play("blip", 1.0, -9.0)
		"tick":
			var now := Time.get_ticks_msec()
			if now - _last_tick < 45:
				return
			_last_tick = now
			play("blip", 1.5 + 0.08 * i, -17.0)
		"open":
			play("bell", semi(-5), -15.0)
			play("bell", semi(2), -17.0, 0.05)
		"correct":
			_fx_good()
			play("bell", semi(7), -5.0)
			play("bell", semi(12), -3.0, 0.08)
		"wrong":
			if fx:
				fx.bad()
			play("bonk", 1.0, -4.0)
		"gem":
			play("bell", semi(scale_semi(5 + i)), -4.0)
		"fall":
			play("fall", 1.0, -7.0)
		"hole":
			play("fall", 0.75, -6.0)
		"ping":
			play("bell", semi(12), -3.0)
			play("bell", semi(0), -9.0)
		"lamp":
			play("bell", semi(scale_semi(4 + i)), -6.0)
		"count":
			play("bell", semi(scale_semi(2 + 2 * i)), -12.0)
		"success":
			_fx_good()
			for k in 5:
				play("bell", semi(scale_semi(k + 3)), -6.0 + k, 0.065 * k)
		"fanfare":
			if fx:
				fx.big(fx.size / 2.0)
			var seq := [0, 2, 4, 5, 7, 10]
			for k in seq.size():
				play("bell", semi(scale_semi(seq[k])), -5.0, 0.11 * k)
			play("bell", semi(-12), -8.0, 0.66)
			play("bell", semi(scale_semi(10)), -2.0, 0.66)


func _fx_good() -> void:
	if fx == null:
		return
	var p := _last_press
	if p.x < 0.0 or not fx.get_rect().has_point(p):
		p = fx.size / 2.0
	fx.good(p)


## 按鈕按下去縮一下、放開彈回來（全遊戲的 Button 自動套用）
func _on_node_added(n: Node) -> void:
	if n is BaseButton and not n.has_meta("no_bounce"):
		n.button_down.connect(_btn_bounce.bind(n, true))
		n.button_up.connect(_btn_bounce.bind(n, false))


func _btn_bounce(b: BaseButton, down: bool) -> void:
	if not is_instance_valid(b) or b.disabled or b.size.x > 700.0:
		return
	b.pivot_offset = b.size / 2.0
	if b.has_meta("_bt"):
		var old: Tween = b.get_meta("_bt")
		if old and old.is_valid():
			old.kill()
	var tw := b.create_tween()
	if down:
		tw.tween_property(b, "scale", Vector2(0.94, 0.94), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_property(b, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	b.set_meta("_bt", tw)


## 光靈奔跑時的音：t 為 0（畫面底部）～1（畫面頂端），對應五聲音階
func note(t: float, db: float = -14.0) -> void:
	var idx := clampi(roundi(clampf(t, 0.0, 1.0) * 14.0), 0, 14)
	play("bell", semi(scale_semi(idx) - 12), db)


# ================= 背景音樂 =================

## 暫停時把音樂壓小
func duck(on: bool) -> void:
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(_bgm, "volume_db", -9.0 if on else 0.0, 0.35)


func _start_bgm() -> void:
	var stream: AudioStreamWAV = null
	# 預先生成好的音樂（res://audio/crystal_bgm.res，用 generate_bgm() 產生）。
	# 手機上即時合成要好幾秒、還會讓畫面卡住，所以直接打包進遊戲。
	if ResourceLoader.exists(BGM_BAKED):
		stream = load(BGM_BAKED) as AudioStreamWAV
	if stream == null and ResourceLoader.exists(BGM_CACHE):
		stream = load(BGM_CACHE) as AudioStreamWAV
	if stream == null:
		stream = await generate_bgm()
		ResourceSaver.save(stream, BGM_CACHE)
	_bgm.stream = stream
	_bgm.volume_db = -40.0
	_bgm.play()
	var tw := create_tween()
	tw.tween_property(_bgm, "volume_db", 0.0, 3.0).set_trans(Tween.TRANS_SINE)


## 水晶音樂：D 大調，72 BPM，四個和弦各兩小節，約 27 秒無縫循環
func generate_bgm() -> AudioStreamWAV:
	var beat := 60.0 / 72.0
	var chord_len := beat * 8.0
	var n := int(chord_len * 4.0 * SR)
	var mix := PackedFloat32Array()
	mix.resize(n)

	# 和弦：arp = 琶音用的五個音、pad = 墊底的三個音（皆為相對 D5 的半音數）
	var chords := [
		{"arp": [0, 4, 7, 11, 14], "pad": [-24, -17, -8]},     # Dmaj9
		{"arp": [-3, 0, 4, 7, 14], "pad": [-27, -20, -12]},    # Bm7(11)
		{"arp": [0, 4, 5, 7, 9], "pad": [-31, -24, -15]},      # Gmaj9
		{"arp": [-5, -1, 2, 7, 9], "pad": [-29, -22, -13]},    # A(add9)
	]
	var patterns := [[0, 2, 1, 3, 2, 4, 3, 1], [4, 3, 1, 2, 0, 2, 3, 1]]
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026

	# 1) 琶音：先把會用到的音高各算一次波形，再疊進音軌
	var ref := _bell_wave(D5, 2.2, 1.0)
	var cache := {}
	var work := 0
	for c in 4:
		var ch: Dictionary = chords[c]
		for b in 2:
			var pat: Array = patterns[b]
			for e in 8:
				var s: int = ch.arp[pat[e]]
				if not cache.has(s):
					cache[s] = _resample(ref, semi(s))
				var t := (c * 8 + b * 4) * beat + e * beat / 2.0 + rng.randf_range(-0.006, 0.006)
				var vel := 0.34 if e == 0 else (0.24 if e % 2 == 0 else 0.18)
				vel *= rng.randf_range(0.85, 1.0)
				_add(mix, cache[s], int(t * SR), vel)
				work += cache[s].size()
				if work > 200000:
					work = 0
					await get_tree().process_frame
			# 每兩小節在反拍加一顆高八度的「閃光」
			if b == 1:
				var top: int = ch.arp[4] + 12
				if not cache.has(top):
					cache[top] = _resample(ref, semi(top))
				_add(mix, cache[top], int(((c * 8 + 6) * beat + beat / 2.0) * SR), 0.1)

	# 2) 和弦墊：柔和的正弦，慢慢淡入淡出，接到下一個和弦
	for c in 4:
		for s in chords[c].pad:
			var f := D5 * semi(s)
			var start := int(c * chord_len * SR)
			var length := int((chord_len + 2.2) * SR)
			var att := 1.8 * SR
			var rel := 2.2 * SR
			var w := TAU * f / SR
			for j in length:
				var env := minf(j / att, 1.0) * minf((length - j) / rel, 1.0)
				var ph := w * j
				var v := (sin(ph) + 0.18 * sin(2.0 * ph) + 0.05 * sin(3.0 * ph)) * env * 0.075
				mix[(start + j) % n] += v * (1.0 + 0.15 * sin(TAU * 0.21 * j / SR))
			await get_tree().process_frame

	# 3) 正規化並轉成 16 位元
	var peak := 0.001
	for i in n:
		peak = maxf(peak, absf(mix[i]))
	var g := 0.8 / peak
	for i in n:
		mix[i] *= g
	return to_wav(mix, n)


# ================= 合成工具 =================

static func to_wav(buf: PackedFloat32Array, loop_end: int = 0) -> AudioStreamWAV:
	# 循環音樂：在結尾後面多接一小段開頭的波形（循環點不變）。
	# Godot 播到循環點時會為了內插往後多讀幾個取樣；如果循環點剛好是資料最後一格，
	# 就會讀到緩衝區外面 → Android 上音訊執行緒直接崩潰（約開啟 30 秒時閃退）。
	const LOOP_PAD := 512
	var n := buf.size()
	var total := n + (mini(LOOP_PAD, n) if loop_end > 0 else 0)
	var bytes := PackedByteArray()
	bytes.resize(total * 2)
	for i in total:
		var v: float = buf[i] if i < n else buf[i - n]
		bytes.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = false
	w.data = bytes
	if loop_end > 0:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = loop_end
	return w


## 水晶鐘音色：幾個泛音各自指數衰減
static func _bell_wave(freq: float, dur: float, amp: float) -> PackedFloat32Array:
	var n := int(dur * SR)
	var out := PackedFloat32Array()
	out.resize(n)
	var parts := [[1.0, 1.0, 1.1], [2.0, 0.42, 0.5], [3.0, 0.15, 0.28], [4.16, 0.08, 0.16], [5.43, 0.035, 0.09]]
	for p in parts:
		var w: float = TAU * freq * p[0] / SR
		var k := exp(-1.0 / (float(p[2]) * SR))
		var e: float = p[1] * amp
		for i in n:
			out[i] += e * sin(w * i)
			e *= k
	var att := int(0.004 * SR)
	for i in att:
		out[i] *= float(i) / att
	return out


## 用線性內插把波形升降調
static func _resample(src: PackedFloat32Array, ratio: float) -> PackedFloat32Array:
	var n := int((src.size() - 1) / ratio)
	var out := PackedFloat32Array()
	out.resize(n)
	for j in n:
		var x := j * ratio
		var i0 := int(x)
		var fr := x - i0
		out[j] = src[i0] * (1.0 - fr) + src[i0 + 1] * fr
	return out


## 把 src 疊加到 mix 的 start 位置（超過結尾就繞回開頭，確保無縫循環）
static func _add(mix: PackedFloat32Array, src: PackedFloat32Array, start: int, vel: float) -> void:
	var n := mix.size()
	for j in src.size():
		mix[(start + j) % n] += vel * src[j]


func _build_sounds() -> void:
	_snd["bell"] = to_wav(_bell_wave(D5, 1.8, 0.85))

	# 按鈕：短促柔和的「嘀」
	var n := int(0.07 * SR)
	var blip := PackedFloat32Array()
	blip.resize(n)
	for i in n:
		var e := exp(-i / (0.014 * SR))
		blip[i] = (sin(TAU * 1500.0 * i / SR) + 0.3 * sin(TAU * 3000.0 * i / SR)) * e * 0.55
	_snd["blip"] = to_wav(blip)

	# 答錯：往下滑的圓潤低音
	n = int(0.34 * SR)
	var bonk := PackedFloat32Array()
	bonk.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / SR
		var f := 320.0 * pow(190.0 / 320.0, minf(t / 0.2, 1.0))
		ph += TAU * f / SR
		var e := minf(t / 0.006, 1.0) * exp(-t / 0.11)
		bonk[i] = (sin(ph) + 0.22 * sin(3.0 * ph)) * e * 0.6
	_snd["bonk"] = to_wav(bonk)

	# 掉落：長長的下滑音
	n = int(0.8 * SR)
	var fall := PackedFloat32Array()
	fall.resize(n)
	ph = 0.0
	for i in n:
		var t := float(i) / SR
		var f := 900.0 * pow(120.0 / 900.0, t / 0.8) * (1.0 + 0.02 * sin(TAU * 9.0 * t))
		ph += TAU * f / SR
		var e := minf(t / 0.01, 1.0) * exp(-t / 0.32)
		fall[i] = (sin(ph) + 0.25 * sin(2.0 * ph)) * e * 0.5
	_snd["fall"] = to_wav(fall)


# ================= 自動幫按鈕、滑桿加上音效 =================

func _hook_tree(node: Node) -> void:
	_hook(node)
	for c in node.get_children():
		_hook_tree(c)


## 按鈕自動加上「嘀」聲、滑桿加上「滴答」聲；不想要的加 meta "silent"
func _hook(node: Node) -> void:
	if node.has_meta("_snd_hooked") or node.has_meta("silent"):
		return
	if node is BaseButton:
		node.set_meta("_snd_hooked", true)
		node.pressed.connect(_on_btn.bind(node))
	elif node is HSlider:
		node.set_meta("_snd_hooked", true)
		node.value_changed.connect(_on_slider.bind(node))


## 手機的返回鍵：轉成和 Esc 一樣的「ui_cancel」；離開遊戲時重排提醒通知
func _notification(what: int) -> void:
	# 離開遊戲（切到背景、關掉）：重新排好提醒通知
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if notifier != null:
			notifier.reschedule()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_inside_tree():
		var ev := InputEventAction.new()
		ev.action = "ui_cancel"
		ev.pressed = true
		get_viewport().push_input(ev)


func _on_btn(b: BaseButton) -> void:
	if not b.has_meta("silent"):
		sfx("click")


func _on_slider(_v: float, s: HSlider) -> void:
	if s.max_value > s.min_value:
		sfx("tick", int(10.0 * (s.value - s.min_value) / (s.max_value - s.min_value)))
