extends RigidBody2D

# ULTIMATE DEBUG VERSION - This will tell us exactly what's wrong

var target_pos := Vector2.ZERO
var target_rot := 0.0
var target_linear_vel := Vector2.ZERO
var target_angular_vel := 0.0
var is_initialized := false
var frame_count := 0

func _ready():
	# QUICK FIX - Force proper physics settings
	gravity_scale = 0.0
	mass = 5.0
	linear_damp = 5.0
	angular_damp = 5.0
	
	print("\n========== RIGIDBODY DEBUG START ==========")
	print("[", name, "] _ready() called")
	print("[", name, "] Initial position:", global_position)
	print("[", name, "] Freeze status:", freeze)
	print("[", name, "] Freeze mode:", freeze_mode)
	print("[", name, "] Mass:", mass)
	print("[", name, "] Gravity scale:", gravity_scale)
	
	# Check multiplayer state
	print("[", name, "] multiplayer.multiplayer_peer:", multiplayer.multiplayer_peer)
	if multiplayer.multiplayer_peer != null:
		print("[", name, "] Peer connection status:", multiplayer.multiplayer_peer.get_connection_status())
		print("[", name, "] My ID:", multiplayer.get_unique_id())
		print("[", name, "] Is Server:", multiplayer.is_server())
	else:
		print("[", name, "] NO MULTIPLAYER PEER - Single player mode")
	
	set_multiplayer_authority(1)
	target_pos = global_position
	target_rot = rotation
	
	_setup_physics_mode()
	print("========== RIGIDBODY DEBUG END ==========\n")

func _setup_physics_mode():
	if multiplayer.multiplayer_peer == null:
		print("[", name, "] Keeping default physics (no multiplayer)")
		is_initialized = true
		return
	
	await get_tree().process_frame
	
	print("[", name, "] After frame wait:")
	print("[", name, "] Is Server:", multiplayer.is_server())
	print("[", name, "] My ID:", multiplayer.get_unique_id())
	
	if not multiplayer.is_server():
		freeze_mode = FreezeMode.FREEZE_MODE_KINEMATIC
		freeze = true
		print("[", name, "] CLIENT MODE - Frozen for sync")
	else:
		print("[", name, "] SERVER MODE - Physics active")
		print("[", name, "] Can simulate physics: YES")
	
	is_initialized = true

func _physics_process(delta):
	frame_count += 1
	
	# Debug every 60 frames (once per second at 60fps)
	if frame_count % 60 == 0:
		print("[", name, "] Physics update - Pos:", global_position, "Vel:", linear_velocity, "Frozen:", freeze)
	
	if not is_initialized:
		return
	
	if multiplayer.multiplayer_peer == null:
		# Single player - just use normal physics
		return
	
	if multiplayer.is_server():
		# Server sends state
		if frame_count % 60 == 0 and linear_velocity.length() > 0.1:
			print("[", name, "] SERVER sending - Pos:", global_position, "Vel:", linear_velocity)
		sync_physics.rpc(global_position, rotation, linear_velocity, angular_velocity)
	else:
		# Client interpolates
		var old_pos = global_position
		global_position = global_position.lerp(target_pos, 0.3)
		rotation = lerp_angle(rotation, target_rot, 0.3)
		
		if frame_count % 60 == 0:
			var distance = old_pos.distance_to(target_pos)
			print("[", name, "] CLIENT interpolating - Distance to target:", distance, "Target:", target_pos)
		
		linear_velocity = target_linear_vel
		angular_velocity = target_angular_vel

@rpc("authority", "call_remote", "unreliable")
func sync_physics(pos: Vector2, rot: float, lin_vel: Vector2, ang_vel: float):
	target_pos = pos
	target_rot = rot
	target_linear_vel = lin_vel
	target_angular_vel = ang_vel
	
	if frame_count % 60 == 0:
		print("[", name, "] CLIENT received sync - Target pos:", pos, "Vel:", lin_vel)

# Test function - call this from console to manually move the object
func _test_move():
	print("[", name, "] TEST: Applying force")
	apply_central_impulse(Vector2(100, 0))

# Test function - call this from console to check status
func debug_status():
	print("\n========== STATUS CHECK ==========")
	print("Name:", name)
	print("Position:", global_position)
	print("Velocity:", linear_velocity)
	print("Frozen:", freeze)
	print("Freeze Mode:", freeze_mode)
	print("Mass:", mass)
	print("Is Server:", multiplayer.is_server() if multiplayer.multiplayer_peer else "No multiplayer")
	print("Initialized:", is_initialized)
	print("==================================\n")
