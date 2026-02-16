extends RigidBody2D

var target_position: Vector2
var target_rotation: float

func _ready():
	await get_tree().process_frame
	_setup_physics_mode()


func _setup_physics_mode():
	if multiplayer.multiplayer_peer == null:
		return

	if multiplayer.is_server():
		freeze = false
		sleeping = false
		print("[RigidBody:", name, "] Server mode - physics active")
	else:
		freeze = true
		sleeping = true

		collision_layer = 0
		collision_mask = 0

		print("[RigidBody:", name, "] Client mode - physics disabled")


func _physics_process(delta):
	if multiplayer.is_server():
		sync_state.rpc(global_position, rotation)


@rpc("authority", "call_remote", "unreliable")
func sync_state(pos: Vector2, rot: float):
	if not multiplayer.is_server():
		target_position = pos
		target_rotation = rot


func _process(delta):
	if not multiplayer.is_server():
		global_position = global_position.lerp(target_position, 0.35)
		rotation = lerp_angle(rotation, target_rotation, 0.35)
