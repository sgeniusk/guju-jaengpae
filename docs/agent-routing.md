# 에이전트 라우팅 노트

이 문서는 Codex Ultragoal G085 이후의 역할 라우팅 결정을 짧게 고정한다. AGENTS.md의 상위 계약을 반복하지 않고, 구주쟁패 작업에서 헷갈리기 쉬운 사용 경계만 기록한다.

## G085 — explore

`explore`는 repo 안의 현재 사실을 빠르게 찾는 read-only 역할이다.

### 쓸 때
- 파일·심볼·패턴·호출 관계를 찾을 때.
- 기존 구현 owner를 확인할 때. 예: `RunManager` API, `WaveFactory` stage 경계, `CardCatalog` 리소스 로딩 경로.
- 수정 전 영향 범위를 좁힐 때. 예: 어떤 테스트가 현재 동작을 잠그는지, 어떤 씬이 같은 helper를 공유하는지.
- 오래된 문서 문구와 현재 코드의 차이를 찾을 때.

### 산출물
- 관련 파일과 심볼 목록.
- 현재 코드가 실제로 하는 일의 짧은 요약.
- 수정하면 같이 봐야 할 테스트·스모크·문서 포인터.
- 불확실한 점과 다음 역할로 넘길 경계.

### 경계
- 외부 공식 문서, SDK 동작, 버전별 API 확인은 `researcher`로 넘긴다.
- 패키지·SDK 선택, 업그레이드, 교체 판단은 `dependency-expert`로 넘긴다.
- 구현, 리팩터링, 테스트 추가는 `executor`로 넘긴다.
- 장기 구조 판단, 저장·전투·스키마 경계 설계는 `architect`로 넘긴다.
- 계획 확정, phase 쪼개기, acceptance criteria 정리는 `planner`나 `critic`으로 넘긴다.

### 완료 기준
- `explore` 결과만으로 다음 작업자가 열어야 할 파일과 확인해야 할 테스트가 분명하다.
- repo 밖 사실을 단정하지 않는다.
- 권장 변경은 “어디를 봐야 하는지” 수준에 머물고, 코드 수정을 직접 맡지 않는다.

## G086 — planner

`planner`는 phase별 피처를 쪼개고 의존성을 정렬하는 역할이다.

### 쓸 때
- 큰 목표를 작은 story나 feature로 나눌 때.
- 선행 조건과 blocker를 정리할 때. 예: 정본 승인 전에는 천계·마계 Resource를 만들지 않는 순서.
- 여러 파일·시스템을 건드리는 작업의 실행 순서를 정할 때.
- 각 단계의 stop condition과 검증 모양을 먼저 정해야 할 때.

### 산출물
- 단계별 작업 목록과 각 단계의 목적.
- 선행 의존성, 후속 의존성, 명시적 보류 조건.
- 각 단계의 acceptance criteria와 필요한 검증 명령.
- 한 번에 하나만 구현해야 하는 현재 feature 후보.

### 경계
- planner는 코드를 직접 수정하지 않는다.
- repo 현황을 모르면 먼저 `explore` 결과를 받는다.
- 시스템 경계나 장기 아키텍처 판단이 핵심이면 `architect`로 넘긴다.
- 계획의 허점, acceptance criteria 누락, 리스크 반박은 `critic`으로 넘긴다.
- 계획이 승인되고 구현 범위가 좁아지면 `executor`로 넘긴다.

### 완료 기준
- 바로 다음에 잡을 한 feature가 분명하다.
- 건드리지 말아야 할 범위와 사용자 확인이 필요한 결정이 분리되어 있다.
- 검증 명령과 상태 파일 갱신 대상이 계획 안에 포함되어 있다.

## G087 — architect

`architect`는 스키마·런 상태·저장·전투 경계를 검토하는 역할이다.

### 쓸 때
- `CardData`/`UnitCardData`/`BuildingCardData`/`SchemeCardData`/`TreasureCardData` 같은 Resource schema를 바꿀 때.
- `RunState`, `ProfileState`, `PersistenceStore`, `RunManager`의 저장·재개·해금 경계를 바꿀 때.
- `BattleSim`, `BattleUnit`, `SkillSystem`, `WaveFactory`처럼 결정성과 전투 결과를 좌우하는 경계를 바꿀 때.
- 새 시스템이 scene/UI, autoload, pure logic, Resource loader 중 어디에 살아야 하는지 불분명할 때.

### 산출물
- 현재 owner와 변경 후 owner의 명시.
- 유지해야 할 invariant. 예: BattleSim 순수성, RunState primitive payload, Resource id 안정성, 저장 I/O RunManager/PersistenceStore 경계.
- 위험한 coupling과 피해야 할 대안.
- 구현자가 따라야 할 최소 변경 경로와 필요한 회귀 테스트.

### 경계
- architect는 원칙적으로 read-only 검토와 설계 판정까지 맡는다.
- repo 파일 위치가 불명확하면 먼저 `explore`로 매핑한다.
- phase sequencing은 `planner`, 구현은 `executor`, 계획 반박은 `critic`으로 넘긴다.
- 외부 Godot API나 export 규칙 확인이 필요하면 `researcher`로 넘긴다.

