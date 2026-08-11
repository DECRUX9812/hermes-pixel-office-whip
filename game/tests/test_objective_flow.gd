extends TestCase

var _flow_completed := false

func _make_flow() -> ObjectiveFlow:
	var flow := ObjectiveFlow.new()
	var make := func(id: String, label: String) -> Objective:
		var objective := Objective.new()
		objective.id = id
		objective.label = label
		return objective
	flow.objectives = [
		make.call("a", "A"),
		make.call("b", "B"),
		make.call("c", "C"),
	]
	add_child(flow)
	return flow

func test_advances_in_order() -> void:
	var flow := _make_flow()
	flow.begin()
	check(flow.current.id == "a", "first objective active")
	check(flow.complete("a"), "a completes")
	check(flow.current.id == "b", "advanced to b")
	check(flow.complete("b"), "b completes")
	check(flow.current.id == "c", "advanced to c")
	check(flow.complete("c"), "c completes")
	check(flow.current == null, "flow completed after last objective")
	flow.queue_free()

func test_out_of_order_rejected() -> void:
	var flow := _make_flow()
	flow.begin()
	check(not flow.complete("b"), "out-of-order completion rejected")
	check(flow.current.id == "a", "still on first objective")
	flow.queue_free()

func test_completion_before_begin_rejected() -> void:
	var flow := _make_flow()
	check(not flow.complete("a"), "completion rejected before begin()")
	check(flow.current == null, "no current before begin")
	flow.queue_free()

func test_has_reached() -> void:
	var flow := _make_flow()
	flow.begin()
	flow.complete("a")
	check(flow.has_reached("a"), "a reached")
	check(not flow.has_reached("c"), "c not reached")
	flow.queue_free()

func test_flow_completed_signal() -> void:
	_flow_completed = false
	var flow := _make_flow()
	flow.flow_completed.connect(_on_flow_completed)
	flow.begin()
	flow.complete("a")
	flow.complete("b")
	flow.complete("c")
	check(_flow_completed, "flow_completed emitted after final objective")
	flow.flow_completed.disconnect(_on_flow_completed)
	flow.queue_free()

func _on_flow_completed() -> void:
	_flow_completed = true
