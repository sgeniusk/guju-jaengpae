# feat-037 — Phase 7 밸런스·릴리스 준비

## 목표
Phase 7은 제품 루프가 끝까지 돈 뒤 최종 릴리스 전에 수치와 발행 경로를 잠근다. G078은 난이도 곡선, 보상 풀, 상점 가격, trait·edict·scheme·treasure 값을 하나의 밸런스 계약으로 고정하고, G079는 민감정보 없는 macOS Desktop export preset과 pack export 경계를 고정한다. G083은 full app export가 실행되고 export 앱이 첫 전투까지 도달하는지 검증한다. G084는 알려진 리스크와 미지원 범위를 릴리스 후보 문서에 고정한다.

## G078 세부 기준
- 난이도 곡선은 선형 구조를 유지하되 `StageCadence.DIFFICULTY_STEP = 0.10`으로 둔다.
- 기준 배율은 stage 1 = 1.00, stage 5 = 1.40, stage 15 = 2.40이다.
- 왕의 칙령은 군세 공격 +10%, 재정 골드 +20%, 축성 성 HP +15%로 둔다.
- 둔전은 비용 3, 전투 중 골드 생산 1/sec로 둔다.
- 망루는 비용 4, 인접 오라 공격 +10%, 반경 1로 둔다.
- 징발은 비용 4, 즉시 골드 +6으로 둔다. 상점 구매 후 큰 즉시 차익을 만들지 않게 `value <= cost + 2`를 유지한다.
- 보패 기본값은 병법서 비용 5, 공격 +10%, stack_limit 2; 금인 비용 4, 골드 +20%; 천리안 비용 4, 보상 후보 +1로 둔다.
- trait 수치는 이번 단계에서 새로 바꾸지 않는다. 인덕 HP +15%, 호패 기병 공격 +25%, 수전 궁병/수군 공격 +20%를 기존 구현값으로 유지한다.
- 보상 풀 정책은 기본 전리 타입 general/troop/scheme/treasure와 보패 stack_limit, profile unlock 조건을 유지한다.
- 새 nation id, 신규 카드 Resource, 저장 payload, BattleSim 승패 공식은 변경하지 않는다.

## G079 세부 기준
- 우선 export 타깃은 macOS desktop이다.
- `export_presets.cfg`는 repo 루트에 두고, 민감정보 없는 preset만 추적한다.
- 인증서, Apple ID, notarization password, encryption key 같은 비밀은 `export_presets.cfg`에 넣지 않는다. Godot의 민감한 export credentials는 `.godot/export_credentials.cfg` 경계에 둔다.
- `.gitignore`는 `export_presets.cfg`를 숨기지 않고, `build/` 산출물과 `.godot/` 로컬 상태를 계속 숨긴다.
- 기본 preset 이름은 `macOS Desktop`, platform은 `macOS`, export path는 `build/macos/guju-jaengpae.zip`이다.
- 리소스 export는 `all_resources`를 사용하되, 보고용 스크린샷 묶음 `docs/reports/**`, 테스트 `test/**`, 개발 도구 `tools/**`는 제외한다.
- full app export는 로컬 export templates가 필요하므로 G083 실행 증거로 닫았다. G079는 preset 파싱과 pack export 경계만 검증한다.

## G081 세부 기준
- 릴리스 체크리스트는 `docs/release-checklist.md`에 둔다.
- 앱 버전은 export preset의 `0.7.0`과 맞추고, tag 후보는 `v0.7.0-rc1`로 준비한다.
- 최종 태그 후보는 `v0.7.0`이지만 G082 fresh clone, G083 full app export, G084 리스크 문서화가 끝난 뒤에만 만든다.
- 실제 `git tag`, `git push`, GitHub release 생성은 사용자 확인 전 실행하지 않는다.
- 체크리스트에는 `jq`, `progress.md` 줄 수, `git diff --check`, `./init.sh`, pack export, fresh clone, full app export, known risk 게이트가 있어야 한다.