### 완료 기준
- 어떤 모듈이 owner인지, 어떤 모듈을 건드리면 안 되는지 분명하다.
- 결정성·저장 호환성·Resource schema·UI 경계 중 어떤 invariant를 테스트로 잠글지 정해져 있다.
- 구현자가 넓은 리팩터링 없이 다음 safe step을 잡을 수 있다.

## G088 — critic

`critic`은 계획 일관성, acceptance criteria, 리스크 누락을 검토하는 역할이다.

### 쓸 때
- planner나 architect가 만든 계획이 충분히 검증 가능한지 의심될 때.
- “done” 조건이 모호하거나 테스트·증거로 증명하기 어려울 때.
- 사용자 확인, 정본 승인, push/tag 같은 불가역 또는 외부 권한 경계가 계획에 섞였는지 확인할 때.
- 이미 좋아 보이는 계획의 숨은 coupling, scope creep, 누락된 실패 모드를 찾을 때.

### 산출물
- 계획의 불일치, 누락, 과한 범위, 검증 불가능 조건 목록.
- 반드시 추가해야 할 acceptance criteria.
- 위험 순위와 최소 수정 제안.
- 구현 전에 보류하거나 사용자 확인이 필요한 결정.

### 경계
- critic은 구현을 대신하지 않는다.
- critic은 새 계획을 독점적으로 다시 쓰지 않고, 최소 수정 제안으로 돌려준다.
- repo 사실관계가 불명확하면 `explore` 확인을 요구한다.
- 설계 owner 판단은 `architect`, phase sequencing은 `planner`, 코드는 `executor`로 넘긴다.

### 완료 기준
- acceptance criteria가 관찰 가능한 결과와 검증 명령으로 바뀌어 있다.
- 위험한 미지원 범위와 사용자 확인 게이트가 명시되어 있다.
- critic 지적을 반영하지 않아도 되는 항목은 이유가 남아 있다.

## G089 — executor

`executor`는 좁게 승인된 피처를 실제 GDScript, 씬, Resource, 테스트 변경으로 구현하는 역할이다.

### 쓸 때
- planner나 architect가 구현 범위와 owner를 충분히 좁힌 뒤.
- 기존 테스트가 실패하거나 새 acceptance criteria를 코드로 잠가야 할 때.
- `RunState`, `BattleSim`, UI scene, catalog, validator처럼 명확한 owner 파일이 정해졌을 때.
- 문서·정본 결정이 아니라 이미 합의된 스펙을 Godot 4.x 프로젝트에 반영할 때.

### 입력
- 현재 피처 하나의 목표와 제외 범위.
- 건드릴 파일 또는 owner 모듈.
- 필요한 검증 명령. 기본은 `./init.sh`.
- Resource schema, 저장 형식, 정본 명칭처럼 바꾸면 안 되는 계약.

### 산출물
- 기존 패턴을 따른 GDScript, scene, Resource, 테스트 diff.
- 변경한 동작과 그 동작을 증명한 테스트 증거.
- 갱신이 필요한 `feature_list.json`, `progress.md`, `session-handoff.md` 변경.
- 남은 리스크와 의도적으로 건드리지 않은 범위.

### 경계
- executor는 새 세계관 명칭, 세력 id, Resource schema 정책을 임의로 확정하지 않는다.
- 저장·전투 결정성·스키마 owner가 불명확하면 `architect` 판정을 먼저 받는다.
- 구현 중 범위가 커지면 `planner`로 쪼개고, acceptance criteria가 흔들리면 `critic`으로 돌린다.
- 최종 증거 검증과 릴리스 판단은 `verifier`나 `git-master`로 넘긴다.

### 완료 기준
- 한 피처 범위 안에서 동작, 테스트, 상태 파일이 함께 갱신되어 있다.
- `./init.sh` 또는 문서화된 대체 검증이 실제로 실행되어 결과가 남아 있다.
- GDScript 변경은 기존 owner와 탭 들여쓰기, Resource id 안정성, 저장 호환성을 따른다.
- worktree diff가 설명 가능한 최소 범위로 남아 있다.

## G090 — test-engineer

`test-engineer`는 새 동작을 어떤 테스트로 잠글지 정하고 회귀 커버리지의 빈틈을 찾는 역할이다.

### 쓸 때
- 구현 전에 acceptance criteria를 단언, 스모크, fixture, export check로 바꿔야 할 때.
- 버그 재현이나 저장 마이그레이션, 보상 풀, 전투 결정성처럼 실패 조건을 먼저 고정해야 할 때.
- `./init.sh`가 너무 넓어 원인 분리가 필요하고, 더 작은 표적 테스트가 필요할 때.
- UI 흐름이나 스크린샷 QA가 코드 테스트와 어디까지 겹치는지 정해야 할 때.

### 산출물
- 어떤 테스트 파일에 어떤 assertion을 추가할지에 대한 스펙.
- 회귀를 증명하는 최소 fixture, seed, stage, deck, save payload 조건.
- 반드시 통과해야 하는 명령과 실패 시 읽어야 할 로그 포인터.
- 테스트가 일부러 덮지 않는 영역과 그 이유.

### 경계
- test-engineer는 제품 동작을 임의로 바꾸지 않는다.
- 구현은 `executor`, 최종 증거 확인은 `verifier`, 시각 판단은 `vision`이나 `designer`로 넘긴다.
- 테스트 설계 중 스키마나 저장 계약이 모호하면 `architect`로 되돌린다.
- acceptance criteria 자체가 불명확하면 `critic`에게 먼저 검토를 맡긴다.

