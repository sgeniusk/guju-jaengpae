# 세션 핸드오프 — Codex 이관용

이 문서는 **Codex CLI가 다음 세션을 이어받기 위한 진입점**이다. 에이전트-중립 규칙은 [AGENTS.md](AGENTS.md), 세계관 정본은 [docs/worldview.md](docs/worldview.md), 구조 이력은 [CHANGELOG.md](CHANGELOG.md).

## 현재 상태 (2026-06-04) — v0.6 완료, 클린
- `./init.sh` **935 단언 green**. working tree 깨끗(`.import` 부산물 외). **모든 feature_list 피처 done**(not-started 0).
- **v0.6 done** — feat-029(위·오 trait·스킬)·feat-020(땅 확장)·feat-021(왕의 칙령)·feat-028(유닛 애니). 각 architect(opus) APPROVED + deslop + 회귀 검증.
- **feat-027 done**(이전) — 촉·위·오 30종 agy 보정 + 렌더 스케일업.

## ⏳ 가장 먼저 — 미푸시 커밋 push (사용자 확인 후)
```
git log --oneline origin/main..main   # 미푸시 전체 확인
git push origin main
```
v0.6 피처 커밋 + handoff 갱신 docs가 미푸시 상태:
- `ca6b816` feat-029 위·오 진영 깊이
- `93de775` feat-020 땅 확장
- `449a2bf` feat-021 왕의 칙령
- `e7d7a6a` feat-028 유닛 애니메이션
- (+ 이 handoff 갱신 docs 커밋 1개)

feat-027 세션 커밋은 이미 push됨. 정확한 미푸시 수는 `git log origin/main..main`로 확인.

## 분업 (Codex 이관 후)
- **이전 분업** — Claude(편집장·스펙/정본/QA) → Codex(GDScript 구현) → agy(애셋) → architect(검증).
- **Codex 이관 시** — Codex가 구현 주도. 새 피처는 `docs/specs/feat-0XX.md` 스펙을 먼저 쓰고(이 디렉토리에 feat-020/021/028/029 예시 있음, 같은 형식) 그대로 구현. 검증은 항상 `./init.sh` 전체 green + 단언 수 증가. 결정성(BattleSim 순수 로직) 보존.
- BattleSim·battle_unit·전투 로직 변경은 신중히(결정성 테스트가 잡는다). 뷰(battle.gd)·데이터(.tres)·런(run_state/run_manager)는 상대적으로 안전.

## 다음 작업 후보 (Codex가 골라 진행)
우선순위·난이도 순. 각각 `docs/specs/`에 스펙 먼저 쓰고 구현.
1. **밸런스 패스** (저위험, 데이터) — 스킬 피해/쿨다운(skill_system.gd COOLDOWNS), trait 배수(card_catalog.gd build_player_unit), edict pct(edict_catalog.gd EDICTS), 확장/칙령 캐이던스(stage_cadence.gd) 수치 튜닝. test 갱신.
2. **마계 진영 깊이** (중위험, feat-029 패턴) — 마계 3국(황천/낙양/만요) trait/장수 스킬. 현재 적 전용. skill_system.gd + card_catalog.gd + resources/cards .tres. 적 강화 또는 플레이 가능화(군주 추가) 중 택.
3. **feat-028 애니 잔여** (agy 의존) — 촉/위/오 나머지 유닛 walk 시트 + idle/attack. **시스템은 이미 완성** — `<unit>_walk.png`(가로 4프레임 균등, 마젠타 키아웃 투명)를 `assets/sprites/units/<faction>/`에 추가하면 battle.gd가 자동 AnimatedSprite2D 적용. agy로 시트 생성 → 키잉(시트 통째, autocrop 금지) → 배치.
4. **평원 배경 교체** — 사용자 미드저니 결과를 `assets/sprites/bg/plain/field.png`(1920×1080)로 덮고 `./init.sh` 재검증.

