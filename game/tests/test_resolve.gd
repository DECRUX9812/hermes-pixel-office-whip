extends TestCase

func test_spend_restore_and_has() -> void:
	var resolve := ResolveComponent.new()
	add_child(resolve)
	resolve.reset()
	check(resolve.spend(30.0), "spend allowed")
	check_eq(resolve.current_resolve, 70.0, "resolve reduced by 30")
	check(resolve.has(70.0), "has(70) true after spend")
	check(not resolve.spend(200.0), "overspend rejected")
	resolve.restore(1000.0)
	check_eq(resolve.current_resolve, resolve.max_resolve, "restore clamps to max")
	resolve.queue_free()

func test_spend_below_zero_rejected() -> void:
	var resolve := ResolveComponent.new()
	add_child(resolve)
	resolve.reset()
	check(resolve.spend(resolve.max_resolve + 1.0) == false, "spending more than max rejected")
	resolve.queue_free()

func test_regen_after_delay() -> void:
	var resolve := ResolveComponent.new()
	add_child(resolve)
	resolve.reset()
	resolve.regen_delay = 0.2
	resolve.regen_rate = 20.0
	resolve.spend(40.0)
	await _wait_physics(40)
	check(resolve.current_resolve > 60.0, "resolve regenerated after delay")
	resolve.queue_free()

func test_regen_stops_at_max() -> void:
	var resolve := ResolveComponent.new()
	add_child(resolve)
	resolve.reset()
	resolve.regen_delay = 0.0
	resolve.regen_rate = 50.0
	await _wait_physics(40)
	check(is_equal_approx(resolve.current_resolve, resolve.max_resolve), "resolve capped at max")
	resolve.queue_free()
