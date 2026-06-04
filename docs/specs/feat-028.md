# feat-028 — 유닛 애니메이션 (스프라이트 시트)

정적 Sprite2D 빌보드를 프레임 애니메이션으로. agy 스프라이트 시트(가로 4프레임 walk) → Godot AnimatedSprite2D/SpriteFrames. **결정성 전투 로직 불변(뷰 레이어만)**.

## 분업
agy(시트 생성)→Claude(키잉·수거)→Codex(엔진 배선)→Claude(검증). 이번 사이클은 시범 1종(촉 보병)으로 시스템을 구축하고, 나머지 유닛 시트는 잔여(점진).

## 설계 결정 (편집장)
- **시트 규약** — `<unit>_walk.png` = 가로 **4프레임 균등 스트립**(프레임폭 = 시트폭÷4), 마젠타 키아웃된 투명 PNG. 예 `shu/infantry_walk.png` 1024×512 → 256px×4프레임. (이미 생성·키잉 완료.)
- **렌더 분기** — battle.gd 유닛 시각화에서 텍스처 경로 옆 `_walk.png`가 있으면 **AnimatedSprite2D(SpriteFrames 4프레임)**, 없으면 현행 **Sprite2D(정적)**. 시트 없는 유닛은 무영향(정적 fallback).
- **재생** — 유닛이 이동 중일 때 walk 재생, 정지(교전·정렬) 시 정지(프레임 0). BattleSim의 위치 변화(px/py 델타)로 이동 판정 — 결정성 무관(순수 뷰).
- **시범 1종** — 촉 보병 `shu/infantry_walk.png`. 나머지 29종 × 애니는 잔여(agy 시트 점진 생성).

## 1. SpriteFrames 생성
- `shu/infantry_walk.png`(투명, 4프레임 256px) → SpriteFrames "walk" 애니, 4프레임 AtlasTexture region(x=0/256/512/768, 폭256·높이512). fps ~8, loop. 코드 생성(battle.gd 헬퍼) 권장(.tres보다 동적).

## 2. battle.gd 렌더 분기
- `_spawn_visual(u)` — `_unit_walk_sheet_path(u)`(텍스처 경로의 `.png`→`_walk.png`) 존재 + ResourceLoader.exists면 AnimatedSprite2D 생성(SpriteFrames "walk"), 아니면 현행 Sprite2D. **flip_h(적)·modulate·_fit_sprite_to_size·발밑 앵커 등 기존 Sprite2D 처리를 AnimatedSprite2D에도 동일 적용**(공통 헬퍼화 권장).
- `_sync_visuals`/위치 갱신에서 이동 판정(이전 위치 대비 델타 > 임계) → `play("walk")`, 정지 → `stop()`/`frame=0`.
- 스킬 플래시·데미지 연출(modulate 트윈)이 AnimatedSprite2D에도 작동하는지 확인.

## 3. 매니페스트
- `assets/MANIFEST.md`에 시트 규격 추가 — `_walk` 접미사, 가로 4프레임 균등, 마젠타 키잉, 프레임폭=시트폭÷4.

## 4. 검증 (Definition of Done)
- `./init.sh` 전체 green(부팅 무에러, AnimatedSprite2D 분기 파싱·런타임 OK). **결정성 전투 테스트 전부 불변**(914 단언 유지·증가).
- 시각 — 촉 전투에서 보병이 이동 중 walk 애니 재생(Claude 연속 스크린샷 또는 육안). 시트 없는 유닛은 정적 현행 유지.

## 금지 / 보존
- BattleSim·전투 로직·결정성 불변 — 애니메이션은 순수 뷰. last_damage_events/skill_casts 등 무관.
- 시트 없는 유닛(현재 29종)은 정적 Sprite2D 현행 그대로. feat-029/020/021 회귀 없음.
- 카드·스킬·trait·edict 로직 미수정.

## 잔여 (이번 사이클 밖)
- 촉·위·오 나머지 유닛 walk 시트(agy 생성) + idle/attack 애니. agy 할당량·시트 일관성 봐가며 점진. 시스템은 이번에 구축되므로 시트만 추가하면 자동 적용.
