# feat-036 — Phase 6 UX·피드백·아트

## 목표
Phase 6은 신규 플레이어가 첫 전투와 첫 보상 루프를 막힘 없이 이해하도록 UI 피드백과 전장 표현을 보강한다. G071~G077은 nation id나 신규 Resource 승인 없이 가능한 tooltip, walk 시트, 배경 테마, 최소 오디오, 첫 전투 온보딩, 눈에 띄는 placeholder 감소, UI 스크린샷 증거 묶음을 먼저 닫는다.

## G071 세부 기준
- 군주 선택 버튼은 해금 상태와 새 런 시작/해금 조건을 tooltip으로 알려준다.
- 저장 런 이어하기 버튼은 현재 저장 런을 불러온다는 의미를 tooltip으로 알려준다.
- 런맵 stage 요약은 보드, 손패, 골드, 난이도 정보의 의미를 tooltip으로 알려준다.
- 전투 시작, 상점 떠나기, 사건 보상, 칙령 선택 버튼은 선택 후 다음 경로를 tooltip으로 알려준다.
- 상점 카드 버튼은 카드 타입, 구매 후 경로, 전투/런 효과, 설명, 구매 가능 여부를 tooltip으로 보여준다.
- 손패 초과 안내는 권장 손패 수와 다음 전투 배치/우물 정리 경로를 tooltip으로 보여준다.
- 전투 배치 손패 버튼은 카드 타입별 다음 행동을 구분한다. 장수·병종·건물은 빈 타일 배치, 계략은 계략 발동, 보패는 즉시 장착 경로를 안내한다.
- 전투 배치의 계략, 우물, 전투 시작 버튼은 선택 카드와 현재 phase에 따라 왜 사용할 수 있는지/없는지 tooltip을 갱신한다.
- 보드 요약과 타일 라벨은 배치된 카드의 타입·경로·효과를 tooltip으로 보여준다.

## G072 세부 기준
- 기존 정적 유닛 PNG에서 4프레임 walk strip을 재현 가능하게 생성하는 도구를 둔다.
- 기존 `shu/infantry_walk.png`는 보존하고, 누락된 주요 유닛 시트만 추가한다.
- 우선 대상은 현세 3국의 주요 병종, 현재 카드화된 장수, 보스 3종이다.
- 생성되는 시트는 `<unit>_walk.png` 네이밍과 가로 4분할 계약을 따른다.
- Godot `.import` 파일은 실제 게임 에셋이므로 원본 PNG와 함께 추적한다.
- 보스 렌더는 display_name 기준으로 동탁·장각·여포의 보스별 정적/워크 에셋을 고른다. 매핑 실패 시 기존 동탁 fallback을 유지한다.
- 전투 로직, BattleSim 결정성, 스킬 수치는 바꾸지 않는다.

## G073 세부 기준
- 기존 `assets/sprites/bg/*/field.png` 배경을 `BattlefieldTheme` 레지스트리에 등록한다.
- 기본 현세 전장은 `plain`, 천계 realm 슬롯은 `heaven`, 마계 act 전장은 `demon`으로 선택된다.
- 보스 stage 5/10/15는 각각 `luoyang`/`plague`/`wanyao` 배경을 사용한다.
- 전투 씬은 현재 stage와 군주 realm으로 배경을 고르고, 테마별 아이소 타일 경로를 사용한다.
- `tools/generate_realm_backgrounds.py`는 기존 평원 배경에서 천계 배경 슬롯을 재생성한다.
- 신규 heaven 배경은 realm 표현 슬롯일 뿐이며, 미승인 천계 nation id나 군주 Resource를 추가하지 않는다.
- 전투 로직, WaveFactory 파도, BattleSim 결정성은 바꾸지 않는다.

## G074 세부 기준
- 최소 BGM 1종과 SFX 5종을 재생 가능한 WAV 에셋으로 둔다.
- `tools/generate_audio_placeholders.py`는 현재 최소 WAV 세트를 재생성할 수 있어야 한다.
- `AudioManager` autoload는 BGM/SFX id와 경로를 한곳에서 관리하고, 누락된 에셋은 false로 폴백한다.
- lord_select/run_map/battle은 화면 진입, 새 런/전투 시작, 구매·골드 획득, 승리, 패배에 최소 cue를 재생한다.
- 오디오 추가는 전투 로직, 저장 payload, BattleSim 결정성을 바꾸지 않는다.

