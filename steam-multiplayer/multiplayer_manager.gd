extends Node2D

@export var player_scene: PackedScene
var peer: SteamMultiplayerPeer
var lobby_id: int = 0
var is_host: bool = false
var is_joining: bool = false
var host_steam_id: int = 0

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
		
		host_steam_id = multiplayer.get_unique_id()
		
		print("=== HOST SETUP ===")
		print("Lobby created, lobby id: ", lobby_id)
		print("Steam.getSteamID(): ", Steam.getSteamID())
		print("multiplayer.get_unique_id(): ", multiplayer.get_unique_id())
		print("Using host_steam_id: ", host_steam_id)
		
		_add_player_local(host_steam_id)

func _on_lobby_joined(lobby_id: int, perms: int, locked: bool, response: int):
	if !is_joining:
		return
	
	self.lobby_id = lobby_id
	host_steam_id = Steam.getLobbyOwner(lobby_id)
	
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(host_steam_id)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	print("=== CLIENT CONNECTING ===")
	print("Connecting to host Steam ID: ", host_steam_id)
	print("My Steam ID (Steam.getSteamID()): ", Steam.getSteamID())
	print("My peer ID (multiplayer.get_unique_id()): ", multiplayer.get_unique_id())
		
	is_joining = false

func _on_connected_to_server():
	print("=== CLIENT CONNECTED ===")
	print("Successfully connected!")
	print("Peers visible: ", multiplayer.get_peers())

func _on_connection_failed():
	print("Connection failed!")

func _on_peer_connected(id):
	print("\n=== PEER_CONNECTED ===")
	print("My multiplayer ID: ", multiplayer.get_unique_id())
	print("Peer ID: ", id)
	print("Is Server: ", multiplayer.is_server())

	if multiplayer.is_server():
		_add_player_local(id)

		spawn_player.rpc(id)

		for child in get_children():
			if child is CharacterBody2D:
				var existing_id = child.name.to_int()
				spawn_player.rpc_id(id, existing_id)

func _on_peer_disconnected(id):
	print("Peer disconnected: ", id)
	_remove_player(id)
	
	if is_host:
		remove_player.rpc(id)

@rpc("any_peer", "call_local", "reliable")
func spawn_player(id: int):
	if not has_node(str(id)):
		_add_player_local(id)

@rpc("any_peer", "call_local", "reliable")
func remove_player(id: int):
	if not is_host:
		_remove_player(id)

func _add_player_local(id: int):
	if has_node(str(id)):
		return
	
	var player = player_scene.instantiate()
	player.name = str(id)

	player.set_multiplayer_authority(id)

	add_child(player, true)

	print("✓ Spawned player ", id, " authority: ", id)
	
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
