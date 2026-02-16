extends Node2D

@export var player_scene: PackedScene
var peer: SteamMultiplayerPeer
var lobby_id: int = 0
var is_host: bool = false
var is_joining: bool = false

@onready var host: Button = $Host
@onready var join: Button = $Join
@onready var id_prompt: LineEdit = $IDPrompt

func _ready():
	print("Steam init: ", Steam.steamInit(480, true))
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	
func host_lobby():
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, 16)
	is_host = true
	
func join_lobby(lobby_id: int):
	is_joining = true
	Steam.joinLobby(lobby_id)

func _on_lobby_created(result: int, lobby_id: int):
	if result == Steam.Result.RESULT_OK:
		self.lobby_id = lobby_id
		
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		multiplayer.multiplayer_peer = peer
		
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		
		# Wait for Steam to fully initialize the peer
		await get_tree().process_frame
		
		print("Lobby created, lobby id: ", lobby_id)
		print("Host ID: ", multiplayer.get_unique_id())
		
		# Spawn the host player using the actual peer ID
		_add_player(multiplayer.get_unique_id())

func _on_lobby_joined(lobby_id: int, perms: int, locked: bool, response: int):
	if !is_joining:
		return
	
	self.lobby_id = lobby_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobby_id))
	multiplayer.multiplayer_peer = peer
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	print("Attempting to connect to server...")
	print(" [", multiplayer.get_unique_id(), "]: Before connection - Is Server:", multiplayer.is_server())
		
	is_joining = false

func _on_connected_to_server():
	print("Successfully connected to server!")
	print(" [", multiplayer.get_unique_id(), "]: After connection - Is Server: ", multiplayer.is_server())

func _on_connection_failed():
	print("Connection to server failed!")

func _on_peer_connected(id):
	print(" [", multiplayer.get_unique_id(), "]: Peer connected: ", id, " (Is Server: ", multiplayer.is_server(), ")")

	# Only the host spawns players
	if is_host:
		print("Server: Spawning player for peer ", id)
		_add_player(id)
	else:
		print("Client: Not spawning (server will handle it)")

func _on_peer_disconnected(id):
	print("Peer disconnected: ", id)
	_remove_player(id)
	
func _add_player(id: int):
	if has_node(str(id)):
		print("Player ", id, " already exists. Aborting summon.")
		return
	
	var player = player_scene.instantiate()
	player.name = str(id)
	
	# Get the server's ID (host's Steam ID)
	var server_id = 1  # Default for ENet
	if multiplayer.multiplayer_peer is SteamMultiplayerPeer:
		# For Steam, server ID is the host's Steam ID
		server_id = Steam.getLobbyOwner(lobby_id) if lobby_id > 0 else multiplayer.get_unique_id()
	
	# Server always has authority over ALL players' physics
	player.set_multiplayer_authority(server_id)
	
	add_child(player, true)
	print("Spawned player ", id, " with authority: ", player.get_multiplayer_authority())
	
func _remove_player(id: int):
	if !self.has_node(str(id)):
		return
	
	self.get_node(str(id)).queue_free()
	print("Removed player ", id)

func _on_host_pressed() -> void:
	host_lobby()
	
func _on_join_pressed() -> void:
	if is_host:
		return
	join_lobby(id_prompt.text.to_int())

func _on_id_prompt_text_changed(new_text: String) -> void:
	join.disabled = (new_text.length() == 0)
