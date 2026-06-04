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
