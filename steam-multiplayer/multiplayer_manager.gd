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
		
		multiplayer.peer_connected.connect(_add_player)
		multiplayer.peer_disconnected.connect(_remove_player)
		
		await get_tree().process_frame
		
		print("Lobby created, lobby id: ", lobby_id)
		
		_add_player()

func _on_lobby_joined(lobby_id: int, perms: int, locked: bool, response: int):
	if !is_joining:
		return
	
	self.lobby_id = lobby_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobby_id))
	multiplayer.multiplayer_peer = peer
	
	if is_host:
		_add_player(multiplayer.get_unique_id())
	
	
	is_joining = false

func _add_player(id: int = 1):
	if has_node(str(id)):
		print("Player already exists. Aborting summon.")
		return
	
	var player = player_scene.instantiate()
	player.name = str(id)
	
	# Server Owns ALL Players
	player.set_multiplayer_authority(1)
		
	call_deferred("add_child", player)
	
func _remove_player(id: int):
	if !self.has_node(str(id)):
		return
	
	self.get_node(str(id)).queue_free()

func _on_host_pressed() -> void:
	host_lobby()
	
func _on_join_pressed() -> void:
	if is_host:
		return
	join_lobby(id_prompt.text.to_int())

func _on_id_prompt_text_changed(new_text: String) -> void:
	join.disabled = (new_text.length() == 0)
