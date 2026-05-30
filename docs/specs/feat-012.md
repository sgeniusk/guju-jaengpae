# 스펙 — feat-012 그리드 전장 전환 (Nine Kings 정합)

Claude(편집장)가 작성한 구현 스펙. Codex(구현자)가 이 문서와 `AGENTS.md`·`CLAUDE.md`·`docs/worldview.md`를 읽고 구현한다. 완료 후 `./init.sh` 전체 green.

## 배경 — 방향 전환
지금 전투는 레인 tug-of-war(양쪽이 행군해 충돌)다. 벤치마크 **Nine Kings**는 **그리드 타일에 유닛/건물을 배치해 파도를 막는 진형 방어**다. 이 피처가 전장 모델을 그리드로 바꾼다. 메타·카드·스킬·상성·상태 등 전투 외 시스템은 전부 재사용한다. (롤백 체크포인트 — 레인 모델 마지막 커밋 `5b61aa1`.)

## 그리드 모델 v1 (NK 실측·플레이 후 정련 가능)
- **보드** — `COLS=3`(전선 컬럼) × `ROWS=3`(전열 깊이; row 0 = 전방=적과 가까움, row 2 = 후방=기지 쪽). 타일 = (col, row). 타일당 유닛 1기(스택 없음).
- **플레이어** — 유닛을 타일에 배치, **고정(행군 안 함, 진형 방어)**. row가 전선 깊이를 정한다.
- **적** — 각 컬럼 far end에서 파도로 등장해 기지 방향으로 **전진**.
- **교전** — 유닛은 같은 컬럼 사거리 내 최근접 적 공격(근접=인접 깊이, 원거리=더 멀리). 적은 같은 컬럼 최전방 유닛을 공격, 그 컬럼 유닛을 다 지나치면 기지 도달.
- **승** — 모든 파도 격파. **패** — 적이 기지(전열 끝) 도달(돌파). 빈 컬럼은 그대로 뚫린다 → 배치 퍼즐의 핵심.

## 좌표 재해석 (최소 변경)
기존 `lane`/`x`를 재사용해 churn을 줄인다.
- `col` = 기존 `lane`(0..2). `row` 필드 신설(0..2). `depth` = 기존 `x`(컬럼 내 위치, 0 = 기지, `LANE_LENGTH` = 적 진입점).
- 플레이어 유닛 — row→depth 매핑으로 고정. 예 `row 0 → depth 360, row 1 → 240, row 2 → 120`(상수로). `_advance` 호출 안 함(static).
- 적 — depth = `LANE_LENGTH`에서 등장, 매 step 전진(depth 감소). 기존 `_advance`(적 방향) 유지.

## 스코프 (이 파일들)
- `scripts/battle/battle_sim.gd` — 그리드 모델. 플레이어 static·적 전진·컬럼 교전·돌파 패배·파도 승리. 스킬/상태/상성 호출 유지하되 타겟팅은 **같은 컬럼** 기준(기존 same-lane 로직이 곧 same-column이라 거의 그대로).
- `scripts/battle/battle_unit.gd` — `row` 필드 + make/from_card 정합. (lane을 col 의미로 계속 써도 됨.)
- `scripts/battle/wave_factory.gd` — 적을 컬럼별 depth=LANE_LENGTH에서 생성(기존 lane→col 유지). 파도 수치 유지.
- `scripts/battle/skill_system.gd` — 타겟 질의 same-lane → same-column(명칭만, 로직 동일). 효과 수치 유지.
- `scripts/battle/battle.gd` — **3×3 그리드 배치 UI**(타일 클릭 → 선택 카드 배치, col=컬럼·row=깊이) + 적 컬럼 전진 시각화. 기존 레인 버튼·스택 오프셋 대체. 지휘력·보상·맵 복귀 흐름은 유지.
- 테스트 — `test_battle_sim`·`test_multiwave`·`test_skills`·`test_status`·`test_type_chart`를 그리드 가정(플레이어 static·적 전진)으로 갱신. 그리드 배치·돌파·빈 컬럼 패배를 덮는 `test/test_grid.gd` 신설 권장.
- **유지(수정 금지)** — `scripts/run/*`, `RunMap`, `RunManager`(노드/맵), `resources/`·`.tres`, `TypeChart` 규칙, `RewardPool`, `scenes/screens/*`. 전투 외 시스템 불변.

## 불변식 (회귀 가드)
- BattleSim 순수·결정적 유지(EventBus·렌더 호출 금지, `last_skill_casts`만 노출).
- 스킬 5종·상성 삼각·상태(도발/약화) 효과 규칙은 그대로(타겟 공간만 컬럼 기준).
- `./init.sh` run_map·battle 부팅 스모크 유지(battle.tscn은 노드 없이 standalone 부팅 안전).

## 테스트 지침
- 플레이어 유닛은 고정 — step 여러 번 후 player.depth 불변 확인.
- 적은 전진 — step 후 enemy.depth 감소.
- 빈 컬럼 — 그 컬럼에 아군 없으면 적이 기지 도달 → PLAYER_LOSE.
- 막힌 컬럼 — 강한 아군 배치 시 적 전멸·돌파 없음 → 파도 클리어.
- 스킬/상성/상태 — 기존 테스트의 공간 설정을 그리드로 바꿔 동일 효과 검증(데미지·도발·약화·상성 배수).
- 풀 덱 vs default 파도 → 적절히 막아냄(밸런스 임시 허용, 결과가 ONGOING로 멈추지 않을 것).

## 제약 (AGENTS.md)
- 비-자명한 새 파일 한 줄 한국어 헤더. 한국어 문장 `:` 종결 금지. GDScript 탭.
- `git commit`·`push` 금지. 네트워크 불필요.
- 끝나면 `./init.sh` 전체 green 증거로 "무엇이/왜/검증결과/남은모호함" 보고.

## 범위 밖 (후속)
- **건물(building) 카드** — NK의 핵심 요소. `card_type "building"` + 효과(오라/소환)는 feat-013.
- 유닛이 전열을 밀고 전진하는 능동 모델, 컬럼 간 광역 스킬 — 플레이 후 검토.

## 완료 기준 (Definition of Done)
- [ ] BattleSim 그리드 — 플레이어 static·적 전진·컬럼 교전·돌파 패배·파도 승리.
- [ ] battle.gd 3×3 타일 배치 UI + 적 전진 시각화.
- [ ] 스킬·상성·상태가 그리드에서 동작(테스트 갱신).
- [ ] test_grid.gd 신설, 전체 단위 테스트 통과.
- [ ] `./init.sh` 전체 green(부팅 스모크 포함), 종료 0, 전투 외 시스템 미수정.