### 완료 기준
- 새 테스트가 관찰 가능한 사용자 동작이나 시스템 invariant와 연결되어 있다.
- 실패 메시지가 다음 작업자가 원인을 좁힐 수 있을 만큼 구체적이다.
- 표적 테스트와 전체 `./init.sh` 중 어느 검증이 필요한지 분명하다.
- 회귀 커버리지의 남은 공백이 명시되어 있다.

## G091 — verifier

`verifier`는 구현 완료 주장이 실제 증거로 닫히는지 독립적으로 확인하는 역할이다.

### 쓸 때
- `executor`가 구현과 테스트 결과를 제출한 뒤 완료 판정을 내릴 때.
- `./init.sh`, 표적 테스트, 스크린샷, export smoke 같은 증거가 acceptance criteria와 맞는지 확인할 때.
- 실패는 없지만 경고, 누락된 상태 파일, stale docs, 미커밋 diff가 남았는지 점검할 때.
- 릴리스 후보나 handoff 전에 clean restart 가능 상태를 확인할 때.

### 산출물
- 검증한 claim과 그 claim을 증명한 명령·파일·스크린샷·export 결과.
- 통과, 조건부 통과, 실패의 판정과 근거.
- 남은 경고와 제품 리스크가 이미 문서화되어 있는지의 확인.
- 다시 `executor`, `test-engineer`, `designer`, `vision`, `git-master`로 넘겨야 할 항목.

### 경계
- verifier는 구현 diff를 직접 고치지 않는다. 실패를 발견하면 owner에게 돌려준다.
- 시각 품질 판단이 핵심이면 `vision`이나 `designer`에게 증거 판독을 맡긴다.
- 릴리스 push, tag, 배포 판단은 `git-master`와 사용자 확인 게이트로 넘긴다.
- 테스트가 부족해 증명 자체가 불가능하면 `test-engineer`에게 커버리지 보강을 요구한다.

### 완료 기준
- `./init.sh` 또는 story별 검증 명령의 실제 출력이 확인되어 있다.
- 스크린샷·export 증거는 파일 경로, 실행 환경, 성공 marker가 함께 남아 있다.
- 상태 파일과 handoff 문서가 다음 세션에서 재시작 가능한 정보를 담고 있다.
- 알려진 경고와 미지원 범위가 릴리스 리스크 문서 또는 handoff에 연결되어 있다.

## G092 — designer

`designer`는 플레이어가 런 흐름, 온보딩, HUD 상태를 화면만 보고 이해할 수 있는지 판단하는 역할이다.

### 쓸 때
- 군주 선택, 첫 전투, 배치, 보상, 상점, 칙령, 결과 화면의 흐름이 막히거나 헷갈릴 때.
- HUD의 gold, stage, hand, edict, treasure, 성 HP, wave 정보 우선순위를 조정할 때.
- 툴팁, 버튼 라벨, 빈 상태, 잠금 상태, feedback text가 사용자 행동을 충분히 안내하는지 볼 때.
- 스크린샷 QA에서 “무엇이 문제인지”를 UX 관점으로 해석해야 할 때.

### 산출물
- 사용자 흐름별 문제와 수정 우선순위.
- 화면 상태별 필요한 copy, affordance, feedback, layout 조정안.
- designer 판단을 구현할 owner scene/script 포인터.
- 시각 QA나 코드 구현으로 넘길 명확한 acceptance criteria.

### 경계
- designer는 세계관 정본이나 수치 밸런스를 임의로 바꾸지 않는다.
- scene/script 구현은 `executor`, screenshot 판독은 `vision`, 최종 검증은 `verifier`로 넘긴다.
- UI 구조가 저장·런 상태 계약을 바꿔야 하면 `architect` 검토를 먼저 받는다.
- 취향 문제가 아니라 플레이 흐름을 막는 문제를 우선한다.

### 완료 기준
- 신규 플레이어가 다음 행동을 찾을 수 있는지 화면 상태별로 설명되어 있다.
- HUD와 툴팁 수정안이 실제 사용자 행동, 상태 변화, 오류 예방과 연결되어 있다.
- 구현자가 바로 손댈 scene/script와 확인할 스크린샷이 분명하다.
- 남은 미학적 polish와 필수 UX blocker가 분리되어 있다.

## G093 — vision

`vision`은 실제 스크린샷을 보고 화면 품질과 시각 회귀를 판독하는 역할이다.

### 쓸 때
- 전투, 상점, 결과, 군주 선택, 런맵 스크린샷에서 텍스트 겹침이나 잘림을 확인할 때.
- placeholder, 누락 에셋, 잘못된 faction theme, 빈 화면, 잘못된 카메라 framing을 찾을 때.
- UI 툴팁과 HUD 정보가 화면에서 실제로 읽히는지 판독할 때.
- export smoke나 수동 QA가 남긴 이미지 증거를 verifier가 판단하기 전에 읽어야 할 때.

### 산출물
- 스크린샷 파일 경로와 화면 상태별 관찰 결과.
- blocker, watch, polish로 나눈 시각 문제 목록.
- 문제가 발생한 영역, 추정 원인, 구현 owner 포인터.
- 재촬영이 필요한 화면과 성공 기준.

