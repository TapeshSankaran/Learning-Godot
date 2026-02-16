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
	
	print("Player ", owner_id,
		" | Local ID: ", multiplayer.get_unique_id(),
		" | Authority: ", get_multiplayer_authority())

func _physics_process(delta):

	if is_multiplayer_authority() and not multiplayer.is_server():
		var input_vec = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		send_input.rpc_id(1, input_vec)

	if multiplayer.is_server():
		velocity = input_dir * SPEED
		move_and_slide()
		
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var body = collision.get_collider()
			if body.has_method("request_impulse"):
				var push_dir = -collision.get_normal()
				var push_force = push_dir * 200 * delta
				body.request_impulse.rpc(push_force, collision.get_position())

		sync_state.rpc(global_position, velocity)

	if not multiplayer.is_server() and not is_multiplayer_authority():
		global_position = global_position.lerp(target_pos, 0.35)
		velocity = target_vel


# CLIENT -> SERVER
@rpc("any_peer", "call_remote", "unreliable")
func send_input(dir: Vector2):
	if not multiplayer.is_server():
		return
	
	input_dir = dir


# SERVER -> CLIENTS
@rpc("authority", "call_remote", "unreliable")
func sync_state(pos: Vector2, vel: Vector2):
	if multiplayer.is_server():
		return

	target_pos = pos
	target_vel = vel
