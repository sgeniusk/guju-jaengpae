# 진행 로그

이 파일은 재시작 상태용이다. 전체 이력이 아니다. 오래된 증거는 CHANGELOG·reports·docs로 옮긴다. (≤120줄)

## 현재 상태 (Current State)
**마지막 갱신 (Last Updated)** — 2026-05-30
**활성 피처 (Active Feature)** — feat-007 로그라이크 맵 (다음 외주 예정)
**현재 목표 (Current Objective)** — v0.2 로그라이크 골격. feat-006 다중 파도 done, 다음은 노드 맵.

## 상태 (Status)
### 완료 (What's Done)
- [x] 하네스 + 세계관 정본(docs/worldview.md) + CHANGELOG
- [x] **feat-001 Godot 셋업** — project.godot, 디렉토리, 오토로드(GameManager·EventBus·CardLibrary·RunManager).
- [x] **feat-002 카드 스키마** — CardData/UnitCardData/LordData/CardVocab + 촉 샘플. validate_cards 통과.
- [x] **feat-003 레인 오토배틀 코어** — BattleSim(순수·결정적) + battle.tscn. sim_smoke + 부팅 스모크 통과.
- [x] **feat-004 전리 보상** — RunState/RewardPool + RunManager. 승리→보상 선택→덱 편입→다음 전투(reload, 덱 영속). 신규 카드 4종. reward_smoke 통과. **v0.1 루프 완성.**
- [x] **feat-005 검증 커버리지** — test/TestCase + runner + 단위 테스트 60 assertions. init.sh 내장 러너 통합.
- [x] **feat-006 다중 파도** (Codex) — BattleSim 파도 큐(set_waves/_spawn_next_wave) + wave_factory default_waves 3파도(정예 포함) + battle.gd 자동 시각화·파도 N/M. test_multiwave 16 assertions. ./init.sh 76 단언 green, 회귀 없음.
### 진행 중 (What's In Progress)
- [ ] 없음 (feat-007 착수 대기)
### 다음 (What's Next)
1. **[맵] feat-007 로그라이크 맵** — 노드 맵 런 진행. 스펙 작성 → Codex 외주.
2. agy/사람 플레이 QA — 클릭 배치→다중 파도→보상→다음 전투를 실제 화면에서.
3. (v0.2+) 메타 해금·천계/마계 6국·계략/보패.

## 블로커 / 리스크 (Blockers / Risks)
- [ ] 시각 플레이 미확인 — 클릭 배치~보상~다음전투는 사람이 `godot --path .`로 확인 필요. 로직은 자동 검증됨.
- [ ] Godot 4.6.3 macOS headless가 CA 인증서 조회 경고(`get_system_ca_certificates`)를 출력함. 종료 코드는 0이고 테스트에는 영향 없음.

## 내린 결정
- **분업 — 구현은 Codex 외주** — 사용자 지시. Claude는 스펙/정본/검증, Codex(5.5 xhigh, 샌드박스 workspace-write)가 구현.
- **feat-005 = 내장 테스트 하네스(GUT 아님)** — 외부 코드 반입이 안전 게이트에 차단됨. 기존 *_smoke.gd 패턴을 정식 하네스로 일반화. 네트워크·서드파티 0. (사용자가 원하면 GUT로 전환 가능.)
- **전투 로직/표현 분리, 적은 카드 아님, trait_id, 승=적전멸/패=기지도달·아군전멸** — 상세 CHANGELOG.

## 이번 세션 수정 파일 (Files Modified)
- v0.1 — 전체 하네스·게임 코드 (커밋 283f68a)
- feat-006 — scripts/battle/{battle_sim,wave_factory,battle}.gd, test/test_multiwave.gd, docs/specs/feat-006.md
- 상태 — feature_list.json, progress.md, CHANGELOG.md

## 검증 증거
- [x] `./init.sh` (2026-05-30) → import / 카드검증(10·1) / sim·reward 스모크 / 씬 부팅 무에러 / 단위 테스트 5파일 76 단언 통과. 종료 0.
- [x] feat-006 회귀·스코프 — 기존 60 + multi-wave 16 = 76, 단일 파도 경로 호환. git diff로 resources/scenes/project.godot 미수정 확인.
- [ ] 시각 플레이(클릭 배치→다중 파도→보상→다음 전투) → agy 또는 사람 확인 필요.

## 아카이브 포인터
- 구조·결정 이력 — `CHANGELOG.md` / 세계관·스키마 — `docs/worldview.md` / 스펙 — `docs/specs/`

## 다음 세션 메모
`./init.sh`로 베이스라인 확인 후 agy 플레이 QA 또는 v0.2 기획 피처를 선택한다. 단위 테스트는 외부 프레임워크 없이 `res://test/runner.gd`가 `test/test_*.gd`를 수집한다.