### 경계
- vision은 이미지를 판독하지만 UX 설계 우선순위는 `designer`로 넘긴다.
- scene/script 수정은 `executor`, 최종 완료 판정은 `verifier`가 맡는다.
- 스크린샷 없이 화면 상태를 추측하지 않는다.
- 색감·분위기 취향보다 읽기, 겹침, 누락, 제품 placeholder 같은 관찰 가능한 문제를 우선한다.

### 완료 기준
- 각 판정이 특정 스크린샷과 관찰 가능한 위치에 연결되어 있다.
- blocker와 polish가 분리되어 구현 우선순위를 흐리지 않는다.
- 재검증에 필요한 촬영 명령이나 화면 경로가 남아 있다.
- 제품 화면에 남은 placeholder 또는 누락 에셋 여부가 명시되어 있다.

## G094 — git-master

`git-master`는 커밋 히스토리, push, tag, 릴리스 브랜치 전략을 안전하게 정리하는 역할이다.

### 쓸 때
- 여러 로컬 커밋이 쌓여 원격 발행 순서, squash 여부, tag 시점을 정해야 할 때.
- Lore Commit Protocol 준수 여부와 커밋 경계를 검토할 때.
- 릴리스 체크리스트, export 증거, known risk가 tag 전에 충분한지 확인할 때.
- push, force, tag, release처럼 사용자 확인이 필요한 외부 side effect를 준비할 때.

### 산출물
- 현재 branch, ahead/behind, worktree 상태, 최근 커밋 목록.
- push/tag/release 전제 조건과 보류 사유.
- 필요한 사용자 확인 문장과 실행할 정확한 git 명령.
- 릴리스 후 되돌릴 수 없는 변경과 복구 경로.

### 경계
- git-master는 사용자 확인 없이 push, force push, tag, GitHub release를 실행하지 않는다.
- 제품 구현이나 테스트 보강은 `executor`와 `test-engineer`로 넘긴다.
- 릴리스 적합성 증거 확인은 `verifier`, 사용자-facing 문구는 필요하면 `writer`로 넘긴다.
- 히스토리 정리는 기존 사용자 변경을 되돌리지 않고, dirty worktree를 먼저 설명한다.

### 완료 기준
- 로컬과 원격 차이, 발행 대상 커밋, 보류 중인 외부 side effect가 명확하다.
- Lore Commit Protocol 위반이나 누락된 검증 trailer가 있으면 지적되어 있다.
- push/tag 명령은 사용자 확인 후 실행할 수 있을 만큼 구체적으로 준비되어 있다.
- 실행하지 않은 외부 작업은 “안 함”으로 증거에 남아 있다.

## G095 — ultragoal

`$ultragoal`은 Phase 0부터 v1.0까지 긴 순차 목표를 durable ledger로 밀고 갈 때 기본 경로다.

### 쓸 때
- 완료까지 여러 story가 있고, 각 story의 증거를 `.omx/ultragoal/ledger.jsonl`에 남겨야 할 때.
- 한 번에 한 피처 원칙을 지키면서도 긴 제품 완성 계획을 끊기지 않게 이어가야 할 때.
- Codex aggregate goal 하나 아래에서 G001, G002 같은 repo-native story를 차례대로 닫을 때.
- 나중에 추가되거나 수정된 story도 원래 brief constraints 안에서 추적해야 할 때.

### 산출물
- `.omx/ultragoal/goals.json`의 story 상태와 active goal id.
- 각 story 완료 후 fresh `get_goal` snapshot을 포함한 checkpoint.
- 검증 명령, 커밋, worktree 상태, push/tag 보류 여부가 들어간 evidence.
- failed, blocked, needs-user-decision 상태의 명확한 사유.

### 경계
- 중간 story에서는 Codex aggregate goal을 `update_goal`로 complete 처리하지 않는다.
- 숨은 Codex goal state를 shell에서 바꾸지 않고, active objective가 다르면 멈춰서 정리한다.
- 각 story는 현재 피처 하나만 닫고, 큰 범위 변경은 steering이나 새 story로 분리한다.
- 최종 story만 mandatory final cleanup/review gate를 통과한 뒤 aggregate goal을 complete 처리한다.

### 완료 기준
- `omx ultragoal complete-goals --json`으로 받은 현재 story만 완료되어 있다.
- checkpoint evidence가 실제 파일, 커밋, 검증 출력, clean/dirty 상태를 포함한다.
- ledger와 Codex goal snapshot의 objective와 status가 서로 모순되지 않는다.
- 다음 story가 같은 절차로 재개될 수 있다.

## G096 — team

`$team`은 Phase 4 이후 세력별 데이터, 스킬, 테스트, 아트 QA처럼 write scope가 분리될 때 적합하다.

### 쓸 때
- 여러 세력이나 화면을 독립적으로 조사·검증·수정할 수 있을 때.
- 데이터 작성, 테스트 설계, 스크린샷 판독, 문서 갱신이 서로 다른 파일 소유권을 가질 때.
- leader가 worker 결과를 통합하고 `./init.sh`를 직접 실행할 여유가 있을 때.
- 병렬화가 속도뿐 아니라 교차검증 품질을 실제로 높일 때.

### 산출물
- worker별 목표, write scope, 금지 범위, 검증 명령.
- worker 결과의 파일·테스트·스크린샷 증거.
- leader가 통합한 최종 diff와 충돌·중복 정리 내역.
- ultragoal checkpoint에 넣을 팀 단위 evidence.