## G082 세부 기준
- G082 fresh clone 검증은 원격 push 없이 로컬 `main` HEAD를 별도 임시 디렉터리에 `git clone --no-hardlinks`로 복제해 수행한다.
- 검증 대상 클론은 clean checkout 상태여야 하며, 원본 작업트리의 `.godot/` import cache나 dirty file에 의존하지 않는다.
- fresh clone 안에서 `./init.sh`를 실행해 Godot import, 카드/군주 validator, 부팅 스모크, UI 피드백 스모크, 단위 테스트가 green임을 확인한다.
- 성공 증거는 clone 경로, HEAD short hash, 카드 수, 단언 수로 남긴다.

## G083 세부 기준
- G083 full app export는 Godot 4.6.3 export templates가 설치된 로컬 환경에서 `godot --headless --path . --export-release "macOS Desktop" build/macos/guju-jaengpae.zip`로 실행한다.
- macOS universal export에 필요한 `rendering/textures/vram_compression/import_etc2_astc=true`를 프로젝트 설정에 둔다.
- release export 안에서는 Resource 디렉터리 항목이 `.tres.remap`으로 보일 수 있으므로 카탈로그 로더는 원본 `.tres` 경로로 정규화해 로드한다.
- export 실행 smoke는 `GUJU_EXPORT_SMOKE=first_battle` 환경변수에서만 동작하며, 일반 플레이 경로에는 영향이 없어야 한다.
- smoke는 lord_select → run_map → battle 경로를 지나 시작 손패 유닛을 보드에 놓고 stage 1 첫 전투 시작 후 `GUJU_EXPORT_SMOKE first_battle_reached` marker와 종료 코드 0을 남겨야 한다.

## G084 세부 기준
- 알려진 리스크와 미지원 범위는 `docs/release-risks.md`에 둔다.
- 문서는 지원 기준, 미지원·보류 범위, 운영 리스크, 태그 전 stop condition을 구분한다.
- 천계·마계 6국 playable 확장, 온라인 멀티플레이, notarization/signing, GitHub release 생성, 장기런 수동 QA, 고급 애니메이션, 최종 사운드 디자인은 현재 릴리스 후보의 미지원·보류 범위로 명시한다.
- full app export 산출물, Godot export templates 의존성, `.tres.remap` export 로더 경계, macOS headless 경고, ObjectDB/resource 종료 경고, 사용자 확인 전 push/tag 금지를 운영 리스크로 명시한다.
- `docs/release-checklist.md`는 G084 완료와 리스크 문서 링크를 표시한다.

## 비범위
- G078 범위에서는 export preset 생성과 실제 export 실행을 하지 않는다.
- G079 범위에서는 playable `.app`/`.zip` full export 실행을 하지 않는다.
- GitHub release 게시문 최종본.
- 사용자 확인 없는 실제 tag 생성과 push.
- 천계·마계 nation id와 군주·카드 Resource 추가.
- 장기런 수동 QA에서 나온 후속 수치 재조정.

## 검증
- `test_balance.gd`는 난이도 곡선, 칙령, 건물, 징발, 보패 수치 계약을 한곳에서 검증한다.
- `test_stage_cadence.gd`는 새 0.10 난이도 스텝을 기존 캐이던스 회귀와 함께 검증한다.
- `test_run_board.gd`, `test_building_economy.gd`, `test_shop.gd`, `test_run_map.gd`는 새 edict/building/shop/difficulty 기대값을 기존 런 흐름 속에서 검증한다.
- `test_export_preset.gd`는 macOS preset 이름, platform, export path, resource filter, docs/test/tools 제외, bundle id, credential-free signing/notarization fields를 검증한다.
- `godot --headless --path . --export-pack "macOS Desktop" build/macos/guju-jaengpae.pck`는 preset을 사용해 pack export 경로가 동작하는지 확인한다.
- `docs/release-checklist.md`는 태그 후보, 사용자 확인 게이트, preflight 명령, G082~G084 선행 조건을 문서화한다.
- fresh clone 검증은 로컬 임시 클론에서 `./init.sh` 전체 green을 확인한다.
- full app export 검증은 `build/macos/guju-jaengpae.zip` 생성과 export 앱 `GUJU_EXPORT_SMOKE first_battle_reached` marker를 확인한다.
- `docs/release-risks.md`는 지원 기준, 미지원·보류 범위, 운영 리스크, 태그 전 stop condition을 문서화한다.
- `./init.sh` 전체 green으로 카드 validator, 부팅 스모크, UI 피드백 스모크, 보스/결과 스모크, 단위 테스트를 함께 확인한다.
