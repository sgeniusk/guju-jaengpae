# 분대/호위 렌더링에 필요한 배치 좌표를 계산하는 순수 helper.
class_name FormationRenderer
extends RefCounted

static func member_offsets(count: int, columns: int, dx: float, dy: float) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	var safe_count := maxi(0, count)
	if safe_count <= 0:
		return offsets
	var safe_columns := maxi(1, columns)
	var rows := int(ceilf(float(safe_count) / float(safe_columns)))
	for i in safe_count:
		var row := int(i / safe_columns)
		var col := i % safe_columns
		var row_count := mini(safe_columns, safe_count - row * safe_columns)
		var x := (float(col) - (float(row_count) - 1.0) * 0.5) * dx
		var y := (float(row) - (float(rows) - 1.0) * 0.5) * dy
		var jitter := Vector2(float((i * 17) % 5 - 2) * 1.2, float((i * 11) % 3 - 1) * 1.0)
		offsets.append(Vector2(x, y) + jitter)
	return offsets

static func troop_offsets(squad_count: int) -> Array[Vector2]:
	return member_offsets(mini(maxi(1, squad_count), 18), 6, 27.0, 16.0)

static func retinue_offsets(retinue_count: int) -> Array[Vector2]:
	var base := member_offsets(mini(maxi(0, retinue_count), 10), 5, 30.0, 17.0)
	var out: Array[Vector2] = []
	for offset in base:
		out.append(offset + Vector2(0.0, 20.0))
	return out

static func sort_key(offset: Vector2, index: int) -> int:
	return int(round(offset.y * 10.0)) + index
