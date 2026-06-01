# feat-022 — 아이소 전장 렌더 리팩토링

## 목표
전투 화면을 Control-only 골격에서 **Node2D 월드 + CanvasLayer HUD**로 재구성한다. 유닛을 `ColorRect`에서 `Sprite2D` 빌보드로 바꾸고, 단일 투영 + py 깊이 정렬 + 좌측 아이소 다이아몬드 기지를 도입한다. 정본 [docs/render-architecture.md](../render-architecture.md)를 그대로 따른다.

## 절대 불변식
- **`scripts/battle/battle_sim.gd`·`battle_unit.gd`·기존 전투 로직 수정 금지.** 뷰만 바꾼다.
- 기존 전투 테스트(`test_*`) 회귀 0. `./init.sh` 단언 수 유지(현 618) 이상.
- 애셋이 없어도(현 상태) 부팅·테스트 통과 — 텍스처 로드 실패 시 **placeholder 폴백**(단색/ modulate).

## 범위 (파일)
- `scenes/battle/battle.tscn` — 노드 트리 재구성.
- `scripts/battle/battle.gd` — 대규모 재구성. 단, _ready/_process/_input 골격과 phase(DEPLOY/BATTLE/DONE)·배치·우물·영웅명령·보상 로직은 **기능 보존**하며 새 트리로 이식.

## 구현
1. **단일 투영** — `field_to_screen(px, py) -> Vector2`. `VIEW_ORIGIN`·`VIEW_SCALE_X`·`VIEW_SCALE_Y` 상수로 1920×1080 채움(세로 압축 원근). 유닛·타일·건물·성·VFX 전부 이 함수 사용. 현 `_map_px/_map_py`·`_tile_position` 대체.
2. **노드 트리** (render-architecture.md 트리 그대로)
   - `WorldRoot(Node2D)` + `Camera2D`(전장 프레이밍).
   - `BackgroundLayer` — 지금은 그라데이션/단색 placeholder(실제 테마는 feat-025). 테마 텍스처를 받을 수 있는 구조.
   - `IsoBaseLayer` — 3×3 보드 타일을 아이소 다이아몬드로(타일 중심 = `field_to_screen(position_for_tile)`, 반폭64·반높32). 배치 단계 클릭 가능(현 타일 버튼 로직 이식). 성은 px=40 위치.
   - `UnitsLayer(y_sort_enabled=true)` — 유닛 스프라이트. `position.y`를 py에 연동해 깊이 정렬.
   - `VfxLayer` — 비움(feat-024가 채움).
   - `HUD(CanvasLayer)` — 컨테이너 노드만 배치(TopLeft/TopCenter/TopRight/LeftBar/BottomBars/DeployPanel). 위젯 내용은 feat-023. **단 DeployPanel엔 현 `_build_panel` 손패·보드·결과 UI를 이식**해 배치·전투·보상이 지금처럼 돌게 한다.
3. **유닛 렌더** — `_spawn_visual`을 Sprite2D 기반으로. 텍스처 경로 = 매니페스트(`assets/sprites/units/<faction>/<troop>.png`). faction = 아군 shu / 적 demon. 보스(이름 "마왕 동탁")는 대형. 적은 `flip_h`. **`ResourceLoader.exists()` 가드 후 없으면 placeholder**(현 색 규칙 유지). HP바·표적 마커 유지.
4. **카메라** — 전장 전체가 보이게 줌/위치. 픽셀 스냅(`texture_filter` nearest).

## 검증
- `./init.sh` green(≥618 단언). 메인 씬·battle 씬 헤드리스 부팅 무에러.
- 배치→전투 시작→유닛 진군→승/패→보상→다음 스테이지 흐름 보존.
- 유닛이 스프라이트(또는 placeholder)로 그려지고 py로 앞뒤 정렬. 좌측 아이소 기지·성 보임.

## 스코프 밖 (후속 피처)
- 실제 픽셀 애셋·배경 테마 = feat-025. HUD 위젯(3중바·사다리·속도·능력) = feat-023. 데미지 숫자·타격감 = feat-024. 건물 = feat-016.
