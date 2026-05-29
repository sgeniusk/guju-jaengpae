# AGENTS.md — 삼국지: 구주쟁패 (九州爭霸)

세 CLI(Claude·Codex·agy)가 공유하는 단일 계약이다. 도구에 무관하게 이 규칙을 따른다. Claude 전용 사항은 [CLAUDE.md](CLAUDE.md), 세계관 정본은 [docs/worldview.md](docs/worldview.md)를 본다.
(섹션 제목에 영어 앵커를 병기한다 — 한국어 가독성과 영어로 학습된 CLI·도구의 상호운용을 둘 다 위해.)

## 프로젝트 한 줄 (Project)
삼국지 기반 풀 판타지 덱빌딩 로그라이크 오토배틀러. Godot 4.x (GDScript). 九州 = 三界(현세·천계·마계) × 3국.

## 일의 자리 (Roles)
| CLI | 자리 | 맡는 일 | 넘기지 않는 것 |
|---|---|---|---|
| Claude | 편집장 | 정본·스펙·계획, 세계관·카드 온톨로지, 톤, 오케스트레이션 | 대규모 GDScript 자동화·CI |
| Codex | 구현자 | 스펙 구현(씬·스크립트), 리팩토링, PR, lint/test | 정본 구조·세계관·톤 결정 |
| agy | 교차검증자 | 다른 모델로 적대적 검증, 플레이·멀티모달 QA | 구현 주도 |

흐름 — Claude(스펙) → Codex(구현·PR) → agy(검증) → Claude(정본 반영).

## 시작 워크플로 (Startup Workflow)
코드를 쓰기 전에 (Before writing code):
1. `pwd`로 작업 디렉토리 확인
2. 이 파일과 `CLAUDE.md` 완독
3. `./init.sh`로 환경 검증 (Godot 4.x 필요 — `GODOT_BIN` 환경변수로 경로 지정 가능)
4. `feature_list.json`에서 미완 피처 하나 선택
5. `progress.md`에서 현재 상태·블로커·다음 단계 확인

## 작업 규칙 (Working Rules)
- **한 번에 한 피처 (One feature at a time)** — `feature_list.json`에서 미완 피처 정확히 하나만 잡는다.
- **검증 필수** — `./init.sh` 또는 문서화된 명령을 실제로 돌리기 전엔 done 주장 금지.
- **스코프 유지 (Stay in scope)** — 현재 피처와 무관한 파일 수정 금지.
- 카드·장수·병종 데이터는 정해진 Resource 스키마를 따른다 — 임의 필드 추가 금지, 먼저 정본(Claude)과 합의.
- 상태 파일은 요약만. 전체 로그는 reports로.
- push·force·삭제는 사용자 확인 후.

## 자율성 — 가정-후-표시 (Assume & Annotate)
되돌릴 수 있는 행동은 묻지 않고 진행하고, 가정은 끝에 모아 보고한다. 블로킹 질문은 되돌리기 어려운 결정에만.

## 워커(서브에이전트) 위임 규칙
- 코디네이터는 위임이 아니라 종합한다. "네 findings 기반으로 고쳐"는 금지 — 먼저 소화해 정확한 스펙을 준다.
- 워커는 zero-context로 시작하니 프롬프트는 자기완결적으로 쓴다.
- 워커별로 도구를 제한한다 — 리서처는 write 없음, 구현자는 넓은 search 없음.

## Definition of Done
A feature is done only when ALL true:
- [ ] 목표 동작 구현
- [ ] 검증 실제 실행 (`./init.sh` — Godot import + 테스트, 또는 문서화된 명령)
- [ ] 압축 증거 기록
- [ ] 표준 시작 경로로 재시작 가능한(restartable) 상태

## 세션 종료 (End of Session)
세션을 끝내기 전에 (Before ending a session):
1. `progress.md`에 현재 상태·블로커·다음 단계·압축 증거 갱신
2. `feature_list.json`에 피처 상태·한 줄 증거 갱신
3. 작업이 끊겼거나 크면 `session-handoff.md` 갱신
4. 다음 세션이 `./init.sh`를 바로 돌릴 수 있는 clean restart 상태로 정리

## 출력 (Output)
한국어 우선. 문장은 `:`로 끝내지 않는다. 보고 순서 — 무엇이 / 왜 / 영향 / 모호함 / 다음 이슈.
