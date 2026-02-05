extends RigidBody2D

# DEBUG VERSION - Use this to troubleshoot syncing issues
# This has extra print statements to help you see what's happening

var target_pos := Vector2.ZERO
var target_rot := 0.0
var target_linear_vel := Vector2.ZERO
var target_angular_vel := 0.0

func _ready():
	set_multiplayer_authority(1)
	
	target_pos = global_position
	target_rot = rotation
	
	print("[RigidBody:", name, "] Ready - Is Server:", multiplayer.is_server(), "My ID:", multiplayer.get_unique_id())
	
	if not multiplayer.is_server():
		freeze_mode = FreezeMode.FREEZE_MODE_KINEMATIC
		freeze = true
		print("[RigidBody:", name, "] Client mode - freeze enabled")
	else:
		print("[RigidBody:", name, "] Server mode - physics active")

func _physics_process(delta):
	if multiplayer.is_server():
		# Server: Send updates
		if linear_velocity.length() > 0.1 or angular_velocity != 0:
			print("[RigidBody:", name, "] Server sending - Pos:", global_position, "Vel:", linear_velocity)
		sync_physics.rpc(global_position, rotation, linear_velocity, angular_velocity)
	else:
		# Clients: Receive and interpolate
		var distance = global_position.distance_to(target_pos)
		if distance > 1.0:  # Only print if moving significantly
			print("[RigidBody:", name, "] Client updating - Current:", global_position, "Target:", target_pos, "Distance:", distance)
		
		global_position = global_position.lerp(target_pos, 0.3)
		rotation = lerp_angle(rotation, target_rot, 0.3)
		linear_velocity = target_linear_vel
		angular_velocity = target_angular_vel

@rpc("authority", "call_remote", "unreliable")
func sync_physics(pos: Vector2, rot: float, lin_vel: Vector2, ang_vel: float):
	target_pos = pos
	target_rot = rot
	target_linear_vel = lin_vel
	target_angular_vel = ang_vel

# DEBUGGING CHECKLIST:
# 1. Does the object appear in BOTH instances?
# 2. Can you push it on the HOST instance?
# 3. Does it move on the CLIENT instance when pushed on host?
# 4. Check console for these prints to verify sync is working
# 5. Make sure MultiplayerSynchronizer is set up correctly if using simple version
