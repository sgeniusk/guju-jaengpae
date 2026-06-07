# feat-086 — 배치 ghost와 분대 개별 동세

사용자가 지적한 두 감각 문제를 좁게 고친다. 배치할 때 유닛이 보이지 않아 놓는 맛이 약하고, 전투 중 분대가 한 덩어리처럼 움직여 긴장감이 낮다.

## 목표
- 손패에서 유닛 카드를 선택하고 빈 타일에 hover하면, 해당 타일 위에 반투명 분대/장수 미리보기를 표시한다.
- 전투 시뮬레이션은 한 카드 = 한 BattleUnit 집계 모델을 유지한다.
- 화면에서는 분대 구성원마다 약간 다른 보폭, 흔들림, 공격 후 lunge를 적용해 개별 병사처럼 읽히게 한다.

## 구현
- `scripts/battle/battle.gd`
  - `DeployPreviewLayer`를 추가해 보드/건물과 실제 유닛 사이에 배치 ghost를 그린다.
  - `_deploy_preview_key()`는 성 선택 완료, 이번 교전 카드 미사용, 선택 카드가 `UnitCardData`, hover 타일이 빈 보드 칸인 경우에만 ghost를 허용한다.
  - ghost는 실제 배치와 같은 `CardCatalog.build_board_army()`와 `_create_unit_body()` 경로를 사용하지만 RunState와 BattleSim에는 추가하지 않는다.
  - formation member마다 `formation_home`, `formation_phase`, `formation_index` 메타를 저장하고 `_sync_formation_member_motion()`에서 local motion만 갱신한다.

## 검증
- 단위 테스트가 배치 hover ghost 생성, ghost 접지, ghost clear를 검증한다.
- 단위 테스트가 formation member metadata와 개별 motion 변화를 검증한다.
- UI smoke가 실제 배치 흐름에서 hover ghost를 확인한다.
- `./init.sh` green으로 닫는다.

## 비범위
- 병사 개별 HP/타겟/충돌을 만들지는 않는다.
- 드래그 앤 드롭 입력은 후속 UX 작업으로 둔다.
