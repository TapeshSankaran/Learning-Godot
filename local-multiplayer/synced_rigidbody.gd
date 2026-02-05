extends RigidBody2D

# This script syncs RigidBody2D objects across the network
# Attach this to any physics object you want to sync (boxes, balls, etc.)

var target_pos := Vector2.ZERO
var target_rot := 0.0
var target_linear_vel := Vector2.ZERO
var target_angular_vel := 0.0
var is_initialized := false

func _ready():
	# Server has authority over all scene physics objects
	set_multiplayer_authority(1)
	
	target_pos = global_position
	target_rot = rotation
	
	# Wait for multiplayer to be initialized before setting up
	_setup_physics_mode()

func _setup_physics_mode():
	# Check if multiplayer is actually active
	if multiplayer.multiplayer_peer == null:
		# No multiplayer yet - this is single player or before host/join
		print("[RigidBody:", name, "] No multiplayer peer - running in single player mode")
		is_initialized = true
		return
	
	# Wait a frame to ensure peer is fully initialized
	await get_tree().process_frame
	
	# Now check if we're the server
	if not multiplayer.is_server():
		# Client: Use kinematic freeze mode so position updates work
		freeze_mode = FreezeMode.FREEZE_MODE_KINEMATIC
		freeze = true
		print("[RigidBody:", name, "] Client mode - physics frozen, will sync from server")
	else:
		print("[RigidBody:", name, "] Server mode - physics active")
	
	is_initialized = true

func _physics_process(delta):
	# Don't do anything until multiplayer is initialized
	if not is_initialized:
		return
	
	# If no multiplayer, just run normal physics
	if multiplayer.multiplayer_peer == null:
		return
	
	if multiplayer.is_server():
		# Server: Physics simulation happens automatically
		# Just send state to all clients
		sync_physics.rpc(global_position, rotation, linear_velocity, angular_velocity)
	else:
		# Clients: Smoothly interpolate to server state
		global_position = global_position.lerp(target_pos, 0.3)
		rotation = lerp_angle(rotation, target_rot, 0.3)
		# Update velocity for visual effects (particles, trails, etc.)
		linear_velocity = target_linear_vel
		angular_velocity = target_angular_vel

@rpc("authority", "call_remote", "unreliable")
func sync_physics(pos: Vector2, rot: float, lin_vel: Vector2, ang_vel: float):
	target_pos = pos
	target_rot = rot
	target_linear_vel = lin_vel
	target_angular_vel = ang_vel
