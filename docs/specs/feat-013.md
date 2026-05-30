# 스펙 — feat-013 오픈필드 난전 (open-field 2D combat)

Claude(편집장)가 작성한 구현 스펙. Codex(구현자)가 이 문서·`AGENTS.md`·`CLAUDE.md`·`docs/worldview.md`를 읽고 구현한다. 완료 후 `./init.sh` 전체 green.

## 배경 — Nine Kings 실측 반영
사용자 제공 스샷으로 NK 전투를 확인했다 — 3×3 보드에 배치한 군세가 **열린 들판으로 나와 양쪽이 만나 자동 난전**한다(컬럼 레인 아님). feat-012의 정적 컬럼 방어를 **2D 오픈필드 난전**으로 교체한다. 프레이밍은 군주 대 군주(다음 피처에서 King HP), 이번 피처는 **공간/전투 모델**에 집중한다. 메타·카드·스킬·상성·상태 효과는 재사용. (롤백 — 레인 5b61aa1, 컬럼 de1ff68.)

## 모델 (정확히 이렇게)
- **필드** — 2D. x ∈ [0, `FIELD_W`=1000](아군 기지 0 쪽 ↔ 적 기지 1000 쪽), y ∈ [0, `FIELD_H`=600](측면). 유닛 위치 = (x, y).
- **배치(3×3)는 시작 진형** — 아군 타일 (col, row) → 시작 (x, y). 예 — 전열 `x` = `ROW_X = [360, 240, 120]`(row 0=전방=적과 가까움), 측면 `y` = `COL_Y = [150, 300, 450]`. 적은 x=`FIELD_W`, y는 측면에 분산(컬럼별 COL_Y 등)에서 등장.
- **양쪽 다 이동** — 정적 아님. 매 step 각 유닛은 **2D 거리상 최근접 살아있는 적**을 표적으로, 사거리 밖이면 그 방향으로 이동(move_speed·delta), 사거리 안이면 공격. 양 군세가 가운데서 수렴해 난전.
- **타겟팅은 컬럼 무관** — 2D 최근접(어느 방향이든). 근접=짧은 사거리, 원거리=넓은 반경(옆줄 커버). `_frontmost_player_in_column`·동일 컬럼 필터 제거.
- **승패** — 적 군세 전멸(+대기 파도 없음) = PLAYER_WIN. 아군 군세 전멸 = PLAYER_LOSE. (열린 난전이라 "기지 도달" 대신 전멸로 판정. King HP는 feat-014.)

## 좌표 재해석 (BattleUnit)
- 기존 `lane`/`row`/`x`를 보존하되 **2D 위치 추가** — `var px: float`, `var py: float`(또는 `pos: Vector2`). `x`는 호환 위해 남겨도 되나 전투는 (px, py)로 한다.
- `make`/`from_card`에 시작 px·py 전달 경로 추가(또는 add_unit 시 배치 좌표 설정). 아군 배치는 (col,row)→(px,py) 매핑, 적은 wave_factory가 지정.

## 스코프 (이 파일들)
- `scripts/battle/battle_sim.gd` — 2D 오픈필드. 양쪽 이동·2D 최근접 타겟·사거리 교전·전멸 승패. 스킬/상태/상성 호출 유지(타겟 질의만 2D로).
- `scripts/battle/battle_unit.gd` — 2D 위치 필드 + 생성 경로.
- `scripts/battle/wave_factory.gd` — 적 군세를 적 진영(x=FIELD_W, y 분산)에 생성.
- `scripts/battle/skill_system.gd` — 타겟 질의를 2D로(동일 컬럼 → 2D 반경/최근접). 일섬=2D 최근접 2기, 백보천양=2D 최원거리 적, 팔진도=대상 반경 내 모든 적, 호통=반경 내 적 도발·약화, 단기필마=전방 2D 경로 피해.
- `scripts/battle/battle.gd` — 3×3 배치 UI 유지(시작 진형) + **2D 필드 시각화**(유닛이 들판에서 이동·수렴하는 모습). 사용자 클릭 배치 → (col,row) 시작 좌표.
- 테스트 — `test_battle_sim`·`test_grid`·`test_multiwave`·`test_skills`·`test_status`·`test_type_chart`를 2D 오픈필드 가정으로 갱신. `test/test_openfield.gd` 신설(양쪽 수렴·2D 타겟·전멸 승패).
- **유지(수정 금지)** — `scripts/run/*`, `RunMap`, `RunManager`, `resources/`·`.tres`, `TypeChart` 규칙, `RewardPool`, `scenes/screens/*`.

## 불변식 (회귀 가드)
- BattleSim 순수·결정적(EventBus·렌더 금지, `last_skill_casts`만 노출).
- 스킬 5종·상성 삼각·상태(도발/약화) 효과 규칙 유지(공간만 2D).
- `./init.sh` run_map·battle 부팅 스모크 유지. battle.tscn standalone 부팅 안전.

## 테스트 지침
- 마주 본 2유닛 → 둘 다 전진·수렴, 사거리서 교전, 한쪽 사망.
- 강한 아군 군세 vs 약한 적 군세 → 적 전멸 PLAYER_WIN. 반대 → PLAYER_LOSE.
- 원거리 유닛 — 2D 반경 내 적을 옆줄이어도 타격(컬럼 무관).
- 풀 덱(3×3 분산 배치) vs default 파도 → 결과가 ONGOING로 안 멈추고 판정.
- 스킬/상성/상태 — 2D 공간에서 기존 효과 규칙 유지 검증.

## 제약 (AGENTS.md)
- 비-자명한 새 파일 한 줄 한국어 헤더. 한국어 문장 `:` 종결 금지. GDScript 탭.
- `git commit`·`push` 금지. 회귀 금지. 네트워크 불필요.
- 끝나면 `./init.sh` 전체 green 증거로 "무엇이/왜/검증결과/남은모호함" 보고.

## 범위 밖 (후속)
- **King HP / 군주 대 군주 판정** — 양쪽 군주 유닛 + HP바, 적 왕 격파 승리 — feat-014.
- **건물 카드** — 궁전·소환·오라 — feat-015.
- **iso 다이아몬드 렌더링** — 비주얼 폴리시.

## 완료 기준 (Definition of Done)
- [ ] BattleSim 2D 오픈필드 — 양쪽 이동·2D 최근접 타겟·전멸 승패.
- [ ] 배치(3×3)가 시작 진형, battle.gd 2D 필드 시각화.
- [ ] 스킬·상성·상태가 2D에서 동작(테스트 갱신).
- [ ] test_openfield.gd 신설, 전체 단위 테스트 통과.
- [ ] `./init.sh` 전체 green(부팅 스모크 포함), 종료 0, 전투 외 시스템 미수정.
