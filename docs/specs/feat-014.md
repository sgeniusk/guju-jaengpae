# 스펙 — feat-014 성(城) 방어 목표 (castle objective)

Claude(편집장)가 작성한 구현 스펙. Codex(구현자)가 이 문서·`AGENTS.md`·`CLAUDE.md`·`docs/design-loop.md`를 읽고 구현한다. 완료 후 `./init.sh` 전체 green.

## 목표
오픈필드(feat-013)에 **성(城)**을 더한다. 성은 맨 안쪽 고정칸의 방어 목표다. **승패 조건을 성 기준으로 바꾼다** — 적 군세 전멸=승, **성 파괴=패**(유닛 전멸 아님). 적은 군세만(비대칭 방어).

## 모델
- **성** — 플레이어 진영 맨 안쪽(기지 쪽) 고정 위치의 BattleUnit. 정적(move_speed 0), 공격 0, 높은 HP(예 1200). troop_type "infantry"(상성 중립 취급). display_name "성"(또는 군주국 테마). 카드가 아니라 전투 시작 시 자동 생성.
- **위치** — px = `CASTLE_X`(예 40, 플레이어 배치보다 더 안쪽), py = `FIELD_H/2`(중앙). 보드는 3×3 유닛 배치 + 성 1칸 = 10칸 개념.
- **적 표적** — 성은 플레이어 유닛이므로 적의 2D 최근접 표적에 포함된다. 적 유닛은 앞선 아군을 먼저 치고, 뚫리면 성을 친다.
- **승패** — `_update_result`에서 **성이 있으면**: 성 사망 → PLAYER_LOSE, 적 전멸(+대기 파도 없음) → PLAYER_WIN. (성이 없으면 기존 동작 유지 — 하위호환.)

## 스코프 (이 파일들)
- `scripts/battle/battle_sim.gd` — 성 보유(`var castle: BattleUnit`), `add_castle()` 또는 setup, 적 표적에 성 포함, `_update_result` 성 기준 승패.
- `scripts/battle/battle_unit.gd` — 성 식별(`is_castle: bool` 또는 별도 생성 헬퍼). 성은 이동·공격 안 함.
- `scripts/battle/battle.gd` — 전투 시작 시 성 자동 배치 + 성 시각화(맨 안쪽, HP바). 3×3 유닛 배치는 유지.
- `tools/sim_smoke.gd` — 승리/패배 시나리오에 성 반영(방어 생존=승, 성 노출 전멸=패).
- `test/test_castle.gd` 신설 + 영향 받는 전투 테스트 갱신.
- **유지(수정 금지)** — `scripts/run/*`, RunMap/RunManager, `resources/`·`.tres`, scenes/screens/*, RewardPool, TypeChart 규칙, SkillSystem 효과 규칙.

## 불변식
- BattleSim 순수·결정적(EventBus·렌더 금지, `last_skill_casts`만).
- 오픈필드 모델(양쪽 이동·2D 타겟)·스킬·상성·상태 규칙 유지.
- `./init.sh` run_map·battle 부팅 스모크 유지. battle.tscn standalone 안전.

## 테스트 지침 (test/test_castle.gd)
- 성 존재 — 전투 시작 시 sim.castle 생성, 정적(여러 step 후 위치 불변).
- **성 파괴=패** — 아군 유닛 없이 성만 있고 적 군세가 들어오면 성을 깨고 PLAYER_LOSE.
- **적 전멸=승** — 강한 아군이 적을 다 잡으면 성 생존으로 PLAYER_WIN.
- 유닛 전멸≠패 — 성이 살아있으면 비-성 아군이 다 죽어도 즉시 패배 아님(적이 성에 도달해 깰 때까지 ONGOING).
- 적 표적 — 다른 표적 없을 때 적이 성을 친다(성 hp 감소).
- 풀 덱 + 성 vs default 파도 → 막아내거나 성 파괴로 결판(ONGOING 정지 없음).

## 범위 밖 (후속)
- 골드 경제 + 상점, 첫 턴 2장 — feat-015.
- 건물 카드(궁전·오라) — feat-016.
- 성의 반격(타워 공격), 양쪽 성 대칭 — 후속 검토.

## 제약 (AGENTS.md)
- 비-자명한 새 파일 한 줄 한국어 헤더. 한국어 문장 `:` 종결 금지. GDScript 탭.
- `git commit`·`push` 금지. 회귀 금지. 네트워크 불필요.
- 끝나면 `./init.sh` 전체 green 증거로 "무엇이/왜/검증결과/남은모호함" 보고.

## 완료 기준 (Definition of Done)
- [ ] BattleSim 성 + 성 기준 승패(적 전멸=승, 성 파괴=패).
- [ ] battle.gd 성 자동 배치·시각화, 3×3 유닛 배치 유지.
- [ ] test_castle.gd 신설 + sim_smoke 성 반영, 전체 단위 테스트 통과.
- [ ] `./init.sh` 전체 green(부팅 스모크 포함), 종료 0, 전투 외 시스템 미수정.
