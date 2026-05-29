# test 디렉토리의 내장 단위 테스트를 수집해 실행한다.
extends SceneTree

const TEST_DIR := "res://test"
const EXCLUDED := {
	"test_case.gd": true,
	"runner.gd": true,
}

func _initialize() -> void:
	var files := _test_files()
	var total_checks := 0
	var total_failures: Array[String] = []
	var file_count := 0

	for file_name in files:
		file_count += 1
		var path := "%s/%s" % [TEST_DIR, file_name]
		var script := load(path)
		if script == null:
			total_failures.append("[%s] 스크립트 로드 실패" % file_name)
			print("FAIL %s — 로드 실패" % file_name)
			continue
		var test = script.new()
		if not (test is TestCase):
			total_failures.append("[%s] TestCase가 아님" % file_name)
			print("FAIL %s — TestCase가 아님" % file_name)
			continue
		test.run_all()
		total_checks += test.checks
		for failure in test.failures:
			total_failures.append("%s %s" % [file_name, failure])
		var passed: int = test.checks - test.failures.size()
		if test.failures.is_empty():
			print("PASS %s — %d 단언" % [file_name, test.checks])
		else:
			print("FAIL %s — 통과 %d, 실패 %d" % [file_name, passed, test.failures.size()])

	var failed := total_failures.size()
	var passed_total := total_checks - failed
	for failure in total_failures:
		printerr("  ", failure)
	print("총 %d 단언, 통과 %d, 실패 %d" % [total_checks, passed_total, failed])

	if file_count == 0:
		printerr("  test_*.gd 파일을 찾지 못함")
		quit(1)
	else:
		quit(0 if failed == 0 else 1)

func _test_files() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		printerr("테스트 디렉토리 열기 실패: %s" % TEST_DIR)
		return out
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and _is_test_file(file_name):
			out.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out

func _is_test_file(file_name: String) -> bool:
	if EXCLUDED.has(file_name):
		return false
	return file_name.begins_with("test_") and file_name.ends_with(".gd")