### 경계
- team은 한 피처 원칙을 깨기 위한 우회로가 아니다.
- 같은 파일을 여러 worker가 동시에 고치는 작업은 피하고 leader가 scope를 다시 나눈다.
- 정본 미승인 세력명, push/tag, schema 확정 같은 결정은 team worker에게 맡기지 않는다.
- Codex App에서 OMX team runtime이 없으면 native subagents나 solo 실행으로 대체한다.

### 완료 기준
- 각 worker의 산출물과 검증 증거가 leader에게 합쳐져 있다.
- leader가 통합 diff를 직접 읽고 `./init.sh` 또는 문서화된 검증을 실행했다.
- shared-file conflict, 누락된 증거, scope creep이 정리되어 있다.
- team 결과가 ultragoal ledger checkpoint로 이어질 수 있다.

## G097 — ralph

`$ralph`는 단일 소유자가 한 피처를 끝까지 밀어붙이는 fallback이며, 기본 durable tracking은 `$ultragoal`이 낫다.

### 쓸 때
- story가 하나의 피처로 좁고, 구현·검증·상태 갱신을 한 소유자가 계속 잡아야 할 때.
- 긴 goal ledger보다 단일 피처의 persistent loop와 회복력이 더 중요한 때.
- 다른 workflow가 과하고, 반복 수정과 검증만 남았을 때.
- 중간에 끊겨도 같은 owner가 `progress.md`와 검증 증거로 재개할 수 있을 때.

### 산출물
- 현재 피처의 목표, 제외 범위, 검증 명령.
- 반복 루프에서 고친 diff와 실패·성공 증거.
- `progress.md`, `feature_list.json`, 필요 시 `session-handoff.md` 갱신.
- 종료 시 clean restart 가능 상태.

### 경계
- 여러 story를 durable하게 추적해야 하면 `$ultragoal`을 쓴다.
- 병렬화가 실제로 유리하면 `$team`이나 native subagents로 나눈다.
- ralph 활성 중 계획 산출물이 없으면 먼저 planning gate를 닫는다.
- 정본 승인, push/tag, schema 정책처럼 외부 결정이 필요한 항목은 묻거나 별도 story로 분리한다.

### 완료 기준
- 단일 피처가 Definition of Done을 만족하고 실제 검증 출력이 있다.
- 상태 파일이 다음 세션에서 바로 재시작 가능한 내용을 담고 있다.
- ralph loop가 불필요하게 열린 채 남아 있지 않다.
- durable multi-story 추적이 필요한 경우 ultragoal ledger로 handoff되어 있다.

## G098 — high

스키마, 저장, 전투 경계 변경은 high effort로 다룬다.

### 해당 범위
- `CardData` 계열 Resource schema, `CardVocab`, validator, catalog loading.
- `RunState`, `ProfileState`, `PersistenceStore`, `RunManager` 저장·재개·해금 경계.
- `BattleSim`, `BattleUnit`, `SkillSystem`, `WaveFactory` 결정성·전투 결과 경계.
- export, save migration, 기존 run/profile 호환성을 건드리는 변경.

### 처리 원칙
- `architect` 검토로 owner와 invariant를 먼저 확정한다.
- `test-engineer`가 missing field, unknown field, deterministic sim, smoke test를 잠근다.
- `executor`는 한 피처 diff로 구현하고, 넓은 리팩터링은 분리한다.
- `verifier`가 표적 테스트와 `./init.sh`를 모두 읽고 완료 판정한다.

### 완료 기준
- 유지해야 할 schema, save payload, RNG, battle result invariant가 문서나 테스트에 드러나 있다.
- old/new payload와 Resource id 안정성을 깨지 않는 증거가 있다.
- 실패 시 어떤 owner로 되돌릴지 분명하다.
- 릴리스 리스크가 있으면 `docs/release-risks.md` 또는 handoff에 연결되어 있다.

## G099 — medium

데이터 튜닝과 문서 동기화는 medium effort로 다룬다.

### 해당 범위
- trait, edict, scheme, treasure, shop price, reward pool의 명백한 outlier 조정.
- README, CHANGELOG, roadmap, specs, handoff, feature list의 현재 상태 동기화.
- stage cadence, tooltip copy, release checklist처럼 정책은 정해졌고 반영이 필요한 작업.
- 테스트 기대값 또는 스크린샷 증거를 최신 동작에 맞춰 갱신하는 작업.

### 처리 원칙
- 변경 전 현재 값과 의도한 효과를 작게 기록한다.
- 수치 튜닝은 broad rebalance가 아니라 명백한 outlier 중심으로 제한한다.
- 문서 동기화는 코드와 정본 중 어느 쪽을 기준으로 삼았는지 밝힌다.
- 검증은 관련 표적 테스트와 `./init.sh`를 기본으로 한다.

### 완료 기준
- 바뀐 수치나 문서 문구의 기준이 현재 코드·정본·검증 증거와 일치한다.
- 밸런스 조정이 플레이 루프를 막는 문제를 해결한다는 근거가 있다.
- stale 문구가 남았는지 `rg`나 관련 파일 확인으로 점검되어 있다.
- high-effort 경계로 번지는 변경은 분리되어 있다.

## G100 — low

repo lookup과 단순 파일 매핑은 low effort로 다룬다.

