extends CharacterBody2D

@export var SPEED := 400
var input_dir := Vector2.ZERO
var target_pos := Vector2.ZERO
var target_vel := Vector2.ZERO
var owner_id: int

func _ready():
	owner_id = name.to_int()
	target_pos = global_position
	
	await get_tree().process_frame
	
	if has_node("MultiplayerSynchronizer"):
		$MultiplayerSynchronizer.set_multiplayer_authority(get_multiplayer_authority())
	
	print("Player ", owner_id, " ready. Local ID: ", multiplayer.get_unique_id(), " Is Server: ", multiplayer.is_server(), " Authority: ", get_multiplayer_authority())

func _physics_process(delta):
	if multiplayer.is_server():
		velocity = input_dir * SPEED
		move_and_slide()
		sync_state.rpc(global_position, velocity)
	else:
		global_position = global_position.lerp(target_pos, 0.25)
		velocity = target_vel
		
func _process(delta):
	if multiplayer.is_server():
		return

	var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	send_input.rpc_id(1, multiplayer.get_unique_id(), dir)

		
@rpc("any_peer", "call_remote", "reliable")
func send_input(sender_id: int, dir: Vector2):
	if not multiplayer.is_server():
		return

	if name.to_int() == sender_id:
		input_dir = dir

@rpc("authority", "call_remote", "unreliable")
func sync_state(pos: Vector2, vel: Vector2):
	if not multiplayer.is_server():
		target_pos = pos
		target_vel = vel
