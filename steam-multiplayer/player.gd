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

	if is_multiplayer_authority():
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		velocity = input_dir * SPEED
		move_and_slide()
		
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			if collider is RigidBody2D:
				var push_dir = -collision.get_normal()
				var impulse = push_dir * 200 * delta
				collider.apply_central_impulse(impulse)
		
		sync_state.rpc(global_position, velocity)
	else:
		global_position = global_position.lerp(target_pos, 0.25)
		velocity = target_vel


@rpc("authority", "call_remote", "unreliable")
func sync_state(pos: Vector2, vel: Vector2):
	if not is_multiplayer_authority():
		target_pos = pos
		target_vel = vel
