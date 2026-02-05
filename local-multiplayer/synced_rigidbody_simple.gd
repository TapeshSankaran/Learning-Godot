extends RigidBody2D

func _ready():
	set_multiplayer_authority(1)
	
	if has_node("MultiplayerSynchronizer"):
		$MultiplayerSynchronizer.set_multiplayer_authority(1)
		
	_setup_physics_mode()

func _setup_physics_mode():
	if multiplayer.multiplayer_peer == null:
		print("[RigidBody:", name, "] No multiplayer peer - running in single player mode")
		return

	await get_tree().process_frame

	if not multiplayer.is_server():
		freeze_mode = FreezeMode.FREEZE_MODE_KINEMATIC
		freeze = true
		print("[RigidBody:", name, "] Client mode - physics frozen, will sync from server")
	else:
		print("[RigidBody:", name, "] Server mode - physics active")
