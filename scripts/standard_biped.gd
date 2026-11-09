extends Node2D
## Standard two-legged rig. Independent hip/knee/ankle IK, planted stance and lifted swing.
## All values are in unscaled character-local pixels; floor is y=0.
@export var stride: float = 36.0
@export var step_height: float = 25.0
@export var stance_fraction: float = 0.64
@export var thigh_length: float = 42.0
@export var shin_length: float = 45.0
@export var body_bob: float = 2.0
@export var walk_speed: float = 260.0

const GROUND_Y := -5.0
const HIP_Y := -70.0
const LANES := [12.0, -12.0]
const OUTLINE := Color("#293340")
const WHITE := Color("#d8e1e9")
const GREY := Color("#788ba0")
const BLUE := Color("#356fae")

var torso_texture: Texture2D
var part_textures: Dictionary = {}
var feet: Array[Vector2] = [Vector2(12.0, GROUND_Y), Vector2(-12.0, GROUND_Y)]
var starts: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var targets: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var cycles: Array[float] = [0.0, 0.5]
var swinging: Array[bool] = [false, false]
var running := false
var was_grounded := false
var previous_facing := 1
var bob_phase := 0.0
var bob_amount := 0.0

func _ready() -> void:
	var path := "res://assets/mech/modular/upper_body.png"
	if ResourceLoader.exists(path):
		torso_texture = load(path) as Texture2D
	for part in ["front_thigh", "front_shin", "front_foot", "back_thigh", "back_shin", "back_foot"]:
		var path_part := "res://assets/mech/parts/%s.png" % part
		if ResourceLoader.exists(path_part):
			part_textures[part] = load(path_part) as Texture2D
	queue_redraw()

func _reset_feet() -> void:
	for i in range(2):
		feet[i] = Vector2(LANES[i], GROUND_Y)
		cycles[i] = 0.0 if i == 0 else 0.5
		swinging[i] = false

func animate(delta: float, moving: bool, grounded: bool, speed_ratio: float, facing: int = 1) -> void:
	if facing != previous_facing:
		_reset_feet()
		previous_facing = facing
	var speed := walk_speed * clampf(speed_ratio, 0.0, 1.0)
	var active := moving and grounded and speed > 8.0
	bob_amount = move_toward(bob_amount, 1.0 if active else 0.0, delta * 5.0)
	if not grounded:
		was_grounded = false
		running = false
		feet[0] = feet[0].lerp(Vector2(22.0, -28.0), minf(1.0, delta * 9.0))
		feet[1] = feet[1].lerp(Vector2(-18.0, -31.0), minf(1.0, delta * 9.0))
		queue_redraw()
		return
	if not was_grounded:
		_reset_feet()
		was_grounded = true
	if not active:
		running = false
		for i in range(2):
			feet[i] = feet[i].lerp(Vector2(LANES[i], GROUND_Y), minf(1.0, delta * 6.0))
		queue_redraw()
		return
	if not running:
		_reset_feet()
		running = true
	var travel := speed * delta
	# One complete gait travels approximately 2 * stride. The planted foot
	# compensates for player movement; the opposite foot swings forward.
	var advance := travel / maxf(2.0 * stride, 1.0)
	bob_phase = fposmod(bob_phase + advance, 1.0)
	for i in range(2):
		var old_cycle := cycles[i]
		var next_cycle := fposmod(old_cycle + advance, 1.0)
		var is_swing := next_cycle >= stance_fraction
		if not is_swing:
			# Ground contact: keep the foot at the same world X coordinate.
			feet[i].x -= travel
			feet[i].y = GROUND_Y
			swinging[i] = false
		else:
			if not swinging[i]:
				starts[i] = feet[i]
				targets[i] = Vector2(LANES[i] + stride, GROUND_Y)
				swinging[i] = true
			var t := clampf((next_cycle - stance_fraction) / (1.0 - stance_fraction), 0.0, 1.0)
			var eased := t * t * (3.0 - 2.0 * t)
			feet[i] = starts[i].lerp(targets[i], eased)
			feet[i].y = GROUND_Y - sin(PI * t) * step_height
		cycles[i] = next_cycle
	queue_redraw()

func _solve_knee(hip: Vector2, ankle: Vector2) -> Vector2:
	var delta := ankle - hip
	var distance := maxf(delta.length(), 0.01)
	var reachable := clampf(distance, absf(thigh_length - shin_length) + 0.01, thigh_length + shin_length - 0.01)
	var along := (thigh_length * thigh_length - shin_length * shin_length + reachable * reachable) / (2.0 * reachable)
	var side := sqrt(maxf(thigh_length * thigh_length - along * along, 0.0))
	var axis := delta / distance
	return hip + axis * along + Vector2(-axis.y, axis.x) * (-side)

