# 진행 로그

이 파일은 재시작 상태용이다. 전체 이력이 아니다. 오래된 증거는 CHANGELOG·reports·docs로 옮긴다. (≤120줄)

## 현재 상태 (Current State)
**마지막 갱신 (Last Updated)** — 2026-05-29
**활성 피처 (Active Feature)** — 없음 (feat-005 완료)
**현재 목표 (Current Objective)** — 리포 내장 단위 테스트 하네스까지 v0.1 검증 경로 완성.

## 상태 (Status)
### 완료 (What's Done)
- [x] 하네스 + 세계관 정본(docs/worldview.md) + CHANGELOG
- [x] **feat-001 Godot 셋업** — project.godot, 디렉토리, 오토로드(GameManager·EventBus·CardLibrary·RunManager).
- [x] **feat-002 카드 스키마** — CardData/UnitCardData/LordData/CardVocab + 촉 샘플. validate_cards 통과.
- [x] **feat-003 레인 오토배틀 코어** — BattleSim(순수·결정적) + battle.tscn. sim_smoke + 부팅 스모크 통과.
- [x] **feat-004 전리 보상** — RunState/RewardPool + RunManager. 승리→보상 선택→덱 편입→다음 전투(reload, 덱 영속). 신규 카드 4종. reward_smoke 통과. **v0.1 루프 완성.**
- [x] **feat-005 검증 커버리지** — test/TestCase + runner + BattleUnit/BattleSim/CardCatalog/RunState/RewardPool 단위 테스트 60 assertions. init.sh 내장 러너 통합.
### 진행 중 (What's In Progress)
- [ ] 없음
### 다음 (What's Next)
1. agy 플레이 QA — 클릭 배치→전투→보상 선택→다음 전투 반영을 실제 화면에서 교차검증.
2. (v0.2+) 로그라이크 맵·메타 해금·천계/마계 6국·계략/보패 시스템.

## 블로커 / 리스크 (Blockers / Risks)
- [ ] 시각 플레이 미확인 — 클릭 배치~보상~다음전투는 사람이 `godot --path .`로 확인 필요. 로직은 자동 검증됨.
- [ ] Godot 4.6.3 macOS headless가 CA 인증서 조회 경고(`get_system_ca_certificates`)를 출력함. 종료 코드는 0이고 테스트에는 영향 없음.

## 내린 결정
- **분업 — 구현은 Codex 외주** — 사용자 지시. Claude는 스펙/정본/검증, Codex(5.5 xhigh, 샌드박스 workspace-write)가 구현.
- **feat-005 = 내장 테스트 하네스(GUT 아님)** — 외부 코드 반입이 안전 게이트에 차단됨. 기존 *_smoke.gd 패턴을 정식 하네스로 일반화. 네트워크·서드파티 0. (사용자가 원하면 GUT로 전환 가능.)
- **전투 로직/표현 분리, 적은 카드 아님, trait_id, 승=적전멸/패=기지도달·아군전멸** — 상세 CHANGELOG.

## 이번 세션 수정 파일 (Files Modified)
- 테스트 — test/test_case.gd, test/runner.gd, test/test_battle_unit.gd, test/test_battle_sim.gd, test/test_card_catalog.gd, test/test_run_reward.gd
- 도구 — init.sh(내장 단위 테스트 러너 호출, Godot 로그/HOME 경로를 .godot 아래로 고정)
- 상태 — feature_list.json, progress.md

## 검증 증거
- [x] 임시 실패 테스트 `test/test_tmp_failure.gd` 추가 상태에서 `./init.sh` → 단위 테스트 실패 1건, `INIT_STATUS=1` 확인. 임시 파일 제거 완료.
- [x] `./init.sh` → import OK / 카드검증(cards 10, lords 1) / sim_smoke 승(19.2s 아군잔존 6)·패(0.1s) / reward_smoke OK / 씬 부팅 스모크 무에러 / 단위 테스트 4파일 60 assertions 통과.
- [ ] 시각 플레이(클릭 배치→전투→보상 선택→다음 전투) → agy 또는 사람 확인 필요.

## 아카이브 포인터
- 구조·결정 이력 — `CHANGELOG.md` / 세계관·스키마 — `docs/worldview.md` / 스펙 — `docs/specs/`

## 다음 세션 메모
`./init.sh`로 베이스라인 확인 후 agy 플레이 QA 또는 v0.2 기획 피처를 선택한다. 단위 테스트는 외부 프레임워크 없이 `res://test/runner.gd`가 `test/test_*.gd`를 수집한다.
