# 리포 내장 단위 테스트의 공통 단언 베이스.
class_name TestCase
extends RefCounted

var failures: Array[String] = []
var _current: String = ""
var checks := 0

func before_each() -> void:
	pass

func run_all() -> void:
	var methods := get_method_list()
	methods.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["name"]) < String(b["name"]))
	for method in methods:
		var method_name := String(method["name"])
		if not method_name.begins_with("test_"):
			continue
		_current = method_name
		before_each()
		call(method_name)

func eq(actual, expected, msg := "") -> void:
	checks += 1
	if actual != expected:
		_add_failure(_message(msg, "expected <%s>, got <%s>" % [str(expected), str(actual)]))

func ne(a, b, msg := "") -> void:
	checks += 1
	if a == b:
		_add_failure(_message(msg, "expected values to differ, both were <%s>" % str(a)))

func truthy(cond, msg := "") -> void:
	checks += 1
	if not bool(cond):
		_add_failure(_message(msg, "expected true"))

func falsy(cond, msg := "") -> void:
	checks += 1
	if bool(cond):
		_add_failure(_message(msg, "expected false"))

func is_null(v, msg := "") -> void:
	checks += 1
	if v != null:
		_add_failure(_message(msg, "expected null, got <%s>" % str(v)))

func not_null(v, msg := "") -> void:
	checks += 1
	if v == null:
		_add_failure(_message(msg, "expected non-null"))

func almost(a: float, b: float, eps := 0.001, msg := "") -> void:
	checks += 1
	if absf(a - b) > eps:
		_add_failure(_message(msg, "expected <%f> ~= <%f> within <%f>" % [a, b, eps]))

func _add_failure(msg: String) -> void:
	failures.append("[%s] %s" % [_current, msg])

func _message(msg: String, fallback: String) -> String:
	return fallback if msg.is_empty() else "%s — %s" % [msg, fallback]
