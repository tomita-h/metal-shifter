extends Node2D
## Self-contained starter level. All visuals are temporary vector art.
const PlayerScript = preload("res://scripts/player.gd")
var player: CharacterBody2D
var camera: Camera2D

func _ready() -> void:
	_build_level()
	player = PlayerScript.new()
	player.name = "Player"
	player.position = Vector2(180, 510)
	add_child(player)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_right = 2800
	camera.limit_top = 0
	camera.limit_bottom = 720
	player.add_child(camera)
	camera.make_current()
	_make_label()

func _build_level() -> void:
	var sky := Polygon2D.new()
	sky.polygon = PackedVector2Array([Vector2(0,0),Vector2(2800,0),Vector2(2800,720),Vector2(0,720)])
	sky.color = Color("#152238")
	add_child(sky)
	for i in range(18):
		var building := Polygon2D.new()
		var x := float(i * 170)
		var h := float(140 + (i * 97) % 230)
		building.polygon = PackedVector2Array([Vector2(x,620),Vector2(x,620-h),Vector2(x+115,620-h),Vector2(x+115,620)])
		building.color = Color("#23354b") if i % 2 == 0 else Color("#1d2d42")
		add_child(building)
	var floor_body := StaticBody2D.new()
	floor_body.name = "Ground"
	add_child(floor_body)
	var floor_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2800,100)
	floor_shape.shape = rect
	floor_shape.position = Vector2(1400,670)
	floor_body.add_child(floor_shape)
	var floor_visual := Polygon2D.new()
	floor_visual.polygon = PackedVector2Array([Vector2(0,620),Vector2(2800,620),Vector2(2800,720),Vector2(0,720)])
	floor_visual.color = Color("#344556")
	add_child(floor_visual)
	for i in range(70):
		var mark := Line2D.new()
		mark.points = PackedVector2Array([Vector2(i*40,623),Vector2(i*40+19,623)])
		mark.width = 3.0
		mark.default_color = Color("#7b9bad")
		add_child(mark)

func _make_label() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.text = "METAL SHIFTER   |   A / D または ← / → : 移動    |    SPACE : ジャンプ"
	label.position = Vector2(20,18)
	label.add_theme_font_size_override("font_size",20)
	layer.add_child(label)
