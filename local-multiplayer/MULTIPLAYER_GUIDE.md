# Godot 4 Server-Authoritative Multiplayer Setup Guide

## Key Issues Fixed in Your Code:

### 1. The "Weird Movement" Problem
**Issue**: Both players were receiving input but the collision/physics was conflicting.
**Solution**: 
- Separate input gathering (in `_process`) from physics simulation (in `_physics_process`)
- Use `call_remote` instead of default RPC mode to prevent local execution
- Improved interpolation on clients

### 2. Client Not Joining
**Issue**: Server spawned players, but clients didn't know about them
**Solution**: Only server spawns players (check `multiplayer.is_server()`)

---

## Setup Instructions

### Player Scene Structure:
```
Player (CharacterBody2D) [player.gd attached]
├─ Sprite2D
├─ CollisionShape2D
└─ MultiplayerSynchronizer
```

### Player MultiplayerSynchronizer Setup:
1. Select the MultiplayerSynchronizer node
2. Set "Root Path" to `..` (points to parent Player node)
3. In "Replication" section, click "Properties" and add:
   - `:position` (or `global_position` if you prefer)
   - `:rotation`
   - `velocity`

### Main Scene for Testing:
```
Main (Node2D) [local_multiplayer.gd attached]
├─ HostButton (Button)
├─ JoinButton (Button)
└─ (Players will spawn here as children)
```

Connect the buttons:
- HostButton.pressed → `_on_host_pressed`
- JoinButton.pressed → `_on_join_pressed`

---

## Syncing RigidBody Objects

You have two options:

### Option 1: Manual Sync (More Control)
Use `synced_rigidbody.gd` - gives you full control over sync rate and interpolation.

### Option 2: MultiplayerSynchronizer (Simpler)
Use `synced_rigidbody_simple.gd` - cleaner code, Godot handles sync automatically.

**For Option 2, add a MultiplayerSynchronizer child to your RigidBody2D:**
```
Box (RigidBody2D) [synced_rigidbody_simple.gd attached]
├─ Sprite2D
├─ CollisionShape2D
└─ MultiplayerSynchronizer
    Set Root Path: ..
    Replication Properties:
    - global_position
    - rotation
    - linear_velocity
    - angular_velocity
```

---

## Important Notes

### Server Authority Benefits:
- ✅ Prevents cheating
- ✅ Consistent physics simulation
- ✅ Single source of truth
- ✅ Easier to validate player actions

### How It Works:
1. **Input**: Each player sends their input to the server
2. **Physics**: Server simulates ALL physics (players + objects)
3. **Sync**: Server broadcasts positions/states to all clients
4. **Display**: Clients interpolate smoothly between states

### Performance Tips:
- Use `"unreliable"` for frequent updates (position, velocity)
- Use `"reliable"` for important events (spawn, damage, score)
- Adjust interpolation factor (0.3) based on your network conditions:
  - Lower (0.1-0.2) = smoother but more latency
  - Higher (0.4-0.5) = more responsive but potentially jittery

### Debugging:
Add these to see what's happening:
```gdscript
print("Is Server:", multiplayer.is_server())
print("My ID:", multiplayer.get_unique_id())
print("Authority:", get_multiplayer_authority())
```

---

## Common Issues & Solutions

**Problem**: Player movement feels delayed
- Increase interpolation factor in player.gd (line with `.lerp`)

**Problem**: Players teleport instead of moving smoothly
- Make sure sync_state uses `"unreliable"` mode
- Check network connection stability

**Problem**: Objects don't sync
- Verify MultiplayerSynchronizer root path is correct
- Ensure server authority is set (authority = 1)
- Check that properties are added to replication list

**Problem**: Client can't connect
- Check firewall settings
- Try using actual IP address instead of "localhost"
- Verify port 135 is available

---

## Testing Locally

1. Run first instance → Click "Host"
2. Run second instance → Click "Join"
3. Use arrow keys to control your player
4. Other player should move when they use arrow keys

For internet play, replace "localhost" with the host's IP address.
