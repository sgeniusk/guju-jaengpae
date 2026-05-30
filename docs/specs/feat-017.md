# 스펙 — feat-017 영웅 조작 (hero command)

Claude(편집장)가 작성한 구현 스펙. Codex(구현자)가 이 문서·`AGENTS.md`·`CLAUDE.md`·`docs/design-loop.md`를 읽고 구현한다. 완료 후 `./init.sh` 전체 green.

## 목표
관전형 오토배틀 위에 미세 컨트롤 한 겹. 전투 중 **마우스 클릭/홀드로 영웅(장수)의 표적을 지정**한다. 자동 전투는 그대로 돌고, 플레이어는 영웅만 손으로 지휘한다.

## 메커닉 (v1)
- **조작 대상 = 장수(영웅)** — `card_type == "general"`인 아군 유닛만 조작 가능(`controllable`). 병종·성은 자동.
- **클릭/홀드** — 전투 중 적 근처를 누르면 그 적이 **모든 영웅의 지정 표적(commanded_target)**이 된다. 누르고 있으면(홀드) 커서 근처 적으로 표적이 갱신(스윕). 떼면 마지막 표적 유지(sticky).
- **자동 복귀** — 지정 표적이 죽거나, 빈 곳(적 없음)을 클릭하면 지정 해제 → 기존 자동(최근접) 타겟으로 복귀.
- **쿨다운 불변** — 클릭은 *표적만* 바꾼다. 공격은 영웅의 기존 `attack_interval` 쿨다운대로 발동(클릭으로 빨라지지 않음). 스킬도 기존 스킬 쿨다운대로.
- **표적 우선순위** — `commanded_target`(생존 시) > 도발(taunt) > 최근접. 플레이어 지휘가 자동보다 우선.

## 스코프 (이 파일들)
- `scripts/battle/battle_unit.gd` — `commanded_target: BattleUnit`(기본 null), `controllable: bool`(기본 false). `from_card`에서 `card.card_type == "general"`이면 controllable=true.
- `scripts/battle/battle_sim.gd` — `_nearest_enemy(u)` 우선순위에 `commanded_target` 반영(생존·적군 확인 후 반환, 죽었으면 무시하고 기존 로직). 순수·결정적 유지.
- `scripts/battle/battle.gd` — BATTLE 단계 마우스 입력(press/hold/release). 커서 화면좌표 → 필드좌표 변환 후 가장 가까운 적 유닛을 찾아, controllable 영웅 전원의 `commanded_target` 설정. 지정 표적 하이라이트(예 표시 링/색). 빈 곳·표적 사망 시 해제.
- `test/test_hero_command.gd` 신설.
- **유지(수정 금지)** — `scripts/run/*`, RunMap/RunManager, `resources/`·`.tres`, scenes/screens/*, RewardPool, TypeChart 규칙, SkillSystem 효과 규칙, WaveFactory.

## 불변식
- BattleSim 순수·결정적(EventBus·렌더 호출 금지). `commanded_target`는 battle.gd가 세팅, 시뮬은 읽기만.
- 오픈필드·성·스킬·상성·상태 규칙 유지. 지정 없으면 기존 동작과 동일.
- `./init.sh` run_map·battle 부팅 스모크 유지. battle.tscn standalone 안전.

## 테스트 지침 (test/test_hero_command.gd, 순수 로직)
- **지정 우선** — 영웅에 더 먼 적을 `commanded_target`으로 두면, 더 가까운 적이 있어도 지정 표적을 친다(step 후 지정 표적 hp 감소).
- **사망 복귀** — 지정 표적이 죽으면 다음 step부터 최근접 적을 친다.
- **병종 무시** — controllable=false 유닛은 commanded_target 세팅돼도 자동(최근접) 유지(또는 애초에 지정 안 됨).
- **from_card** — 장수 카드 → `controllable==true`, 병종 카드 → false.
- 기존 전투 테스트 회귀 없이 통과.

## 범위 밖 (후속)
- 영웅 개별 선택(한 명만 지휘) — v1은 전원 집중.
- 골드 경제+상점(feat-015), 건물(feat-016), 배치 역할 전/후열.

## 제약 (AGENTS.md)
- 비-자명한 새 파일 한 줄 한국어 헤더. 한국어 문장 `:` 종결 금지. GDScript 탭.
- `git commit`·`push` 금지. 회귀 금지. 네트워크 불필요.
- 끝나면 `./init.sh` 전체 green 증거로 "무엇이/왜/검증결과/남은모호함" 보고.

## 완료 기준 (Definition of Done)
- [ ] BattleUnit commanded_target/controllable + from_card 장수 판정.
- [ ] BattleSim 표적 우선순위(지정>도발>최근접), 사망 복귀.
- [ ] battle.gd 클릭/홀드 입력 → 영웅 지정·하이라이트, 빈 곳 해제.
- [ ] test_hero_command.gd 신설, 전체 단위 테스트 통과.
- [ ] `./init.sh` 전체 green(부팅 스모크 포함), 종료 0, 전투 외 시스템 미수정.
