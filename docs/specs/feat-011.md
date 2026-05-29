# 스펙 — feat-011 상태이상: 도발·약화 (status effects)

Claude(편집장)가 작성한 구현 스펙. Codex(구현자)가 이 문서와 `AGENTS.md`·`CLAUDE.md`·`docs/worldview.md`를 읽고 구현한다. **feat-010 완료·커밋 후 착수**(같은 코어 파일, 순차). 완료 후 `./init.sh` 전체 green. v0.3 세 번째(마지막) 전투 깊이 피처.

## 목표
상태이상 프레임워크를 깔고 **도발(TAUNT)·약화(WEAKEN)** 두 종을 구현한다. 이로써 feat-009에서 placeholder(피해+자가회복)였던 **장비 호통을 진짜 도발+약화**로 교체한다. (지속피해 DOT·둔화 SLOW는 후속 feat-012로 분리.)

## 상태 모델
- TAUNT(도발) — 대상이 정해진 시전자(source)를 강제로 타겟. source가 죽거나 다른 레인이면 무효, 지속 만료 시 해제.
- WEAKEN(약화) — 대상 공격력 감소(배수). 만료 시 복구.

## 스코프 (이 파일들)
- 수정 — `scripts/battle/battle_unit.gd`(statuses 보유 + 헬퍼), `scripts/battle/battle_sim.gd`(상태 틱·도발 타겟·유효 공격력 적용), `scripts/battle/skill_system.gd`(장비 호통을 도발+약화로 교체), `test/test_skills.gd`(호통 테스트를 새 동작으로 갱신).
- 신규 — `test/test_status.gd`.
- **위 외(resources/·.tres·wave_factory·run_*·screens·battle.gd·type_chart) 수정 금지.** 기존 테스트 회귀 금지(단, 호통 테스트는 명시적으로 갱신).

## BattleUnit
- 필드 — `var statuses: Array = []`. 각 원소 `{ "type": String, "remaining": float, "magnitude": float, "source": BattleUnit }`(source는 taunt에만 의미, 없으면 null).
- `add_status(type: String, duration: float, magnitude: float, source: BattleUnit = null)` — 같은 type 있으면 더 긴 remaining으로 갱신(중첩 대신 리프레시).
- `tick_statuses(delta)` — 모든 status `remaining -= delta`, 0 이하 제거.
- `has_status(type) -> bool`, `get_status(type) -> Dictionary`(없으면 빈 `{}`).
- `effective_attack() -> int` — WEAKEN 합산 배수 적용 `max(0, int(round(attack * (1.0 - clampf(weaken_mag, 0.0, 0.9)))))`. WEAKEN 없으면 attack.
- `taunt_source() -> BattleUnit` — 활성 TAUNT의 source 반환(없으면 null). 만료/무효 판단은 BattleSim에서.

## BattleSim
- `step(delta)` — 각 살아있는 유닛에 대해 먼저 `u.tick_statuses(delta)`.
- **타겟팅** — `_nearest_enemy(u)` 보정: u가 활성 TAUNT를 갖고 그 source가 살아있고 같은 레인이면 source 반환, 아니면 기존 최근접. (도발은 적이 장비를 강제 타겟하게 함.)
- **유효 공격력** — 일반 공격 피해는 `u.effective_attack()` 사용(feat-010 TypeChart 배수와 곱). 즉 `dmg = int(round(u.effective_attack() * TypeChart.multiplier(u.troop_type, target.troop_type)))`.
- 결정적·순수 유지(EventBus·렌더 금지).

## SkillSystem — 장비 호통 교체
- `skill_changban_roar`(쿨다운 6.0 유지) 효과를 다음으로 교체
    - 같은 레인 모든 적에 25 피해(유지).
    - 같은 레인 모든 적에 `add_status("taunt", 2.5, 0.0, 장비)` + `add_status("weaken", 2.5, 0.3, 장비)`.
    - **자가 회복 제거**(placeholder였음).
- 나머지 4스킬 불변.

## 테스트
### test/test_status.gd (신규)
- `add_status`/`has_status`/`get_status` + `tick_statuses` 만료(2.5s 지나면 해제).
- `effective_attack` — attack 100 + weaken 0.3 → 70, weaken 없으면 100, 과도 weaken은 0.9 cap.
- 도발 타겟 — 적 E에 `add_status("taunt", source=장비A)` 후, 더 가까운 아군 B가 있어도 E가 A를 친다(step 후 A.hp 감소, B.hp 불변으로 검증).
- 도발 무효 — source 죽으면 일반 타겟으로 복귀.
### test/test_skills.gd (갱신)
- 장비 호통 테스트를 새 동작으로 — 적 25 피해 + 적이 taunt·weaken 보유, 장비 hp는 회복되지 않음(변화 없음).

## 제약 (AGENTS.md)
- 비-자명한 새 파일 한 줄 한국어 헤더. 한국어 문장 `:` 종결 금지. GDScript 탭 들여쓰기.
- `git commit`·`push` 금지. 회귀 금지(호통 외). 네트워크 불필요.
- 끝나면 `./init.sh` 전체 green 증거로 "무엇이/왜/검증결과/남은모호함" 보고.

## 완료 기준 (Definition of Done)
- [ ] BattleUnit 상태 프레임워크 + effective_attack + taunt 질의.
- [ ] BattleSim 상태 틱·도발 타겟·유효 공격력 적용.
- [ ] 장비 호통 = 피해+도발+약화(자가회복 제거), 나머지 스킬 불변.
- [ ] test_status.gd 신규 + test_skills.gd 호통 갱신, 전체 단위 테스트 통과.
- [ ] `./init.sh` 전체 green, 부팅 스모크 유지, 종료 0, 스코프 외 미수정.
