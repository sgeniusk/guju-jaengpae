# CLAUDE.md — 삼국지: 구주쟁패 (九州爭霸)

세션 시작 시 Claude Code가 읽는 프로젝트 기억이다. 에이전트-중립 규칙은 [AGENTS.md](AGENTS.md), 세계관 정본은 [docs/worldview.md](docs/worldview.md)를 본다.

## Project identity
삼국지 기반 **풀 판타지 덱빌딩 로그라이크 오토배틀러**. *Nine Kings* 벤치마크, 엔진은 **Godot 4.x (GDScript)**.
세계관 한 줄 — 정사는 위·촉·오 3국의 싸움으로 알지만, 실제로는 三界(현세·천계·마계)에 각 3국, 도합 **九州(9세력)**가 패권을 다툰다. 봉신연의풍 환상이 정사·연의에 겹친다.

**v0.1 성공 기준** — 군주 하나로 시작해 장수 3종·병종 3종 카드를 레인에 배치하면 **자동 교전(오토배틀)**으로 적 파도 한 번을 막고, 승리 시 카드 한 장을 보상으로 골라 덱에 편입하는 최소 플레이 가능 빌드. Godot에서 실제로 한 판이 돈다.

## 역할 경계 — 멀티 CLI 분업
| CLI | 자리 | 맡는 일 |
|---|---|---|
| Claude (나) | 편집장 | 정본·스펙·계획, 세계관·카드 온톨로지, 톤, 오케스트레이션 |
| Codex CLI | 구현자 | 잘 정의된 스펙 구현(GDScript·씬), 리팩토링, PR, lint/test |
| Antigravity (agy) | 교차검증자 | 다른 모델로 산출물 적대적 검증, 플레이 QA·스크린샷 |

기본 흐름 — 나(스펙·정본) → Codex(구현·PR) → agy(교차검증) → 나(정본 반영·CHANGELOG).
Claude는 "왜 이렇게 구성되는지 설명하고 정본화하는 자리"에 머문다. 대규모 GDScript 자동화·CI·익스포트는 Codex에 넘긴다.

## Context Budget
점진적 공개를 쓴다. 시작 시 이 파일·`feature_list.json`·`progress.md`의 현재/다음 섹션만 읽는다. `docs/worldview.md`·`session-handoff.md`·깊은 설계 문서·긴 로그는 해당 피처가 필요할 때만 연다.
루트 파일을 작게 유지한다 — 오래된 증거는 `CHANGELOG.md`나 docs/reports로 옮긴다.

## Startup Workflow
1. `pwd`로 작업 디렉토리 확인
2. 이 파일 완독
3. 선택한 피처에 필요한 docs만 읽기 (카드·전투 작업이면 `docs/worldview.md`)
4. `./init.sh`로 환경 검증 (Godot)
5. `feature_list.json`에서 활성/준비된 피처 하나 선택
6. `progress.md`에서 현재 상태·블로커·다음 단계 확인
베이스라인 검증이 깨져 있으면 새 작업 전에 그것부터 고친다.

## 자율성 — 가정-후-표시
- 되돌릴 수 있는 행동(파일 생성, 브랜치 내 작업)은 묻지 않고 합리적 기본값으로 진행한다.
- 가정한 지점은 끝에 "가정한 것" 목록으로 모아 보고하고, 사용자가 일괄 수정한다.
- 블로킹 질문은 되돌리기 어려운 결정(push·삭제·외부 발행·비용)에만.

## Working Rules
- 한 번에 한 피처 — `feature_list.json`에서 미완 피처 정확히 하나 선택
- 검증 필수 — `./init.sh` 안 돌리고 done 주장 금지
- 종료 전 `progress.md`·`feature_list.json` 갱신
- 스코프 유지 — 현재 피처와 무관한 파일 수정 금지
- 상태는 압축 — 루트 상태 파일엔 전체 로그가 아니라 요약만
- push·force·브랜치 삭제는 사용자 확인 후에만

## Writing style
- 한국어 우선. 중요한 기술 용어는 영어 병기 가능.
- 한국어 문장은 `:`로 끝내지 않는다 — 종결은 `.`, `?`, `!`만.
- 비-자명한 새 파일(씬 스크립트·카드 Resource·도메인 로직)은 한 줄 한국어 헤더로 시작.
- 간결한 Markdown.

## Definition of Done
- [ ] 목표 동작 구현됨
- [ ] 필수 검증 실제로 돌림 (`./init.sh` — Godot import + 테스트)
- [ ] `feature_list.json`/`progress.md`에 압축된 증거 기록
- [ ] 오래된 디테일은 docs/reports로 링크
- [ ] 표준 시작 경로로 재시작 가능한 상태

## End of Session
1. `progress.md`에 현재 상태·블로커·다음 단계·압축 증거 갱신
2. `feature_list.json`에 피처 상태·한 줄 증거 갱신
3. 작업이 끊겼거나 너무 크면 `session-handoff.md` 갱신
4. 큰 로그·스크린샷·이력은 docs/reports로 이동
5. 다음 세션이 `./init.sh`를 바로 돌릴 수 있게 정리

## When editing — 보고 순서
무엇이 바뀜 / 왜 / 영향 모듈 / 남은 모호함 / 다음 이슈 제안(`[모듈]` 프리픽스).
구조 변경(새 씬·새 시스템·개념 개명)은 `CHANGELOG.md`에 기록한다.