### 해당 범위
- 파일, 심볼, 테스트, scene, Resource 위치를 찾는 작업.
- 기존 구현 owner와 호출 관계를 빠르게 확인하는 작업.
- stale 문구나 TODO, feature id, asset 경로를 찾는 작업.
- 코드 변경 전 영향 범위를 좁히는 read-only 탐색.

### 처리 원칙
- 기본 도구는 `rg`, `rg --files`, `git status`, `git log`, `sed` 같은 빠른 로컬 확인이다.
- repo 밖 사실이나 Godot API 버전 판단은 low effort로 단정하지 않는다.
- 결과는 파일 경로, 심볼, 다음에 열어야 할 테스트 중심으로 짧게 남긴다.
- 구현이 필요해지는 순간 `executor`나 상위 effort로 넘긴다.

### 완료 기준
- 다음 작업자가 볼 파일과 테스트가 분명하다.
- read-only 탐색 결과와 추정이 구분되어 있다.
- 외부 문서나 설계 판단이 필요한 부분은 별도로 표시되어 있다.
- 불필요한 장기 조사로 확대되지 않았다.

## G101 — export high

릴리스 export와 세이브 마이그레이션은 high effort로 다룬다.

### 해당 범위
- `export_presets.cfg`, export templates, exported app smoke, packaging output.
- `.tres.remap`, Resource loading, platform path, build artifact ignore 정책.
- `save_version`, old/new run payload, profile payload, unlock migration.
- 릴리스 tag 전에 필요한 checklist, known risk, rollback 판단.

### 처리 원칙
- export는 editor green만으로 닫지 않고 실제 export와 실행 smoke를 확인한다.
- migration은 old payload, missing field, unknown field, newer version 테스트를 포함한다.
- build artifact는 repo에 섞이지 않게 하고, 필요한 정책만 문서화한다.
- tag나 release는 `git-master`와 사용자 확인 전에는 실행하지 않는다.

### 완료 기준
- export 산출물 생성과 실행 marker가 모두 증거로 남아 있다.
- 저장 호환성 테스트가 과거 payload와 신규 payload를 함께 덮고 있다.
- 알려진 플랫폼·템플릿·Resource warning이 release risk로 연결되어 있다.
- push, tag, release 같은 외부 side effect의 실행 여부가 명시되어 있다.

## G102 — default ultragoal prompt

기본 실행 프롬프트는 `$ultragoal "구주쟁패 Phase 0부터 v1.0 계획 순차 실행"`이다.

### 쓸 때
- 새 세션에서 긴 제품 완성 계획을 이어가야 할 때.
- 아직 어떤 피처를 잡을지보다 durable sequencing과 ledger checkpoint가 더 중요할 때.
- Phase 0부터 v1.0까지의 남은 story를 순서대로 재개해야 할 때.
- 단일 피처 실행보다 전체 계획의 stop condition과 audit trail이 중요한 때.

### 실행 전 확인
- `AGENTS.md`, `session-handoff.md`, `progress.md`를 읽는다.
- `omx ultragoal complete-goals --json`으로 현재 story를 받는다.
- `get_goal`이 같은 aggregate objective를 active로 보고하는지 확인한다.
- push/tag/canon approval처럼 사용자 확인이 필요한 항목은 실행하지 않고 보류한다.

### 완료 기준
- 현재 story만 완료하고 checkpoint한다.
- 각 story 증거에 커밋, 검증, worktree 상태, 실행하지 않은 외부 작업이 남아 있다.
- 최종 story 전까지 aggregate goal은 active로 유지된다.
- 다음 story가 같은 프롬프트로 이어질 수 있다.

## G103 — realm team prompt

병렬 구현이 필요해지면 `$team "구주쟁패 Phase 4 마계 3국 확장"`처럼 realm 단위로 실행한다.

### 쓸 때
- 한 realm 안에서 세력별 데이터, 스킬, 테스트, 스크린샷 QA를 분리할 수 있을 때.
- worker별 write scope가 다른 파일이나 다른 faction resource로 나뉠 때.
- leader가 정본 승인 범위와 금지된 세력 id를 명확히 줄 수 있을 때.
- 병렬 결과를 하나의 realm-level 검증으로 통합할 수 있을 때.

### 실행 전 확인
- `docs/worldview.md`와 정본 승인 상태.
- `CardVocab.NATIONS`, lord catalog, reward pool, validator의 현재 id 정책.
- worker별 금지 파일, 허용 파일, 검증 명령.
- 천계·마계 명칭 미승인 상태에서는 playable nation/resource를 만들지 않는다는 gate.

### 완료 기준
- realm 단위 작업이 정본 승인 범위 안에 있다.
- worker 결과가 leader에게 통합되고 `./init.sh`가 leader 손으로 실행되어 있다.
- 세력별 fallback, 테스트, 스크린샷 QA 증거가 분리되어 있다.
- unresolved canon은 needs-user-decision이나 pending story로 남아 있다.

## G104 — Codex App fallback

OMX CLI tmux가 없는 Codex App 표면에서는 native subagents로 read-only review와 검증만 병렬화한다.

### 쓸 때
- Codex App 안에서 작업 중이고 OMX CLI/tmux runtime state가 확인되지 않을 때.
- repo lookup, diff review, 테스트 증거 점검, screenshot 판독처럼 write scope가 없는 병렬 검토가 필요할 때.
- 구현 owner가 이미 leader에게 있고, subagent 결과를 참고 자료로만 통합할 때.
- runtime workflow를 직접 띄우기보다 현재 App 표면에서 안전하게 계속해야 할 때.

