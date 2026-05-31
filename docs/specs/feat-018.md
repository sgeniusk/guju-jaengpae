# 스펙 — feat-018 타겟 AI 시스템 (data-driven targeting rules)

Claude(편집장)가 작성한 구현 스펙. Codex(구현자)가 이 문서·`AGENTS.md`·`CLAUDE.md`·`docs/design-backlog.md`를 읽고 구현한다. 완료 후 `./init.sh` 전체 green.

## 목표
지금은 모든 유닛이 "최근접 적" 고정. 유닛마다 **타겟 규칙(target_rule)**을 데이터로 갖게 해, 병종이 전술적으로 달라지게 한다(궁병은 센 원거리 견제, 기병은 후열 다이브 등). "조건을 수용하는 시스템"의 토대.

## 규칙 집합 (v1)
| rule | 의미 |
|---|---|
| `nearest` | 2D 최근접(기본) |
| `backline` | 가장 먼 적(후열) |
| `strongest_ranged` | 가장 센(공격력 최대) 원거리 적, 없으면 nearest |
| `lowest_hp` | 현재 hp 최소(마무리) |
| `highest_hp` | max_hp 최대(탱커 견제) |
모든 규칙은 동률 시 **최근접으로 tie-break**(결정적).

## 우선순위 (BattleSim 표적 선택)
영웅 지정 > 도발 > **타겟 규칙**. 즉 `_pick_target(u)` — controllable이고 commanded_target 생존 시 그것, 아니면 taunt, 아니면 `TargetRules.pick(u.target_rule, u, foes)`. (foes = 살아있는 상대팀.)

## 스코프 (이 파일들)
- 신규 — `scripts/battle/target_rules.gd`(class_name TargetRules, 순수 static), `test/test_target_rules.gd`.
- 카드 스키마 — `scripts/resources/unit_card_data.gd`에 `@export_enum("nearest","backline","strongest_ranged","lowest_hp","highest_hp") var target_rule := "nearest"`. `scripts/resources/card_vocab.gd`에 `TARGET_RULES` 추가.
- 데이터 — `resources/cards/*.tres`에 target_rule 지정(아래 표). `tools/validate_cards.gd`에 target_rule 허용값 검증 추가.
- 전투 — `scripts/battle/battle_unit.gd`(target_rule 필드 + make/from_card 운반, 기본 "nearest"), `scripts/battle/battle_sim.gd`(_nearest_enemy → _pick_target, 규칙 적용), `scripts/battle/wave_factory.gd`(적 target_rule 지정).
- **유지(수정 금지)** — `scripts/run/*`, RunMap/RunManager, scenes/screens/*, RewardPool, TypeChart 규칙, SkillSystem 효과 규칙, battle.gd(타겟은 sim 측이라 UI 변경 불필요).

## 카드/적 규칙 지정 (기본값)
- 보병 nearest · 궁병 strongest_ranged · 기병 backline · 노병 highest_hp · 수군 nearest.
- 관우 nearest · 장비 nearest · 제갈량 backline · 조운 backline · 황충 strongest_ranged. (영웅은 조작으로 덮임.)
- 적 — 사령병/증원병 nearest · 요사 궁수 strongest_ranged · 마군 정예·호위 nearest · 마왕 동탁 highest_hp.

## 불변식
- BattleSim·TargetRules 순수·결정적(EventBus·렌더 금지). 규칙은 결정적 정렬.
- 영웅 지정·도발·오픈필드·성·스킬·상성·상태 규칙 유지.
- **밸런스 가드** — ./init.sh의 풀 덱 방어 승리 시나리오(sim_smoke·test_castle 풀덱)가 계속 승리해야 한다. 규칙으로 깨지면 수치·규칙 소폭 조정해 green 유지.
- `./init.sh` run_map·battle 부팅 스모크 유지.

## 테스트 지침 (test/test_target_rules.gd, 순수)
- 각 규칙 단독 — nearest=최근접, backline=최원거리, strongest_ranged=공격력 최대 원거리(원거리 없으면 nearest), lowest_hp=현재hp 최소, highest_hp=max_hp 최대.
- 동률 tie-break 결정적(최근접).
- BattleSim 통합 — backline 유닛은 가까운 적 두고 먼 적으로 이동·공격.
- from_card target_rule 운반(장수/병종 표대로), 미지정 기본 nearest.
- 우선순위 — commanded_target(영웅) > 규칙(test_hero_command와 정합).
- 기존 테스트 회귀 없이 통과.

## 범위 밖 (후속)
- 더 많은 규칙(weakest·flank·protect-ally), 조건 조합 — 데이터로 확장.
- 골드 경제(feat-015)·건물(feat-016)·배치 역할.

## 제약 (AGENTS.md)
- 비-자명한 새 파일 한 줄 한국어 헤더. 한국어 문장 `:` 종결 금지. GDScript 탭.
- `git commit`·`push` 금지. 회귀 금지(밸런스 가드). 네트워크 불필요.
- 끝나면 `./init.sh` 전체 green 증거로 "무엇이/왜/검증결과/남은모호함" 보고.

## 완료 기준 (Definition of Done)
- [ ] TargetRules(5규칙, 결정적) + BattleSim _pick_target(영웅>도발>규칙).
- [ ] UnitCardData.target_rule + CardVocab + .tres 지정 + validate_cards 검증.
- [ ] BattleUnit/wave_factory target_rule 운반.
- [ ] test_target_rules.gd 신설, 전체 단위 테스트 통과(회귀 0).
- [ ] `./init.sh` 전체 green(부팅 스모크·풀덱 승리 유지), 종료 0, 금지 영역 미수정.