## G075 세부 기준
- stage 1 run_map은 첫 전투임을 화면 문구로 알리고, 전투 화면에서 손패 선택 → 빈 타일 배치 → 전투 시작 순서로 진행한다고 알려준다.
- battle 배치 패널은 처음 온 플레이어도 행동 순서를 읽을 수 있도록 손패 선택, 빈 타일 클릭, 전투 시작, 승리 후 보상 선택을 한 줄 안내로 보여준다.
- 보드가 비어 있을 때 전투 시작 버튼 tooltip과 보드 요약은 손패를 먼저 선택하고 빈 타일을 클릭하라고 알려준다.
- 손패 선택, 타일 미선택, 배치 성공 피드백은 다음 행동이 전투 시작인지 계략 발동인지 화면 문구로 이어준다.
- 일반 승리 보상 overlay는 “한 장 선택” 제목, 카드 버튼을 누르면 보상이 적용된다는 안내, `선택`으로 시작하는 보상 버튼을 보여준다.
- 패배와 최종 승리 overlay는 보상 드래프트 문구를 노출하지 않는다.
- 온보딩 보강은 전투 로직, 저장 payload, BattleSim 결정성을 바꾸지 않는다.

## G076 세부 기준
- `StageCadence`가 화면에 노출하는 combat/shop/boss/expand/edict/elite/event node kind는 모두 `assets/sprites/ui/node_<kind>.png` 텍스처를 가진다.
- G066 이후 추가된 칙령, 정예, 사건 node icon은 `tools/generate_ui_node_icons.py`로 재생성 가능하다.
- battle HUD의 왼쪽 능력 버튼은 실제 `ability_well`/`ability_focus`/예약 아이콘을 우선 사용하고, 아이콘이 없을 때만 글자 fallback으로 돌아간다.
- 예약 능력 슬롯은 숫자 placeholder 대신 비활성 아이콘으로 표시한다.
- fallback 경로 자체는 유지하되, 현 제품 화면의 기본 자산 상태에서는 텍스트/단색 placeholder가 주요 HUD에 노출되지 않아야 한다.
- placeholder 감소는 전투 로직, 저장 payload, BattleSim 결정성을 바꾸지 않는다.

## G077 세부 기준
- `tools/shoot_ui_bundle.sh`는 기본 출력 경로 `docs/reports/phase6-ui-screens/`에 제품 화면 스크린샷 묶음을 남긴다.
- 묶음은 군주 선택, 위·촉·오 run_map stage 1/3/4/5, 위·촉·오 battle deploy/fight stage 5, 위·촉·오 shop stage 4, 패배 결과 stage 3, 최종 승리 결과 stage 15를 포함한다.
- `tools/validate_screenshot_bundle.py`는 핵심 24개 PNG의 존재, PNG 디코딩, 최소 1280x720 해상도, 비어 있지 않은 화면을 검증한다.
- 결과 화면 촬영 과정에서 생기는 추가 deploy PNG는 유지해도 되지만, 검증 계약에는 핵심 24개만 포함한다.
- `docs/reports/**/*.import` ignore 정책은 유지하고, 실제 증거 PNG와 README만 보고 묶음으로 남긴다.
- 스크린샷 묶음 추가는 전투 로직, 저장 payload, BattleSim 결정성을 바꾸지 않는다.

## 비범위
- 별도 모달 튜토리얼 overlay, 강제 guided first-run flow.
- 수작업 신규 원화 제작, 상용 오디오, 최종 믹싱.
- 최종 밸런스 수치 조정.

## 검증
- `test_card_ui_text.gd`는 공통 카드 tooltip이 타입, 획득/사용 경로, 효과, 설명을 함께 담는지 검증한다.
- `test_lord_select.gd`는 해금/잠김 군주 버튼 tooltip이 새 런 시작과 해금 조건을 표시하는지 검증한다.
- `tools/ui_feedback_smoke.gd`는 lord_select, run_map 첫 전투/상점/칙령/사건, battle 배치 패널과 일반 승리 보상 overlay를 실제 씬으로 띄우고 필수 문구와 tooltip을 수집한다.
- `test_unit_walk_visuals.gd`는 3국 핵심 장수와 보스별 walk 시트가 `AnimatedSprite2D`로 로드되고, 보스별 텍스처 매핑이 맞는지 검증한다.
- `test_battlefield_theme.gd`는 모든 등록 배경과 타일 경로가 존재하고, realm/stage별 테마 선택이 맞는지 검증한다.
- `test_audio_manager.gd`는 등록된 BGM/SFX id, 경로, 로드 가능성을 검증한다.
- `test_hud_state.gd`는 모든 stage ladder node kind에 실제 UI 아이콘이 있는지 검증한다.
- `test_unit_walk_visuals.gd`는 능력 버튼이 아이콘 에셋을 찾으면 글자 fallback을 제거하고 TextureRect를 붙이는지 검증한다.
- `tools/shoot_ui_bundle.sh`는 `docs/reports/phase6-ui-screens/`에 26 PNG를 생성한다.
- `tools/validate_screenshot_bundle.py docs/reports/phase6-ui-screens`는 핵심 24개 PNG가 존재하고 비어 있지 않은지 검증한다.
- `init.sh`는 UI 툴팁/피드백 스모크를 전체 검증에 포함한다.
- `./init.sh` 전체 green으로 카드 validator, 기존 부팅 스모크, UI 피드백 스모크, 단위 테스트를 함께 확인한다.
