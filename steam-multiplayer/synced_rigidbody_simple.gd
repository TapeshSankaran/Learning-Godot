extends RigidBody2D

var target_position: Vector2
var target_rotation: float

func _ready():
	await get_tree().process_frame
	_setup_mode()

func _setup_mode():
	if multiplayer.multiplayer_peer == null:
		return

	if is_multiplayer_authority():
		freeze = false
		sleeping = false
		print("[RigidBody:", name, "] Authority mode - physics active")
	else:
		freeze = true
		sleeping = true

		collision_layer = 0
		collision_mask = 0

		print("[RigidBody:", name, "] Proxy mode - physics disabled")


func _physics_process(delta):
	if is_multiplayer_authority():
		sync_state.rpc(global_position, rotation)


@rpc("authority", "call_remote", "unreliable")
func sync_state(pos: Vector2, rot: float):
	if not is_multiplayer_authority():
		target_position = pos
		target_rotation = rot


func _process(delta):
	if not is_multiplayer_authority():
		global_position = global_position.lerp(target_position, 0.35)
		rotation = lerp_angle(rotation, target_rotation, 0.35)