func _armor_segment(a: Vector2, b: Vector2, width: float, base: Color, accent: Color) -> void:
	var axis := (b - a).normalized()
	var normal := Vector2(-axis.y, axis.x)
	var p := PackedVector2Array([
		a - axis * 4.0 + normal * width * 0.42,
		a - axis * 4.0 - normal * width * 0.42,
		b + axis * 4.0 - normal * width * 0.32,
		b + axis * 4.0 + normal * width * 0.32
	])
	draw_colored_polygon(p, OUTLINE)
	var inset := PackedVector2Array([
		a + axis * 2.0 + normal * width * 0.29,
		a + axis * 2.0 - normal * width * 0.29,
		b - axis * 2.0 - normal * width * 0.22,
		b - axis * 2.0 + normal * width * 0.22
	])
	draw_colored_polygon(inset, base)
	draw_line(a + normal * width * 0.19, b + normal * width * 0.12, accent, 3.0, true)
	draw_line(a - normal * width * 0.19, b - normal * width * 0.13, Color("#536577"), 2.0, true)

func _draw_part(name: String, start: Vector2, finish: Vector2) -> bool:
	if not part_textures.has(name):
		return false
	var texture: Texture2D = part_textures[name]
	var scale_factor: float = start.distance_to(finish) / float(texture.get_height())
	var angle: float = (finish - start).angle() - PI * 0.5
	draw_set_transform(start, angle, Vector2.ONE * scale_factor)
	draw_texture(texture, Vector2(-texture.get_width() * 0.5, 0.0))
	draw_set_transform(Vector2.ZERO)
	return true

func _draw_foot_part(name: String, ankle: Vector2) -> bool:
	if not part_textures.has(name):
		return false
	var texture: Texture2D = part_textures[name]
	draw_set_transform(ankle, 0.0, Vector2.ONE * 0.22)
	draw_texture(texture, Vector2(-texture.get_width() * 0.68, -texture.get_height() * 0.58))
	draw_set_transform(Vector2.ZERO)
	return true

func _draw_leg(hip: Vector2, ankle: Vector2, near: bool) -> void:
	var knee := _solve_knee(hip, ankle)
	var armor := WHITE if near else GREY
	var accent := Color("#ffffff") if near else Color("#a6b5c6")
	var prefix := "front" if near else "back"
	if not _draw_part(prefix + "_thigh", hip, knee):
		_armor_segment(hip, knee, 25.0, armor, accent)
	if not _draw_part(prefix + "_shin", knee, ankle):
		_armor_segment(knee, ankle, 21.0, armor, accent)
	draw_circle(hip, 12.0, OUTLINE)
	draw_circle(hip, 7.0, Color("#677d93"))
	draw_circle(knee, 12.0, OUTLINE)
	draw_circle(knee, 8.0, BLUE if near else Color("#304e78"))
	draw_circle(knee, 4.0, Color("#a9d3e7"))
	draw_circle(ankle, 8.0, OUTLINE)
	draw_circle(ankle, 5.0, armor)
	if _draw_foot_part(prefix + "_foot", ankle):
		return
	var sole := PackedVector2Array([
		ankle + Vector2(-16,-4), ankle + Vector2(10,-5),
		ankle + Vector2(25,4), ankle + Vector2(22,9),
		ankle + Vector2(-19,9)
	])
	draw_colored_polygon(sole, OUTLINE)
	var boot := PackedVector2Array([
		ankle + Vector2(-12,-2), ankle + Vector2(8,-3),
		ankle + Vector2(19,3), ankle + Vector2(17,5),
		ankle + Vector2(-14,5)
	])
	draw_colored_polygon(boot, armor)
	draw_line(ankle + Vector2(2,0), ankle + Vector2(15,2), BLUE, 2.0)

func _draw() -> void:
	var bob := absf(sin(bob_phase * TAU)) * body_bob * bob_amount
	var back_hip := Vector2(-12.0, HIP_Y + bob)
	var front_hip := Vector2(12.0, HIP_Y + bob)
	_draw_leg(back_hip, feet[1], false)
	if torso_texture != null:
		draw_set_transform(Vector2(-210.0,-365.0) * 0.45 + Vector2(0,bob), 0.0, Vector2.ONE * 0.45)
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
	_draw_leg(front_hip, feet[0], true)
