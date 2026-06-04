# 구주쟁패 (九州爭霸) / Nine Provinces

삼국지 기반 풀 판타지 덱빌딩 로그라이크 **오토배틀러**. *Nine Kings* 벤치마크. 엔진 **Godot 4.x**.
세계관 — 三界(현세·천계·마계) × 3국 = **九州(9세력)**의 패권 다툼. 현세는 위·촉·오.

상태 — **v0.6 + Phase 1 sanity + Phase 2 카드 시스템 완료, Phase 3 완료, Phase 4 게이트 진행, Phase 5 완료, Phase 6 완료, Phase 7 진행 (2026-06-04).** 현세 3국 군주 선택, 보드 배치, 오픈필드 성 방어 전투, 보상, 상점, 땅 확장, 왕의 칙령, 위·오 trait/장수 스킬, 촉 보병 walk 애니메이션까지 동작한다. 위·촉·오 첫 보스 런 플로우와 첫 5스테이지 UI 흐름은 22 PNG 스크린샷으로 확인했다. 계략·보패 카드 시스템은 실제 효과와 UI 구분까지 닫혔고, Phase 3는 `PersistenceStore`와 `RunManager` 경계의 ConfigFile 런/프로필 저장·재개·영구 해금 계약까지 닫았다. Phase 4는 9세력 확장을 명칭 승인 → `docs/worldview.md` → `CardVocab.NATIONS`/validator → Resource → lord_select 순서로 진행하도록 게이트를 추가했고, `lord_select`는 3군주 고정 배열 대신 unlock-aware 카탈로그 UI로 전환했다. Phase 5는 `WaveFactory.stage_waves`를 act-aware 템플릿 구조로 확장했고, stage 5 동탁·10 장각·15+ 여포 보스, 정예/사건 node_kind, stage 15 최종 보스 결과, 첫 15스테이지 런 믹스, 보스별 순수 시뮬레이션/부팅 스모크, 패배/최종 승리 결과 화면 스모크를 잠갔다. Phase 6은 G071로 군주 선택, 런맵, 상점, 칙령, 사건, 전투 배치 손패/우물/계략/보드의 최소 tooltip과 피드백을 붙였고, G072로 주요 병종·장수·보스 walk 시트 26개와 보스별 렌더 매핑을 채웠으며, G073으로 평원/realm/보스 stage 배경 테마와 테마별 아이소 타일을 연결했고, G074로 최소 BGM/SFX와 `AudioManager` 재생 경로를 붙였으며, G075로 첫 전투 시작과 일반 승리 보상 선택 안내를 실제 화면 문구로 잠갔고, G076으로 HUD 노드/능력 버튼 placeholder를 실제 아이콘으로 대체했고, G077로 `docs/reports/phase6-ui-screens/`에 제품 화면 26 PNG 묶음과 검증 도구를 남겼다. Phase 7 G078은 난이도 step 0.10, 칙령 10/20/15%, 둔전·망루·징발·보패 수치 계약을 `test_balance.gd`로 잠갔고, G079는 credential-free `macOS Desktop` export preset과 pack export 경로를 추가했으며, G080~G081은 릴리스 기준 문서와 태그 체크리스트를 준비했고, G082는 로컬 fresh clone에서 `./init.sh` green을 확인했다. `./init.sh`는 카드 **22개**와 **2349 단언 green**이다.

현재 발행 상태 — 로컬 `main`은 `origin/main`보다 6커밋 앞서 있다. `git push origin main`은 사용자 확인 후에만 실행한다.

## 새 세션에서 시작하는 법
1. 이 폴더에서 새 Codex 또는 Claude 세션을 연다.
2. `AGENTS.md`·`CLAUDE.md`·`session-handoff.md`를 읽는다.
3. `./init.sh`로 baseline을 확인한다.
4. `feature_list.json`과 `progress.md`에서 다음 피처를 하나만 고른다.
5. 새 피처는 `docs/specs/feat-0XX.md`를 먼저 쓰고, 구현 후 `./init.sh` green 증거로 닫는다.

