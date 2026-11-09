extends CharacterBody2D
## Modular placeholder mech. Replace each Polygon2D with part sprites later.
const SPEED := 260.0
const ACCEL := 1350.0
const FRICTION := 1600.0
const JUMP_VELOCITY := -430.0
const GRAVITY := 1100.0

var facing := 1
var walk_time := 0.0
var idle_time := 0.0
var visual: Node2D
var body_pivot: Node2D
var left_leg: Node2D
var right_leg: Node2D
var modular_mech: Node2D
var sprite: Sprite2D
var frame_time := 0.0
const IDLE_SHEET := "res://assets/mech/idle.png"

func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(62,120)
	collision.shape = shape
	collision.position = Vector2(0,-62)
	add_child(collision)
	visual = Node2D.new()
	visual.name = "MechVisual"
	add_child(visual)
	_make_mech()
	_setup_sprite()
	_setup_modular()

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("ui_left","ui_right")
	if Input.is_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction += 1.0
	direction = clampf(direction,-1.0,1.0)
	if direction != 0:
		facing = 1 if direction > 0 else -1
		velocity.x = move_toward(velocity.x,direction*SPEED,ACCEL*delta)
	else:
		velocity.x = move_toward(velocity.x,0.0,FRICTION*delta)
	if not is_on_floor():
		velocity.y += GRAVITY*delta
	elif Input.is_key_pressed(KEY_SPACE):
		velocity.y = JUMP_VELOCITY
	move_and_slide()
	visual.scale.x = facing
	_update_sprite(delta)
	if modular_mech != null:
		modular_mech.animate(delta, absf(velocity.x) > 8.0, is_on_floor(), absf(velocity.x) / SPEED)
	idle_time += delta
	if absf(velocity.x) > 8.0 and is_on_floor():
		walk_time += delta * 10.0
		left_leg.rotation = sin(walk_time)*0.32
		right_leg.rotation = -sin(walk_time)*0.32
		body_pivot.position.y = -sin(walk_time*2.0)*2.5
	else:
		left_leg.rotation = move_toward(left_leg.rotation,0.0,delta*3.0)
		right_leg.rotation = move_toward(right_leg.rotation,0.0,delta*3.0)
		body_pivot.position.y = sin(idle_time*2.6)*2.0