### 운영 원칙
- Codex App에서 `$team`, `$ralph` 같은 runtime workflow가 실제로 active라고 단정하지 않는다.
- native subagents는 read-only review와 검증 보조에 한정한다.
- 구현, 상태 파일 갱신, commit, checkpoint는 leader가 직접 통합하고 확인한다.
- subagent 결과가 서로 충돌하면 leader가 diff와 테스트 증거를 기준으로 최종 판단한다.

### 완료 기준
- 어떤 표면에서 실행 중인지와 runtime availability가 명시되어 있다.
- subagent가 쓴 증거와 leader가 직접 확인한 증거가 구분되어 있다.
- leader가 최종 diff를 읽고 `./init.sh` 또는 story별 검증을 실행했다.
- OMX/tmux 의존 작업은 별도 pending 또는 CLI 전환 후보로 남아 있다.

## G105 — worker write scope

각 worker는 자기 write scope와 테스트 증거를 보고한다.

### 보고해야 할 것
- 맡은 story 또는 subtask id.
- 허용된 write scope와 실제로 수정한 파일.
- 실행한 테스트 명령, 주요 출력, 실패 또는 경고.
- 건드리지 않은 shared file, unresolved decision, leader가 확인해야 할 diff.

### 운영 원칙
- worker는 자기 scope 밖 파일을 발견하면 leader에게 보고하고 멈춘다.
- 같은 shared file을 여러 worker가 만져야 하면 leader가 먼저 순서를 정한다.
- worker는 “통과했다”가 아니라 어떤 명령이 어떤 assertion 또는 smoke를 통과했는지 남긴다.
- 테스트를 못 돌렸으면 못 돌린 이유와 대체 확인을 분리해서 적는다.

### 완료 기준
- worker별 write scope와 실제 diff가 일치한다.
- 테스트 증거가 leader의 통합 검증으로 재현 가능하다.
- unresolved decision이 구현 diff 안에 숨지 않고 보고서에 남아 있다.
- leader가 worker 결과를 읽고 merge, reject, follow-up 중 하나로 판정할 수 있다.

## G106 — leader diff and init

leader가 통합 diff를 읽고 `./init.sh`를 직접 실행한다.

### 해야 할 일
- worker 보고와 실제 `git diff`가 같은 범위를 말하는지 확인한다.
- shared file 충돌, 상태 파일 누락, stale 문구, unintended Resource 변경을 찾는다.
- 표적 테스트가 통과했더라도 마지막에는 leader가 직접 `./init.sh`를 실행한다.
- 실패나 경고가 있으면 worker에게 되돌리기 전에 leader가 원인 범위를 좁힌다.

### 운영 원칙
- worker가 실행한 테스트는 증거지만 완료 판정의 대체물이 아니다.
- leader는 `git diff --check`, `git status --short`, 관련 diff read를 최소 확인으로 둔다.
- `./init.sh`의 known ObjectDB/resource warning은 기록하되 신규 script error나 assertion failure와 구분한다.
- 검증 결과는 checkpoint, progress, handoff 중 필요한 곳에 같은 숫자로 남긴다.

### 완료 기준
- leader가 통합 diff를 직접 읽었다.
- `./init.sh` 결과의 assertion 수, pass/fail, known warning이 기록되어 있다.
- worktree 상태와 외부 side effect 실행 여부가 확인되어 있다.
- 실패가 있으면 완료 처리 대신 owner와 다음 수정 범위가 정해져 있다.

## G107 — verifier checklist

verifier가 테스트 증거, 스크린샷, 상태 파일 갱신 여부를 확인한다.

### 확인 항목
- story objective와 acceptance criteria가 실제 diff로 충족되는지.
- `./init.sh`, 표적 테스트, export smoke, screenshot QA 중 필요한 증거가 실행되었는지.
- `feature_list.json`, `progress.md`, `session-handoff.md` 같은 상태 파일이 필요한 만큼 갱신되었는지.
- known warning, skipped check, external side effect 미실행 여부가 명시되었는지.

### 운영 원칙
- verifier는 “테스트가 있다”가 아니라 테스트가 어떤 claim을 증명하는지 확인한다.
- screenshot QA는 파일 경로, 촬영 화면, 판정 결과가 함께 있어야 증거로 인정한다.
- 상태 파일 갱신이 필요 없을 때도 그 이유가 story 범위에서 설명되어야 한다.
- verifier가 실패를 찾으면 완료 판정을 내리지 않고 owner와 재검증 조건을 지정한다.

### 완료 기준
- claim, diff, test output, 상태 파일 갱신 여부가 서로 맞다.
- 스크린샷이 필요한 UI/visual story는 이미지 증거가 남아 있다.
- known warning과 미지원 범위가 새 실패와 섞이지 않는다.
- 다음 세션이 같은 evidence trail로 재시작할 수 있다.

## G108 — leader state files

leader가 `feature_list.json`, `progress.md`, 필요 시 `session-handoff.md`를 갱신한다.

