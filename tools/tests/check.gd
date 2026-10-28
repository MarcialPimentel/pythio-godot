# Pass/fail checks shared by the tests. In a test:
#   const C = preload("res://tools/tests/check.gd")
#   C.ok(value == 30, "Heal heals 30")      # prints PASS/FAIL and counts failures
#   C.near(a, 53.0, "effective healing")     # numbers within half a point
#   C.done(self)                             # instead of quit(): exits 1 if anything failed
# tools/tests/run_all.sh runs every test and fails on a FAIL line, an ERROR, a crash or a hang.
extends RefCounted

static var failures := 0
static var checks := 0


static func ok(cond: bool, label: String) -> bool:
	checks += 1
	if cond:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label)
	return cond


static func eq(actual, expected, label: String) -> bool:
	return ok(actual == expected, "%s (got %s, want %s)" % [label, str(actual), str(expected)])


static func near(actual: float, expected: float, label: String, tolerance: float = 0.6) -> bool:
	return ok(absf(actual - expected) <= tolerance, "%s (got %.2f, want %.2f)" % [label, actual, expected])


## Call when the test hit its frame limit without finishing.
static func timed_out(tree: SceneTree) -> void:
	ok(false, "test finished before its frame limit")
	done(tree)


static func done(tree: SceneTree) -> void:
	print("RESULT: %d checks, %d failed" % [checks, failures])
	tree.quit(1 if failures > 0 else 0)