func _part(parent: Node, name: String, points: PackedVector2Array, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = name
	poly.polygon = points
	poly.color = color
	parent.add_child(poly)
	return poly

func _make_mech() -> void:
	# Pivot positions are the contract for future replaceable parts.
	left_leg = Node2D.new()
	left_leg.name = "LegRear"
	left_leg.position = Vector2(-13,-58)
	visual.add_child(left_leg)
	_part(left_leg,"Armor",PackedVector2Array([Vector2(-15,0),Vector2(7,0),Vector2(13,35),Vector2(9,52),Vector2(-20,52),Vector2(-24,42)]),Color("#73869b"))
	_part(left_leg,"Foot",PackedVector2Array([Vector2(-22,46),Vector2(10,46),Vector2(20,58),Vector2(-27,58)]),Color("#c7d2db"))
	right_leg = Node2D.new()
	right_leg.name = "LegFront"
	right_leg.position = Vector2(18,-58)
	visual.add_child(right_leg)
	_part(right_leg,"Armor",PackedVector2Array([Vector2(-11,0),Vector2(15,2),Vector2(19,35),Vector2(12,52),Vector2(-16,52),Vector2(-20,37)]),Color("#b7c3cf"))
	_part(right_leg,"Knee",PackedVector2Array([Vector2(-12,18),Vector2(16,18),Vector2(12,32),Vector2(-14,30)]),Color("#3f6fa7"))
	_part(right_leg,"Foot",PackedVector2Array([Vector2(-17,46),Vector2(15,46),Vector2(27,58),Vector2(-20,58)]),Color("#e0e5e8"))
	body_pivot = Node2D.new()
	body_pivot.name = "UpperBody"
	visual.add_child(body_pivot)
	var shoulder := Node2D.new()
	shoulder.name = "ShoulderWeaponMount"
	shoulder.position = Vector2(-24,-120)
	body_pivot.add_child(shoulder)
	_part(shoulder,"MissilePod",PackedVector2Array([Vector2(-27,-25),Vector2(22,-25),Vector2(27,2),Vector2(-27,8)]),Color("#9eacb8"))
	for x in [-15,0,15]:
		_part(shoulder,"Missile"+str(x),PackedVector2Array([Vector2(x-5,-18),Vector2(x+4,-18),Vector2(x+4,-9),Vector2(x-5,-9)]),Color("#d05c57"))
	var torso := Node2D.new()
	torso.name = "TorsoMount"
	torso.position = Vector2(0,-100)
	body_pivot.add_child(torso)
	_part(torso,"Body",PackedVector2Array([Vector2(-33,-27),Vector2(12,-38),Vector2(39,-12),Vector2(30,34),Vector2(-24,34),Vector2(-39,5)]),Color("#cbd4dc"))
	_part(torso,"Chest",PackedVector2Array([Vector2(-5,-21),Vector2(31,-11),Vector2(22,16),Vector2(-7,13)]),Color("#758ba5"))
	var head := Node2D.new()
	head.name = "HeadMount"
	head.position = Vector2(11,-145)
	body_pivot.add_child(head)
	_part(head,"Helmet",PackedVector2Array([Vector2(-22,-17),Vector2(8,-26),Vector2(27,-12),Vector2(22,9),Vector2(-19,11)]),Color("#d9e0e6"))
	_part(head,"Visor",PackedVector2Array([Vector2(1,-10),Vector2(26,-11),Vector2(19,0),Vector2(2,1)]),Color("#3de1ee"))
	var weapon := Node2D.new()
	weapon.name = "RightWeaponMount"
	weapon.position = Vector2(18,-103)
	body_pivot.add_child(weapon)
	_part(weapon,"Arm",PackedVector2Array([Vector2(-8,-13),Vector2(15,-11),Vector2(24,13),Vector2(5,21),Vector2(-16,8)]),Color("#e2e7eb"))
	_part(weapon,"Rifle",PackedVector2Array([Vector2(-8,6),Vector2(49,3),Vector2(62,10),Vector2(49,17),Vector2(-8,17)]),Color("#364456"))
	_part(weapon,"Barrel",PackedVector2Array([Vector2(54,8),Vector2(82,8),Vector2(82,13),Vector2(54,13)]),Color("#94a6b7"))

const ANIMATIONS := {
	"idle": {"path": "res://assets/mech/idle.png", "frames": 9, "fps": 7.0},
	"walk": {"path": "res://assets/mech/walk.png", "frames": 8, "fps": 11.0},
	"jump": {"path": "res://assets/mech/jump.png", "frames": 8, "fps": 9.0}
}
var animation_textures: Dictionary = {}
var animation_name := ""
var animation_elapsed := 0.0

func _setup_sprite() -> void:
	for name in ANIMATIONS:
		var path: String = ANIMATIONS[name]["path"]
		if ResourceLoader.exists(path):
			var texture := load(path) as Texture2D
			if texture != null:
				animation_textures[name] = texture
	if animation_textures.is_empty():
		push_warning("No mech sprites found. Extract motion asset ZIP into assets/mech.")
		return
	sprite = Sprite2D.new()
	sprite.name = "MechSprite"
	sprite.scale = Vector2(0.45, 0.45)
	sprite.position = Vector2(-8, -94)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visual.add_child(sprite)
	for child in visual.get_children():
		if child != sprite and child is CanvasItem:
			child.visible = false
	_play_animation("idle")

func _play_animation(name: String) -> void:
	if sprite == null:
		return
	if not animation_textures.has(name):
		name = "idle"
	if not animation_textures.has(name):
		return
	if animation_name == name:
		return
	animation_name = name
	animation_elapsed = 0.0
	sprite.texture = animation_textures[name]
	sprite.hframes = int(ANIMATIONS[name]["frames"])
	sprite.vframes = 1
	sprite.frame = 0

func _update_sprite(delta: float) -> void:
	if sprite == null:
		return
	var next_anim := "idle"
	if not is_on_floor():
		next_anim = "jump"
	elif absf(velocity.x) > 8.0:
		next_anim = "walk"
	_play_animation(next_anim)
	animation_elapsed += delta
	var fps: float = ANIMATIONS[animation_name]["fps"]
	var count: int = ANIMATIONS[animation_name]["frames"]
	if animation_name == "jump":
		# Hold the airborne pose until landing; reset on the next jump.
		sprite.frame = mini(int(animation_elapsed * fps), count - 1)
	else:
		sprite.frame = int(animation_elapsed * fps) % count
	sprite.position.y = -94.0

func _setup_modular() -> void:
	var path := "res://assets/mech/modular/"
	var required := ["upper_body.png", "front_leg.png", "rear_leg.png"]
	for filename in required:
		if not ResourceLoader.exists(path + filename):
			push_warning("Modular part missing: " + filename + ". Using existing sprite animation.")
			return
	modular_mech = preload("res://scripts/modular_mech.gd").new()
	modular_mech.name = "ModularMech"
	visual.add_child(modular_mech)
	if sprite != null:
		sprite.visible = false
	for child in visual.get_children():
		if child != modular_mech and child is CanvasItem:
			child.visible = false
