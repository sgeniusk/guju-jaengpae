# 세션 핸드오프

작업이 끊겼거나 `progress.md`에 담기 너무 클 때 쓴다. 큰 증거는 링크.

## 현재 상태 (2026-06-04) — v0.6 진영 깊이·메커닉·애니
- **v0.5** 비주얼 전장 + 마누스 페인터리 풀세트(9세력 93종) + 상점(015d) + 촉/위/오 3진영.
- **feat-027 done** — 촉·위·오 30종 agy 그래픽 보정 + 렌더 스케일업. (feat-027 세션 5커밋 **push됨**.)
- **v0.6 ralph 4피처 done (이번 세션)** —
  - **feat-029 위·오 진영 깊이** — 호패(조조)=기병 atk+25%·수전(손권)=궁/수군 atk+20% trait + 조조 위압·하후돈 발돌·손권 결단·주유 화공 4스킬. `ca6b816`.
  - **feat-020 땅 확장** — 보드 3→6행(보스 보상). BattleSim static 유지(ROW_X 6고정, board_rows 제어). `93de775`.
  - **feat-021 왕의 칙령** — 전역 perk(군세 atk·재정 골드·축성 성HP) 3마다 드래프트, EdictCatalog. `449a2bf`.
  - **feat-028 유닛 애니메이션** — AnimatedSprite2D walk 시트 시스템(`_walk.png`→4프레임), 촉 보병 시범. 순수 뷰. `e7d7a6a`.
- **검증** — 각 **architect(opus) APPROVED** + deslop + 회귀, `./init.sh` 723→**935 단언 green**.
- **GitHub** — main, **ralph 4커밋 미푸시**(`ca6b816`·`93de775`·`449a2bf`·`e7d7a6a`). 푸시는 사용자 확인 후.

## 분업 (ralph로 운영, 검증됨)
Claude(편집장·스펙/정본/QA) → **Codex CLI**(GDScript 구현, `codex exec -s workspace-write -c model_reasoning_effort=medium -C <repo> "..." < /dev/null`) → agy(애셋/시트) → Claude(독립 검증·정본·커밋) → **architect**(opus 적대 검증). PRD `.omc/prd.json`. 각 피처 — 스펙(`docs/specs/`)→Codex→Claude(`./init.sh`+diff+architect+deslop)→커밋.

## ⚠️ 운영 함정 (이번 세션 발견·검증, 메모리 `agy-image-pipeline` 반영)
- **Codex stdin hang** — `codex exec "..."` 백그라운드가 stdin EOF 대기로 hang(코드변경 0, "Reading additional input from stdin..." 정체). **`< /dev/null`로 해결**(feat-028 1차 hang→재위임 정상).
- **agy 자율-쓰기** — `--add-dir <dir>` 주면 agy가 그 디렉토리에 이미지 직접 저장(brain 아님). 경로 grep에서 `/assets/` 제외하면 오탐. (이전 함정 — agy가 feature_list/progress 자율편집; "이미지만 생성"+--add-dir 좁히기로 방지.)
- **백그라운드 PATH** — detached 셸 python3 미발견 → 키잉 `/usr/bin/python3` 절대경로. **HOME** — godot용 `export HOME=.godot/home`과 PIL python 섞으면 ModuleNotFoundError(키잉 원 HOME, godot만 서브셸).

## 다음 후보 (v0.6+)
- **feat-028 잔여** — 촉/위/오 나머지 유닛 walk 시트(agy 점진) + idle/attack. 시스템 완료, `<unit>_walk.png` 추가하면 자동 적용.
- 평원 배경 사용자 미드저니 교체(`assets/sprites/bg/plain/field.png` 1920×1080).
- 마계 등 적 진영 깊이(trait/스킬·강화). 밸런스 튜닝(스킬 수치·trait·edict·확장).
- walk 애니 재생 시각 QA(헤드리스 밖, 사람/agy 확인).

## 알려진 사소 이슈
- feat-020 ROW_X 확장 행 전방 배치(공세 의도, 후방 성 공간 부족) — `battle_sim.gd` 주석.
- 칙령 stage 12=칙령·15=보스 우선(칙령 스킵 가능) — 의도된 충돌 처리.
- `docs/reports/v0.5-screens/*.png.import` — 미추적 부산물, 무해.

## 다음 세션 시작 프롬프트 (복사)
> 구주쟁패 이어서. v0.6 ralph 4피처 done — feat-029(위·오 trait/스킬)·020(땅확장)·021(칙령)·028(유닛 애니), `./init.sh` 935 green, architect APPROVED. 미푸시 4커밋(`ca6b816`·`93de775`·`449a2bf`·`e7d7a6a`). `session-handoff`·`feature_list`·`progress` 읽고 `./init.sh` 확인 후 다음 — ① feat-028 잔여(나머지 유닛 walk 시트 agy 점진) ② 평원 배경 미드저니 ③ 밸런스 튜닝 ④ 마계 진영 깊이. 분업 — Claude 스펙→Codex(`codex exec ... < /dev/null`)→architect 검증. ⚠️ Codex stdin은 `< /dev/null`, agy는 `--add-dir` 좁히고 "이미지만 생성" 명시.
