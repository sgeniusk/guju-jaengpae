extends TestCase

const FormationRenderer := preload("res://scripts/battle/formation_renderer.gd")

func test_troop_offsets_are_centered_and_capped_for_readable_density() -> void:
	var offsets := FormationRenderer.troop_offsets(26)
	eq(offsets.size(), 18, "성장 분대는 18명까지 보이게 압축")
	var min_x := 9999.0
	var max_x := -9999.0
	for offset in offsets:
		min_x = minf(min_x, offset.x)
		max_x = maxf(max_x, offset.x)
	truthy(min_x < 0.0 and max_x > 0.0, "좌우로 펼쳐진 포메이션")

func test_retinue_offsets_sit_below_general_anchor() -> void:
	var offsets := FormationRenderer.retinue_offsets(5)
	eq(offsets.size(), 5, "호위병 5명")
	var below_count := 0
	for offset in offsets:
		if offset.y > 0.0:
			below_count += 1
	truthy(below_count >= 3, "대부분 장수 아래쪽에 서서 접지감 제공")

func test_retinue_offsets_cap_at_ten_guards() -> void:
	var offsets := FormationRenderer.retinue_offsets(13)
	eq(offsets.size(), 10, "장수 호위는 10명까지 렌더")

func test_sort_key_follows_y_depth_then_index() -> void:
	var back := FormationRenderer.sort_key(Vector2(0, -10), 0)
	var front := FormationRenderer.sort_key(Vector2(0, 10), 0)
	truthy(front > back, "아래쪽 멤버가 더 앞에 그려질 수 있음")
