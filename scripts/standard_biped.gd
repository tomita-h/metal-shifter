extends Node2D
## Standard biped with independently solved two-bone legs.
## Coordinates are Godot local units; ground is y=0.
@export var stride: float = 42.0
@export var step_height: float = 27.0
@export var cycles_per_second: float = 1.45
@export var thigh_length: float = 39.0
@export var shin_length: float = 43.0
@export var body_bob: float = 2.0

var phase: float = 0.0
var movement_blend: float = 0.0
var grounded_state: bool = true
var rear_foot := Vector2(-11.0, -4.0)
var front_foot := Vector2(11.0, -4.0)
var torso_texture: Texture2D

func _ready() -> void:
	var path := "res://assets/mech/modular/upper_body.png"
	if ResourceLoader.exists(path):
		torso_texture = load(path) as Texture2D
	queue_redraw()

var step_from := [Vector2.ZERO, Vector2.ZERO]
var step_to := [Vector2.ZERO, Vector2.ZERO]
var last_swing := -1
var was_grounded := false
const GROUND_Y := -4.0

func animate(delta: float, moving: bool, grounded: bool, speed_ratio: float) -> void:
	grounded_state = grounded
	var active := moving and grounded
	movement_blend = move_toward(movement_blend, 1.0 if active else 0.0, delta * 7.0)
	if not grounded:
		was_grounded = false
		last_swing = -1
		front_foot = front_foot.lerp(Vector2(22.0, -29.0), minf(delta * 8.0, 1.0))
		rear_foot = rear_foot.lerp(Vector2(-18.0, -29.0), minf(delta * 8.0, 1.0))
		queue_redraw()
		return
	if not was_grounded:
		front_foot = Vector2(11.0, GROUND_Y)
		rear_foot = Vector2(-11.0, GROUND_Y)
		phase = 0.0
		last_swing = -1
		was_grounded = true
	if active:
		var travel := 260.0 * clampf(speed_ratio, 0.0, 1.0) * delta
		front_foot.x -= travel
		rear_foot.x -= travel
		var cycle_rate := maxf(cycles_per_second, 260.0 * speed_ratio / maxf(stride * 4.0, 1.0))
		phase = fposmod(phase + delta * cycle_rate, 1.0)
		var swing_index := 0 if phase < 0.5 else 1
		var swing_t := fposmod(phase, 0.5) * 2.0
		if swing_index != last_swing:
			last_swing = swing_index
			step_from[swing_index] = front_foot if swing_index == 0 else rear_foot
			step_to[swing_index] = Vector2((11.0 if swing_index == 0 else -11.0) + stride, GROUND_Y)
		var smooth := swing_t * swing_t * (3.0 - 2.0 * swing_t)
		var foot: Vector2 = (step_from[swing_index] as Vector2).lerp(step_to[swing_index] as Vector2, smooth)
		foot.y = GROUND_Y - sin(swing_t * PI) * step_height
		if swing_index == 0:
			front_foot = foot
		else:
			rear_foot = foot
	else:
		last_swing = -1
		front_foot = front_foot.lerp(Vector2(11.0, GROUND_Y), minf(delta * 7.0, 1.0))
		rear_foot = rear_foot.lerp(Vector2(-11.0, GROUND_Y), minf(delta * 7.0, 1.0))
	queue_redraw()

func _solve_knee(hip: Vector2, ankle: Vector2, bend: float) -> Vector2:
	var diff := ankle - hip
	var d := clampf(diff.length(), absf(thigh_length - shin_length) + 0.01, thigh_length + shin_length - 0.01)
	var along := (thigh_length * thigh_length - shin_length * shin_length + d * d) / (2.0 * d)
	var perpendicular := sqrt(maxf(thigh_length * thigh_length - along * along, 0.0))
	var axis := diff.normalized() if diff.length() > 0.001 else Vector2.DOWN
	return hip + axis * along + Vector2(-axis.y, axis.x) * perpendicular * bend

func _draw_bone(a: Vector2, b: Vector2, width: float, color: Color) -> void:
	draw_line(a, b, Color("#25303d"), width + 6.0, true)
	draw_line(a, b, color, width, true)

func _draw_leg(hip: Vector2, ankle: Vector2, near: bool) -> void:
	var knee := _solve_knee(hip, ankle, -1.0)
	var armor := Color("#c5d1db") if near else Color("#697a90")
	var shin := Color("#d8e1e8") if near else Color("#8899ab")
	_draw_bone(hip, knee, 21.0, armor)
	_draw_bone(knee, ankle, 17.0, shin)
	draw_circle(hip, 12.0, Color("#394a5e"))
	draw_circle(knee, 10.0, Color("#356da8") if near else Color("#344b6c"))
	draw_circle(knee, 5.0, Color("#b2c9df"))
	# Foot stays horizontal while the ankle moves.
	var foot := PackedVector2Array([
		ankle + Vector2(-13, -2),
		ankle + Vector2(13, -2),
		ankle + Vector2(24, 6),
		ankle + Vector2(-17, 6)
	])
	draw_colored_polygon(foot, shin)
	draw_line(ankle + Vector2(-17, 7), ankle + Vector2(24, 7), Color("#25303d"), 3.0)

func _draw() -> void:
	var bob := absf(sin(phase)) * body_bob * movement_blend
	var rear_hip := Vector2(-12.0, -68.0 + bob)
	var front_hip := Vector2(11.0, -68.0 + bob)
	# Rear leg is drawn first, then torso, then near leg.
	_draw_leg(rear_hip, rear_foot, false)
	if torso_texture != null:
		# Source image uses a 420x415 reference canvas.
		# Keep only the upper-body mask; origin approximates original hip.
		draw_set_transform(Vector2(-210.0, -365.0) * 0.45 + Vector2(0, bob), 0.0, Vector2.ONE * 0.45)
		draw_texture(torso_texture, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO)
	else:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-29,-116+bob),Vector2(22,-125+bob),
			Vector2(34,-75+bob),Vector2(-28,-74+bob)
		]), Color("#c6d3df"))
		draw_rect(Rect2(Vector2(-8,-139+bob),Vector2(30,23)),Color("#d9e2e8"))
		draw_rect(Rect2(Vector2(10,-130+bob),Vector2(15,5)),Color("#3ce2f4"))
		draw_rect(Rect2(Vector2(-40,-141+bob),Vector2(35,22)),Color("#7e8fa5"))
		draw_rect(Rect2(Vector2(7,-103+bob),Vector2(73,13)),Color("#384858"))
	_draw_leg(front_hip, front_foot, true)
