extends RigidBody2D

var target_position: Vector2
var target_rotation: float

func _ready():
	await get_tree().process_frame
	_setup_mode()

func _setup_mode():
	if multiplayer.multiplayer_peer == null:
		await get_tree().process_frame

	if multiplayer.is_server():
		freeze = false
		sleeping = false
		collision_layer = 1
		collision_mask = 1
		print("[RigidBody:", name, "] SERVER physics active")
	else:
		freeze = true
		sleeping = true
		collision_layer = 0
		collision_mask = 0
		print("[RigidBody:", name, "] CLIENT proxy mode")

func _physics_process(delta):
	if multiplayer.is_server():
		sync_state.rpc(global_position, rotation)

@rpc("any_peer", "call_remote", "reliable")
func request_impulse(force: Vector2, position: Vector2):
	if not multiplayer.is_server():
		return

	apply_impulse(force, position)

@rpc("authority", "call_remote", "unreliable")
func sync_state(pos: Vector2, rot: float):
	if multiplayer.is_server():
		return

	target_position = pos
	target_rotation = rot

func _process(delta):
	if multiplayer.is_server():
		return

	global_position = global_position.lerp(target_position, 0.35)
	rotation = lerp_angle(rotation, target_rotation, 0.35)
