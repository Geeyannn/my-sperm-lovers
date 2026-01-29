# Level 2 Puzzle Refactoring Plan

## Overview
Refactor the 4 scripts identified as needing work. The elevator system (`elevator.gd`, `elevator_zone_validator.gd`, `button_elevator.gd`) is already well-structured.

---

## Priority 1: `sibling_sperm_lvl_2.gd` (Most Issues)

### Issue 1: Duplicate Separation Methods
**Problem**: Two nearly identical methods - `_apply_separation()` and `get_separation_from_enemies()`

**Fix**: Remove `_apply_separation()`, use `get_separation_from_enemies()` everywhere
```gdscript
# DELETE _apply_separation() (lines ~200-209)
# Keep get_separation_from_enemies() and use it in _handle_toilet_attraction()
```

### Issue 2: Hardcoded Attraction Fallback
**Problem**: Line 100 has hardcoded coordinates `Vector3(16.0, 0.8, -7.0)`

**Fix**: Remove hardcoded fallback, rely on group lookup only
```gdscript
func _find_toilet_attraction_target() -> void:
    var toilets = get_tree().get_nodes_in_group("attraction_toilet")
    if toilets.size() > 0:
        toilet_attraction_position = toilets[0].global_position
    else:
        push_warning("No attraction_toilet found in scene!")
        toilet_attraction_position = global_position  # Stay in place
```

### Issue 3: Aggro State Never Resets
**Problem**: Once `is_aggro = true`, it never becomes false. Sperm can hurt player even when static.

**Fix**: Add aggro reset when attraction starts, and prevent attack when static
```gdscript
func start_attraction_to_toilet() -> void:
    is_attracted_to_toilet = true
    is_aggro = false  # Reset aggro when attracted
    is_chasing = false

func check_continuous_attack() -> void:
    if not is_aggro or not can_attack or not attack_hitbox: return
    if static_mode: return  # ADD THIS - Don't attack when static
```

### Issue 4: Over-Complex Target Finding
**Problem**: Three separate methods to find attraction target

**Fix**: Consolidate into single robust method (see Issue 2 fix above)

---

## Priority 2: `elevato_map_manager.gd`

### Issue 1: Fixed Y-Axis Offset Causes Floating/Stacking
**Problem**: `vertical_offset` is added to all spawns regardless of terrain

**Fix**: Use raycast to find ground, or spawn at marker position directly
```gdscript
func _spawn_sibling_at(marker: Marker3D) -> void:
    var sibling = SiblingScene.instantiate()
    # Use marker position directly - markers should be placed correctly in editor
    sibling.global_position = marker.global_position
    # OR use raycast for ground detection:
    # var ground_pos = _raycast_to_ground(marker.global_position)
    # sibling.global_position = ground_pos
```

### Issue 2: Incomplete Signal Handlers
**Problem**: `_handle_sibling_died()` and `_handle_sibling_removed()` have TODO comments

**Fix**: Implement proper tracking
```gdscript
var active_siblings: Array[Node] = []

func _handle_sibling_died(sibling: Node) -> void:
    active_siblings.erase(sibling)
    # Optionally trigger respawn after cooldown

func _handle_sibling_removed(sibling: Node) -> void:
    active_siblings.erase(sibling)
```

### Issue 3: O(n²) Stacking Prevention
**Problem**: Proximity check iterates all spawned siblings for each new spawn

**Fix**: For small numbers (<20), current approach is fine. For larger counts, use spatial partitioning. Keep as-is for now since enemy count is low.

---

## Priority 3: `attraction_trigger.gd`

### Issue 1: Incomplete Exit Behavior
**Problem**: Commented-out `stop_attraction_to_toilet()` on exit

**Fix**: Keep sperms attracted permanently (matches intended puzzle design)
```gdscript
func _on_body_exited(body: Node3D) -> void:
    # Sperms stay attracted to toilet even after leaving trigger
    # This is intentional - they should keep moving toward elevator
    pass
```

### Issue 2: Tight Coupling
**Problem**: Hardcoded method names create coupling

**Fix**: Use signals instead (optional, lower priority)
```gdscript
signal attraction_triggered(target_position: Vector3)

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("enemies") and body.has_method("start_attraction_to_toilet"):
        body.start_attraction_to_toilet()
```

---

## Priority 4: `elevator_trigger.gd` (If it exists)

Based on exploration, this may have been refactored into `elevator.gd`. Verify if separate file exists and remove redundant code.

---

## Implementation Order

1. **sibling_sperm_lvl_2.gd** - Fix aggro/attack issue first (player safety)
2. **sibling_sperm_lvl_2.gd** - Remove duplicate separation method
3. **sibling_sperm_lvl_2.gd** - Fix hardcoded attraction fallback
4. **elevato_map_manager.gd** - Fix Y-axis spawn position
5. **elevato_map_manager.gd** - Implement signal handlers
6. **attraction_trigger.gd** - Clarify exit behavior (minor)

---

## Files to Modify

| File | Changes |
|------|---------|
| `scripts/sibling_sperm_lvl_2.gd` | Remove duplicate method, fix aggro reset, remove hardcoded coords, add static attack guard |
| `scripts/elevato_map_manager.gd` | Fix spawn position, implement signal handlers |
| `scripts/attraction_trigger.gd` | Minor cleanup of exit behavior |

---

## Testing Checklist

- [ ] Sperms spawn at correct height (not floating)
- [ ] Sperms don't stack on each other
- [ ] Sperms are attracted to toilet and stay attracted
- [ ] Sperms don't attack player when in static/attracted state
- [ ] Elevator validates correctly (player only, no enemies)
- [ ] Elevator ascends when conditions met
- [ ] Killing sperms triggers respawn (if intended)
