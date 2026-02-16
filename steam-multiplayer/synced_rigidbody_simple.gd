extends RigidBody2D

var target_position: Vector2
var target_rotation: float

func _ready():
	await get_tree().process_frame

	set_multiplayer_authority(1)	
	if has_node("MultiplayerSynchronizer"):
		$MultiplayerSynchronizer.set_multiplayer_authority(1)
	
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
