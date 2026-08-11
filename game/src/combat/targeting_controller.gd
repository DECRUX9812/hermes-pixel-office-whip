class_name TargetingController
extends Node3D
## Combat targeting: lock-on plus soft target fallback.
##
##   - Lock-on (Tab): pins the nearest hostile in range; the camera drifts toward
##     the target so it stays framed. Lock breaks when the target dies or leaves
##     the chain. In lock the player still moves camera-relative.
##   - Soft targeting: with no lock, attacks and companion commands auto-aim at
##     the nearest hostile inside a forward cone, so the staff reads as magnetic
##     without being a tracking weapon.
##
## Targets are any node in the "hostile" group that reports itself alive and
## hostile (duck-typed, so blockout dummies, Custodians and the Warden all work).

const HOSTILE_GROUP := "hostile"

@export var lock_range := 22.0
@export var soft_range := 6.0
@export var soft_cone_degrees := 70.0
@export var camera_follow_speed := 4.5

var locked_target: Node3D = null

func toggle_lock(player: Player) -> void:
	if locked_target != null:
		release()
		return
	var target := _nearest_hostile(player, lock_range)
	if target == null:
		EventBus.combat_event.emit("No target to lock")
		return
	locked_target = target
	EventBus.target_locked.emit(target)
	EventBus.combat_event.emit("Locked on %s" % _label(target))

func release() -> void:
	if locked_target == null:
		return
	locked_target = null
	EventBus.target_released.emit()

func is_locked() -> bool:
	return locked_target != null

func get_target(player: Player) -> Node3D:
	if locked_target != null:
		if is_instance_valid(locked_target) and _is_live_target(locked_target):
			return locked_target
		release()
	return acquire_soft_target(player, soft_range)

func acquire_soft_target(player: Player, max_range: float) -> Node3D:
	if player == null:
		return null
	var origin := player.global_position
	var forward := player.camera_rig.get_flat_forward()
	var cone_cos := cos(deg_to_rad(soft_cone_degrees))
	var best: Node3D = null
	var best_score := INF
	for node in get_tree().get_nodes_in_group(HOSTILE_GROUP):
		var candidate := node as Node3D
		if candidate == null or not _is_live_target(candidate):
			continue
		var flat_to := _flat(candidate.global_position - origin)
		var distance_sq := flat_to.length_squared()
		if distance_sq <= 0.0001 or distance_sq > max_range * max_range:
			continue
		var dir := flat_to.normalized()
		var dot := forward.dot(dir)
		if dot < cone_cos:
			continue
		# Prefer targets in front and close: dot dominates, distance breaks ties.
		var score := distance_sq / maxf(dot, 0.05)
		if score < best_score:
			best_score = score
			best = candidate
	return best

func update(player: Player, delta: float) -> void:
	if locked_target == null or player == null:
		return
	if not is_instance_valid(locked_target) or not _is_live_target(locked_target):
		release()
		return
	var to_target := player.global_position.direction_to(locked_target.global_position)
	var target_yaw := atan2(-to_target.x, -to_target.z)
	var rig := player.camera_rig
	var blended := lerp_angle(rig.yaw, target_yaw, minf(1.0, camera_follow_speed * delta))
	rig.set_yaw(blended)

func _nearest_hostile(player: Player, max_range: float) -> Node3D:
	if player == null:
		return null
	var origin := player.global_position
	var best: Node3D = null
	var best_distance_sq := max_range * max_range
	for node in get_tree().get_nodes_in_group(HOSTILE_GROUP):
		var candidate := node as Node3D
		if candidate == null or not _is_live_target(candidate):
			continue
		var distance_sq := _flat(candidate.global_position - origin).length_squared()
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best = candidate
	return best

func _is_live_target(node: Node3D) -> bool:
	if node.has_method("is_hostile") and not node.is_hostile():
		return false
	var health := _resolve_health(node)
	if health:
		return not health.is_dead()
	return node.has_method("is_hostile")

func _resolve_health(node: Node) -> HealthComponent:
	if node is HealthComponent:
		return node as HealthComponent
	var direct := node.get_node_or_null("Health") as HealthComponent
	if direct:
		return direct
	var parent := node.get_parent()
	if parent is HealthComponent:
		return parent as HealthComponent
	if parent is Node:
		return parent.get_node_or_null("Health") as HealthComponent
	return null

func _label(target: Node3D) -> String:
	if target.has_method("display_name"):
		return str(target.display_name)
	return target.name

func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
