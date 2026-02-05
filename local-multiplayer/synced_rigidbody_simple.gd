extends RigidBody2D

# Alternative approach using MultiplayerSynchronizer
# This is simpler but requires setting up a MultiplayerSynchronizer child node

func _ready():
	# Server has authority over physics
	set_multiplayer_authority(1)
	
	if has_node("MultiplayerSynchronizer"):
		$MultiplayerSynchronizer.set_multiplayer_authority(1)
	print("Is this a multiplayer server: ", multiplayer.is_server())
	# Only server simulates physics
	if not multiplayer.is_server():
		# Client: Make it kinematic instead of frozen
		# This allows position updates while preventing local physics simulation
		freeze_mode = FreezeMode.FREEZE_MODE_KINEMATIC
		freeze = true
		print(" [RigidBody]: Frozen on client")

# Server handles all physics, clients just display the synced state
# No additional code needed if you set up MultiplayerSynchronizer correctly!

# HOW TO SET UP MultiplayerSynchronizer:
# 1. Add a MultiplayerSynchronizer node as a child of this RigidBody2D
# 2. In the MultiplayerSynchronizer properties, add these to "Replication" -> "Properties":
#    - global_position
#    - rotation
#    - linear_velocity
#    - angular_velocity
# 3. Set "Root Path" to ".." (parent)
# 4. Set replication interval if needed (default is fine)
# 5. That's it! The synchronizer will automatically sync these properties
