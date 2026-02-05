extends Node2D

@export var player_scene: PackedScene
var peer := ENetMultiplayerPeer.new()
var is_host := false

func _on_host_pressed():
	is_host = true
	
	# Create and set the peer FIRST
	peer.create_server(135)
	multiplayer.multiplayer_peer = peer
	
	# THEN connect signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	print("Server started. My ID:", multiplayer.get_unique_id())
	
	# Wait one frame to ensure peer is fully initialized
	await get_tree().process_frame
	
	# Now spawn the host player
	_add_player(1)

func _on_join_pressed():
	is_host = false
	
	# Create and set the peer FIRST
	peer.create_client("localhost", 135)
	multiplayer.multiplayer_peer = peer
	
	# THEN connect signals
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	print("Attempting to connect to server...")
	print(" [", multiplayer.get_unique_id(), "]: Before connection - Is Server:", multiplayer.is_server())

func _on_connected_to_server():
	print("Successfully connected to server!")
	print(" [", multiplayer.get_unique_id(), "]: After connection - Is Server: ", multiplayer.is_server())

func _on_connection_failed():
	print("Connection to server failed!")

func _on_peer_connected(id):
	print(" [", multiplayer.get_unique_id(), "]: Peer connected: ", id, " (Is Server: ", multiplayer.is_server(), ")")
	
	# CRITICAL: Only spawn if we are the actual server
	# Use is_host flag instead of multiplayer.is_server() for reliability
	if is_host:
		print("Server: Spawning player for peer ", id)
		_add_player(id)
	else:
		print("Client: Not spawning (server will handle it)")

func _on_peer_disconnected(id):
	print("Peer disconnected: ", id)
	_remove_player(id)

func _add_player(id: int):
	# Prevent duplicate spawns
	if has_node(str(id)):
		print("Player ", id, " already exists, skipping spawn")
		return
	
	var player = player_scene.instantiate()
	player.name = str(id)
	
	# Server always has authority over physics
	player.set_multiplayer_authority(1)
	
	add_child(player, true)
	print("Spawned player ", id, " with authority: ", player.get_multiplayer_authority())

func _remove_player(id: int):
	if has_node(str(id)):
		get_node(str(id)).queue_free()
		print("Removed player ", id)
