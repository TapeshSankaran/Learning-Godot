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
		
		await get_tree().process_frame
		
		print("Lobby created, lobby id: ", lobby_id)
		print("Host ID: ", multiplayer.get_unique_id())
		print("Is Server: ", multiplayer.is_server())
		
		_add_player_local(multiplayer.get_unique_id())

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
	print("My ID: ", multiplayer.get_unique_id(), " Is Server: ", multiplayer.is_server())
		
	is_joining = false

func _on_connected_to_server():
	print("Successfully connected to server!")
	print("My ID: ", multiplayer.get_unique_id(), " Is Server: ", multiplayer.is_server())
	print("Peers: ", multiplayer.get_peers())

func _on_connection_failed():
	print("Connection to server failed!")

func _on_peer_connected(id):
	print("[", multiplayer.get_unique_id(), "] Peer connected: ", id, " (Is Server: ", multiplayer.is_server(), ")")
	print("Current peers: ", multiplayer.get_peers())
	print("Current children: ", get_children().map(func(c): return c.name if c is CharacterBody2D else null))

	if is_host:
		print("Server: Spawning player for peer ", id)
		_add_player_local(id)
		
		print("Server: Broadcasting spawn for peer ", id)
		spawn_player.rpc(id)
		
		print("Server: Sending existing players to peer ", id)
		for child in get_children():
			if child is CharacterBody2D:
				var existing_id = child.name.to_int()
				print("  - Telling peer ", id, " about player ", existing_id)
				spawn_player.rpc_id(id, existing_id)

func _on_peer_disconnected(id):
	print("Peer disconnected: ", id)
	_remove_player(id)
	
	if is_host:
		remove_player.rpc(id)

@rpc("any_peer", "call_local", "reliable")
func spawn_player(id: int):
	print("[", multiplayer.get_unique_id(), "] Received spawn_player RPC for ID: ", id)
	if not is_host:
		print("Client: Spawning player ", id)
		_add_player_local(id)
	else:
		print("Server: Ignoring spawn_player RPC (already spawned locally)")

# RPC: Server tells clients to remove a player
@rpc("any_peer", "call_local", "reliable")
func remove_player(id: int):
	if not is_host:
		_remove_player(id)

func _add_player_local(id: int):
	if has_node(str(id)):
		print("Player ", id, " already exists. Skipping.")
		return
	
	var player = player_scene.instantiate()
	player.name = str(id)
	
	var server_id = Steam.getLobbyOwner(lobby_id) if lobby_id > 0 else multiplayer.get_unique_id()
	
	player.set_multiplayer_authority(server_id)
	
	add_child(player, true)
	print("✓ Spawned player ", id, " with authority: ", player.get_multiplayer_authority())
	print("  Current players: ", get_children().filter(func(c): return c is CharacterBody2D).map(func(c): return c.name))
	
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