## 다음 개발 축
- Phase 0 — v0.6 발행·문서·import 정책 baseline. push는 사용자 확인 대기.
- Phase 1 — 위·촉·오 3국 베타 sanity pass와 시각 QA 루틴 완료.
- Phase 2 — 계략(計略)·보패(寶貝) 카드 시스템 완료. `feat-032` 카드 계약, 계략 손패 발동 경계, `SchemeCatalog`, 보패 `RunState.treasures` 소유권, `TreasureCatalog`, 카드 타입별 `RewardPool` 정책, scheme/treasure validator, 초기 카드 3+3종, 실제 런·전투·보상 효과 적용, UI 혼동 방지를 연결했다.
- Phase 3 — ConfigFile 저장·재개·영구 해금 완료. G045~G053에서 `PersistenceStore`와 기본 저장 경로, `RunState`/`ProfileState` primitive payload, `save_version` 버전 처리, `ProfileState` 해금·기록·설정 API, 전투 결과 화면의 기록/해금/새 런 경로, 런 autosave/이어하기, 신규/호환/미래 버전 테스트, unlock-aware 보상/군주 선택, 프로필 저장/로드와 저장 I/O 경계를 고정했다.
- Phase 4 — 9세력 확장 진행. G054에서 명칭 승인 → 세계관 정본 → `CardVocab.NATIONS`/validator → Resource → lord_select 순서 게이트를 스펙과 테스트로 잠갔고, G057에서 `lord_select`를 카탈로그 기반 군주 목록으로 바꿨다.
- Phase 5 — act·보스 구조 완료. G064에서 `WaveFactory`가 5스테이지 단위 act-aware 파도 템플릿을 고르고, G065에서 동탁·장각·여포 보스 3종의 target_rule·스킬·호위 파도를 분리했다. G066에서 stage 7 정예, stage 11 사건 node_kind와 run_map/HUD 표시를 추가했고, G067에서 stage 15 최종 보스 승리 조건을 확정했다. G068에서 stage 1~15 런 믹스 회귀를, G069에서 보스별 순수 시뮬레이션과 battle.tscn 부팅 스모크를, G070에서 패배/최종 승리 결과 화면 스모크를 잠갔다.
- Phase 6 — UX·아트·오디오 완료. G071에서 `CardUiText.tooltip`, 군주/런맵/상점/칙령/사건/전투 배치 tooltip, 손패 초과/우물/계략/보패 피드백 경로, `tools/ui_feedback_smoke.gd`를 추가했다. G072에서 `tools/generate_walk_sheets.py`와 주요 `_walk.png` 시트 26개, 동탁·장각·여포 보스별 렌더 매핑과 walk 회귀 테스트를 추가했다. G073에서 `BattlefieldTheme`가 realm/stage별 배경과 아이소 타일을 선택하고, `tools/generate_realm_backgrounds.py`로 천계 배경 슬롯을 재생성한다. G074에서 `tools/generate_audio_placeholders.py`, `AudioManager`, 기본 battle BGM과 UI/골드/전투 시작/승리/패배 SFX를 추가했다. G075에서 첫 전투 run_map 안내, battle 배치 순서 안내, 일반 승리 보상 선택 안내를 smoke로 검증한다. G076에서 `node_edict`/`node_elite`/`node_event`와 능력 버튼 아이콘 경로를 채웠다. G077에서 `tools/shoot_ui_bundle.sh`와 `tools/validate_screenshot_bundle.py`를 추가해 `docs/reports/phase6-ui-screens/` 26 PNG 묶음을 남겼다.
- Phase 7 — 밸런스·릴리스 진행. G078에서 `docs/specs/feat-037.md`와 `test_balance.gd`를 추가하고, 난이도 곡선·edict·건물 경제·징발·보패 수치를 통합 계약으로 잠갔다. G079에서 `export_presets.cfg`와 `test_export_preset.gd`를 추가하고 macOS pack export를 검증했다. G080에서 `CHANGELOG.md`, `docs/worldview.md`, `assets/MANIFEST.md`, handoff/status 문서를 릴리스 기준으로 동기화했고, G081에서 `docs/release-checklist.md`에 태그 후보와 릴리스 게이트를 준비했다. G082에서 로컬 fresh clone `./init.sh` green을 확인했다. 다음은 full app export와 리스크 문서화다.

## 파일
- `CLAUDE.md` / `AGENTS.md` — 하네스 지침 (Claude 전용 / 3 CLI 공유 계약)
- `feature_list.json` / `progress.md` / `session-handoff.md` — 상태
- `init.sh` — Godot 검증 스크립트
- `docs/reports/phase6-ui-screens/` — G077 제품 화면 스크린샷 묶음
- `docs/release-checklist.md` — G081 태그·릴리스 체크리스트
- `docs/specs/feat-037.md` — Phase 7 밸런스·릴리스 준비 스펙
- `export_presets.cfg` — G079 macOS Desktop export preset
- `docs/worldview.md` — 세계관·카드 스키마 정본
- `.omx/plans/prd-guju-completion-plan-20260604T074118Z.md` — v1.0 완성 PRD
- `.omx/plans/test-spec-guju-completion-plan-20260604T074118Z.md` — v1.0 테스트 스펙
- `game-concept.md` — 기획 시드 (결정 확정 반영됨)

## 분업
- Claude — 편집장. 정본·스펙·계획.
- Codex — 구현자. 게임 로직·씬·테스트.
- agy — 교차검증자. 다른 모델로 QA.
