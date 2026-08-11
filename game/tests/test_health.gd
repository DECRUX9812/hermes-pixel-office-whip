extends TestCase

var _depleted_count := 0

func test_take_damage_reduces_health() -> void:
	var health := HealthComponent.new()
	add_child(health)
	health.reset()
	check(health.take_damage(25.0), "damage accepted")
	check_eq(health.current_health, 75.0, "health reduced by 25")
	health.queue_free()

func test_heal_clamps_to_max() -> void:
	var health := HealthComponent.new()
	add_child(health)
	health.reset()
	health.take_damage(10.0)
	health.heal(500.0)
	check_eq(health.current_health, health.max_health, "heal clamps to max")
	health.queue_free()

func test_depleted_emits_once() -> void:
	_depleted_count = 0
	var health := HealthComponent.new()
	add_child(health)
	health.reset()
	health.depleted.connect(_on_depleted)
	health.take_damage(100.0)
	health.take_damage(50.0)
	check_eq(_depleted_count, 1, "depleted emitted exactly once")
	check_eq(health.current_health, 0.0, "health clamped at zero")
	health.depleted.disconnect(_on_depleted)
	health.queue_free()

func _on_depleted(_source: Node) -> void:
	_depleted_count += 1

func test_hit_invulnerability_blocks_second_hit() -> void:
	var health := HealthComponent.new()
	add_child(health)
	health.reset()
	health.take_damage(20.0)
	var blocked := health.take_damage(20.0)
	check(not blocked, "post-hit invulnerability blocks second hit")
	check_eq(health.current_health, 80.0, "no double damage applied")
	health.queue_free()

func test_dodge_invulnerability_window_blocks_damage() -> void:
	var health := HealthComponent.new()
	add_child(health)
	health.reset()
	health.grant_invulnerability_window(0.5)
	check(not health.take_damage(10.0), "damage blocked inside invulnerability window")
	check_eq(health.current_health, health.max_health, "health untouched while invulnerable")
	health.queue_free()

func test_negative_damage_rejected() -> void:
	var health := HealthComponent.new()
	add_child(health)
	health.reset()
	check(not health.take_damage(-5.0), "negative damage rejected")
	health.queue_free()