## 코드 구조 포인터 (Codex 진입)
- 전투 로직(순수·결정적) — `scripts/battle/battle_sim.gd`(ROW_X/COL_Y/성/이동/승패), `battle_unit.gd`(스탯/상태/effective_attack).
- 스킬 — `scripts/battle/skill_system.gd`(const+COOLDOWNS+cast match+`_cast_*`, `_record_damage_event` 필수). 9스킬(촉5+위오4).
- trait/edict — `scripts/resources/card_catalog.gd` `build_player_unit`(인덕 hp·호패/수전 atk·edict atk), `scripts/run/edict_catalog.gd`.
- 런 상태 — `scripts/run/run_state.gd`(board_rows 3~6·hand·gold·edicts·stage_index), `scripts/autoloads/run_manager.gd`(API), `scripts/run/stage_cadence.gd`(상점4·보스5·확장5·칙령3, node_kind 우선순위).
- 뷰 — `scripts/battle/battle.gd`(아이소 렌더·HUD·AnimatedSprite2D 분기·VFX). `scripts/screens/run_map.gd`(상점·확장·칙령 드래프트 UI).
- 카드 데이터 — `resources/cards/*.tres`, `resources/lords/*.tres`. 카탈로그 `scripts/autoloads/card_library.gd`.
- 테스트 — `test/test_*.gd`, 러너 `test/runner.gd`. `./init.sh`가 import+검증+스모크+테스트 일괄.
- QA 스크린샷 — `tools/shoot_battle.gd`(`LORD`·`SHOOT_STAGE` env), 비헤드리스 `godot --path . res://tools/shoot_battle.tscn`, 결과 `/tmp/shot_*.png`.

## ⚠️ 운영 함정 (검증됨)
- **Codex stdin hang** — `codex exec "..."` 백그라운드는 `< /dev/null`로 stdin 닫을 것(안 닫으면 EOF 대기 hang).
- **agy 애셋** — `--add-dir <dir>` 주면 agy가 그 디렉토리에 이미지 직접 저장(brain 아님). "이미지만 생성, repo 파일 수정 금지" 명시(안 하면 feature_list/progress 자율편집).
- **PATH/HOME** — 백그라운드 셸 python3는 `/usr/bin/python3` 절대경로. godot용 `export HOME=.godot/home`과 PIL python을 한 셸에서 섞지 말 것(키잉 원 HOME, godot만 서브셸).
- 메모리 정본 — `agy-image-pipeline`(agy 파이프라인 상세).

## 알려진 사소 이슈
- feat-020 ROW_X 확장 행 전방 배치(공세 의도, 후방 성 공간 부족) — `battle_sim.gd` 주석.
- 칙령 stage 12=칙령·15=보스 우선(칙령 스킵 가능) — 의도된 충돌 처리.
- `init.sh` 부팅 스모크 라벨이 "run_map.tscn"인데 실제 main_scene은 lord_select — 혼동만, 무관.
- `docs/reports/v0.5-screens/*.png.import` — 미추적 부산물, 무해.

## Codex 시작 프롬프트 (복사)
> 구주쟁패(/Users/taewookkim/dev/guju-jaengpae) 이어서. v0.6 완료(feat-029/020/021/028), `./init.sh` 935 green, 모든 피처 done, working tree 클린. **미푸시 커밋(`git log origin/main..main` 확인 — v0.6 피처 4 + handoff docs) — 사용자 확인 후 `git push origin main` 먼저.** `AGENTS.md`·`session-handoff.md`·`feature_list.json`·`progress.md` 읽고 `./init.sh`로 935 green 확인. 다음 — ① 밸런스 패스 ② 마계 진영 깊이 ③ feat-028 애니 잔여(agy 시트) ④ 평원 배경. 새 피처는 `docs/specs/`에 스펙 먼저(feat-020~029 형식 참고) → 구현 → `./init.sh` green(단언 증가) → 커밋. BattleSim 결정성 보존.
