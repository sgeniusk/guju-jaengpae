# feat-031 — 3국 sanity balance pass

## 목표
현세 위·촉·오 3군주가 현재 v0.6 루프에서 막히지 않는지 확인한다. 이 피처는 최종 밸런스 잠금이 아니라 Phase 2 이후 확장 전의 얕은 sanity pass다.

## 범위
- StageCadence의 초반 리듬을 baseline으로 잠근다.
- SkillSystem 쿨다운·피해, trait 배수, edict 수치, 상점 비용은 명백한 outlier만 조정한다.
- lord별 시각 QA 루틴과 스크린샷 증거를 남긴다.
- 최종 난이도 곡선과 통합 수치 튜닝은 Phase 7로 미룬다.

## G026 세부 기준
StageCadence는 현재 상점 4, 보스 5, 확장 5, 칙령 3 간격을 유지한다. 충돌은 `boss > edict > shop > expand > combat` 순서로 해석한다. 첫 15스테이지 node_kind를 테스트로 고정해 상점·보스·칙령·확장이 플레이를 막는 순서로 회귀하지 않게 한다.

## G027 세부 기준
SkillSystem 쿨다운·피해, trait 배수, edict 수치, 상점 비용은 기존 테스트가 기대하는 sanity 범위 안에 있다. G027에서는 수치 조정 없이 구현과 데이터 설명이 어긋난 trait 문구만 고친다. 호패는 기병 계열 공격력 +25%, 수전은 궁병·수군 공격력 +20%로 이미 적용 중이므로 군주 `trait_text`와 회귀 테스트가 같은 효과를 말해야 한다.

## G028 세부 기준
시각 QA는 사람이 매번 수동 명령을 조합하지 않아도 같은 장면을 재현해야 한다. `tools/shoot_visual_qa.sh`는 군주 선택 화면 1장과 위·촉·오 각 군주의 전투 배치/교전/상점 화면을 같은 `SHOT_DIR`에 저장한다. `LORDS`, `SHOOT_STAGE`, `SHOP_STAGE`, `SHOT_DIR`, `GODOT_BIN` 환경변수로 범위를 좁히거나 경로를 바꿀 수 있어야 한다.

## G029 세부 기준
첫 보스까지의 런 흐름은 화면 조작과 같은 상태 전이를 순수 테스트로 재현할 수 있어야 한다. 위·촉·오 각 군주는 시작 손패 배치 → stage 1 전투 승리 → 보상 → stage 2 전투 승리 → 보상 → stage 3 칙령 → stage 4 상점 구매 → stage 5 보스 승리 → 보드 확장 → 보상 → stage 6 도달을 막힘 없이 통과해야 한다.

검증 중 발견된 명백한 outlier는 여기서 좁게 보정한다. G029 기준 자동 배치는 전열부터 채워 근접 장수의 실제 수비 운용을 반영한다. 무작위 보상 운이 테스트 결과를 흔들지 않도록 보상·상점 선택은 가능한 전투 강화 카드 우선순위로 고정한다. 위나라 첫 보스 안정성을 위해 조조 `위압`은 240px/100 피해로 상향하고, 위·오 시작 덱은 첫 전투 기준 최소 6장 이상을 만족해야 한다.

## G030 세부 기준
UI 흐름 검증은 전투 계산이 아니라 화면 부팅과 상태 표시 확인에 집중한다. `tools/shoot_run_flow.sh`는 위·촉·오 각 군주에 대해 stage 1 일반 전투, stage 3 왕의 칙령, stage 4 상점, stage 5 보스 run_map 화면을 같은 `SHOT_DIR`에 저장한다. 각 캡처는 전열 배치와 전투 카드 우선 보상/상점 선택으로 준비한 런 상태를 사용한다.

## G031~G032 세부 기준
헤드리스 수치 회귀는 `./init.sh` 전체 green과 `test_run_flow_sanity.gd`로 잠근다. 스크린샷 증거는 최소 3종을 넘겨 남긴다. 기존 "시각 플레이 필요" 부채는 Phase 1 핵심 화면(군주 선택, 전투 배치/교전, 상점, 칙령, 보스 run_map) 증거로 줄이고, 남은 수동 QA는 장기런·전투 중 표적 지정 체감·결과 화면처럼 아직 하네스가 없는 범위로 좁힌다.

## G033 세부 기준
feat-031은 최종 밸런스 잠금 없이 Phase 1 sanity pass로 종료한다. G029의 조조 `위압` 상향과 위·오 시작 덱 보강은 첫 보스 진행 차단을 없애는 blocker 보정이지 릴리스 밸런스 기준이 아니다. 난이도 곡선, 보상 풀, 상점 가격, trait·edict·scheme·treasure 통합 수치 잠금은 계략·보패, 저장·해금, 9세력, act·보스 구조, UX·아트·오디오가 연결된 뒤 Phase 7에서 수행한다.

## 검증
- `test_stage_cadence.gd`에 첫 15스테이지 node_kind sequence를 추가한다.
- `test_factions.gd`에 군주 trait 설명이 구현 효과와 동기화되어 있는지 추가한다.
- `test_visual_qa_config.gd`에 시각 QA 군주 목록과 파일명 규칙을 추가한다.
- `test_run_flow_sanity.gd`에 위·촉·오 첫 보스까지의 런 흐름 sanity를 추가한다.
- `tools/shoot_visual_qa.sh`가 `/tmp/guju-visual-qa-smoke`에 lord select 1장 + 세 군주 battle deploy/fight/shop 9장을 생성해야 한다.
- `tools/shoot_run_flow.sh`가 `/tmp/guju-run-flow-qa-smoke`에 세 군주 run_map stage 1/3/4/5 스크린샷 12장을 생성해야 한다.
- `./init.sh`가 green이어야 한다.
