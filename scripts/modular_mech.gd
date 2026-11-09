extends Node2D
## Part images use the same 420x415 reference canvas.
## Each leg is animated independently, with PI radians phase offset.
const PART_DIR := "res://assets/mech/modular/"
const CANVAS_SCALE := 0.45
@export var stride_pixels: float = 42.0
@export var lift_pixels: float = 22.0
@export var step_frequency: float = 1.75

var rear_pivot: Node2D
var front_pivot: Node2D
var torso_pivot: Node2D
var phase := 0.0

func _ready() -> void:
	scale = Vector2.ONE * CANVAS_SCALE
	position = Vector2(-210.0, -365.0) * CANVAS_SCALE
	rear_pivot = _create_part("rear_leg", Vector2(245, 244), 0)
	torso_pivot = _create_part("upper_body", Vector2(210, 239), 1)
	front_pivot = _create_part("front_leg", Vector2(165, 244), 2)

func _create_part(part_name: String, pivot: Vector2, depth: int) -> Node2D:
	var node := Node2D.new()
	node.name = part_name
	node.position = pivot
	node.z_index = depth
	add_child(node)
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.position = -pivot
	sprite.texture = load(PART_DIR + part_name + ".png") as Texture2D
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	node.add_child(sprite)
	return node

func animate(delta: float, moving: bool, grounded: bool, speed_ratio: float) -> void:
	if moving and grounded:
		phase = fposmod(phase + delta * TAU * step_frequency * maxf(speed_ratio, 0.3), TAU)
	var intensity := 1.0 if moving and grounded else 0.0
	var front_cycle := sin(phase)
	var rear_cycle := sin(phase + PI)
	_apply_leg(front_pivot, Vector2(165,244), front_cycle, intensity)
	_apply_leg(rear_pivot, Vector2(245,244), rear_cycle, intensity)
	# When the rear leg is swung forward, render it above the front leg.
	rear_pivot.z_index = 3 if rear_cycle > 0.2 else 0
	front_pivot.z_index = 3 if front_cycle > 0.2 else 2
	torso_pivot.position = Vector2(210, 239 - absf(sin(phase)) * 3.0 * intensity)
	if not grounded:
		# Legs tucked slightly during jump, without running cycle.
		front_pivot.position = Vector2(165 + 8, 244 - 13)
		rear_pivot.position = Vector2(245 - 8, 244 - 13)
		front_pivot.rotation = -0.12
		rear_pivot.rotation = 0.12

func _apply_leg(node: Node2D, origin: Vector2, cycle: float, intensity: float) -> void:
	node.position = origin + Vector2(stride_pixels * cycle * intensity, -lift_pixels * maxf(cycle, 0.0) * intensity)
	node.rotation = 0.10 * cycle * intensity
