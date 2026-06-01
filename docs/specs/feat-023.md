# feat-023 — 전투 HUD 오버홀

## 목표
첨부 레퍼런스의 HUD를 재현한다 — 하단 3중 진행바, 상단 스테이지 사다리, 좌상 자원 카운터, 우상 속도 컨트롤, 좌측 능력 버튼 4개. feat-022가 만든 `HUD(CanvasLayer)` 컨테이너를 채운다.

## 전제
- feat-022 완료(HUD 컨테이너·DeployPanel 존재). `BattleSim` 불변. 정본 [docs/render-architecture.md](../render-architecture.md) HUD 절.

## 범위 (파일)
- `scripts/battle/battle.gd` — HUD 위젯 구축·갱신.
- (신규 가능) `scripts/battle/hud_*.gd` 또는 `scenes/battle/hud.tscn` — HUD 분리하면 가독성↑(선택).
- `scripts/run/stage_cadence.gd` — 사다리용 조회 헬퍼 **추가만**(기존 로직 불변), 예 `static func node_kind(stage) -> String`(combat/shop/boss/expand).

## 구현
1. **3중 진행바 (하단)** — 첨부의 `무의 왕 / 무의 챔피언 / 무의 반란` 대응.
   - ① 아군 성 HP — `sim.castle.hp_ratio()`. 라벨 "성".
   - ② 보스/챔피언 HP — 적에 보스 유닛(최대 HP 최상위, 또는 boss 플래그) 있으면 그 HP, 없으면 바 흐리게/숨김.
   - ③ 적 군세 잔존 — `enemy_units.size()` / 그 파도 최대(또는 파도 진행 `wave_index/wave_total`).
   - 매 프레임 `_sync_visuals`에서 갱신.
2. **스테이지 사다리 (상단중앙)** — `StageCadence`로 현재~+6 스테이지 노드. 아이콘 = 전투/상점(`is_shop`)/보스(`is_boss`, 왕관)/확장(`is_expand`). 현재 위치 하이라이트. "N년" 플레이버 — 시작 기준년 + stage_index(예 33년부터). 매니페스트 `ui/node_*.png`, 없으면 도형/글자 폴백.
3. **자원 카운터 (좌상)** — 골드 `RunManager.get_gold()` + `ui/icon_gold.png`(없으면 ◆ 글자). 골드 변동 시 갱신.
4. **속도 컨트롤 (우상)** — pause 토글 + 배속 버튼 ×1/×2/×3. `var _speed := 1.0`·`var _paused := false`. `_process`에서 `if _paused: return` + `_sim.step(delta * _speed)`. "auto"는 토글 라벨(최소; 동작은 후속). 아이콘 `ui/spd_*.png` 폴백 글자.
5. **능력 버튼 (좌세로 4개)** — 원형 버튼.
   - 우물 — 현 `_on_well_pressed` 래핑(선택 카드 있을 때 활성).
   - 집중표적 토글 — 현 마우스 홀드 영웅명령을 토글 모드로(켜면 클릭 표적 지정). 현 로직 보존.
   - 예약 2개 — 비활성 슬롯(아이콘 흐리게).
   - 아이콘 `ui/ability_*.png` 폴백.
6. **테마** — HUD 기본 룩을 GDScript Theme/StyleBox로(양피지·먹·금). 애셋 의존 최소.

## 검증
- `./init.sh` green. 사다리·속도 로직 단위 테스트(`test_hud_*` 또는 `test_stage_cadence` 확장) — 예 배속 적용·노드 종류 분류·3중바 비율 계산.
- 헤드리스 부팅 무에러. 위젯이 데이터에 반응(골드·성HP·파도·스테이지).

## 스코프 밖
- 실제 UI 아이콘 아트 = feat-025(폴백으로 동작). 상점 실거래 = feat-015d. 데미지 숫자 = feat-024.