### 갱신할 때
- 피처 상태, acceptance evidence, blocker, next step이 바뀌었을 때.
- 세션을 종료하거나 다음 세션이 이어받아야 할 handoff가 생겼을 때.
- ledger checkpoint만으로는 repo-local 재시작 정보가 부족할 때.
- 사용자 확인 대기, 정본 미승인, push/tag 보류 같은 외부 gate가 남았을 때.

### 운영 원칙
- `feature_list.json`은 machine-readable 상태와 한 줄 증거를 담는다.
- `progress.md`는 사람이 읽는 현재 상태, 블로커, 다음 단계, 압축 증거를 담는다.
- `session-handoff.md`는 긴 작업이 끊길 때만 갱신하고, 새 세션 시작 순서를 분명히 한다.
- 문서-only story처럼 상태 파일 변화가 불필요하면 checkpoint evidence에 그 이유를 남긴다.

### 완료 기준
- 상태 파일과 실제 커밋·검증 결과가 서로 모순되지 않는다.
- 다음 세션이 `AGENTS.md` → `session-handoff.md` → `./init.sh` 순서로 재시작할 수 있다.
- push/tag/canon approval 같은 미실행 외부 작업이 숨지 않는다.
- 상태 파일 갱신 여부를 verifier가 확인할 수 있다.

## G109 — Lore commits

커밋 메시지는 Lore Commit Protocol을 따른다.

### 포함할 것
- 첫 줄은 무엇을 바꿨는지보다 왜 바꿨는지를 쓴다.
- `Constraint:`에는 외부 계약, 정본 gate, 검증 gate처럼 변경을 제한한 조건을 쓴다.
- `Rejected:`에는 다음 agent가 다시 검토하지 않아야 할 대안과 이유를 쓴다.
- `Tested:`와 `Not-tested:`에는 실제 실행한 검증과 남은 공백을 분리한다.

### 운영 원칙
- 단순 문서 변경도 검증 evidence와 scope-risk를 남긴다.
- push, tag, release, canon approval처럼 실행하지 않은 외부 작업은 commit body나 checkpoint에 드러낸다.
- commit message에 workflow trigger처럼 오해될 문구를 불필요하게 넣지 않는다.
- 여러 독립 story는 한 커밋에 뭉치지 않고 story별로 닫는다.

### 완료 기준
- commit이 변경의 이유, 제약, 거절한 대안, 검증, 미검증 범위를 설명한다.
- future agent가 같은 결정을 반복 조사하지 않아도 된다.
- checkpoint evidence와 commit trailers가 서로 모순되지 않는다.
- 커밋 단위가 되돌리기 쉽고 story objective 하나에 대응한다.

## G110 — ultragoal durable ledger

`$ultragoal`을 기본으로 추천한다. 이 계획은 긴 순차 제품 완성 목표라 durable ledger가 가장 잘 맞는다.

### 쓸 때
- Phase 0부터 v1.0까지처럼 여러 세션에 걸친 제품 완성 계획을 이어갈 때.
- 각 story가 commit, 검증, checkpoint evidence로 닫혀야 할 때.
- 미승인 정본, push/tag 보류, failed story처럼 장기 상태를 잃으면 안 될 때.
- 현재 story만 구현하고 다음 story는 ledger가 이어받게 해야 할 때.

### 운영 원칙
- Codex goal은 전체 aggregate objective로 유지하고, OMX story는 ledger 항목으로 닫는다.
- 매 story 시작은 `omx ultragoal complete-goals --json`과 `get_goal` 확인으로 시작한다.
- 최종 story 전까지는 aggregate goal을 complete로 표시하지 않는다.
- blocked, failed, pending, needs-user-decision 상태를 억지로 구현으로 해소하지 않는다.

### 완료 기준
- 각 story evidence에 commit, 검증 명령, worktree 상태, 외부 side effect 여부가 남아 있다.
- story completion과 Codex aggregate goal 상태가 서로 모순되지 않는다.
- 다음 story가 같은 ledger에서 자동 재개된다.
- 사용자가 push/tag/canon approval 같은 외부 결정을 내릴 때까지 gate가 보존된다.

## G111 — team for separable phases

`$team`은 9세력 확장, 애셋 생산, QA처럼 분리 가능한 phase에서 함께 쓰기 좋다.

### 쓸 때
- 세력별 데이터, 스킬, 테스트, 아트 QA가 파일과 책임으로 분리될 때.
- sprite/import 검수, screenshot 판독, 문서 검토처럼 병렬 read-only 또는 asset lane이 독립적일 때.
- 9세력 확장 중 정본 승인 범위가 realm 또는 faction 단위로 명확히 나뉘었을 때.
- leader가 통합 diff와 최종 `./init.sh` 검증을 직접 닫을 수 있을 때.

### 쓰지 않을 때
- Resource schema, RunState 저장, BattleSim 결정성처럼 한 owner가 강한 shared core를 바꿀 때.
- 천계·마계 명칭이나 playable nation id가 아직 승인되지 않았을 때.
- worker write scope가 같은 shared file로 겹치고 순서를 나눌 수 없을 때.
- 단일 피처를 한 사람이 끝까지 구현하는 편이 더 안전할 때.

### 완료 기준
- worker별 산출물과 leader 통합 산출물이 분리되어 있다.
- 정본 gate와 금지 scope가 team prompt에 들어 있다.
- screenshot/asset QA와 코드 테스트가 각자 evidence를 가진다.
- team 결과를 leader가 commit, checkpoint, state-file 기준으로 닫았다.
