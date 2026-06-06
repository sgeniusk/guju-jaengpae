# CHANGELOG — 삼국지: 구주쟁패 (九州爭霸)

구조 변경(새 씬·새 시스템·개념 개명·정본 결정)을 기록한다. 일상 진행은 `progress.md`.

## 2026-06-06 — feat-069 스크린샷 validator 속도 최적화
PIL 없이 동작하는 screenshot bundle validator의 기본 경로를 빠른 PNG 검사로 바꿨다.
- **fast PNG mode** — 기본 검증은 PNG signature/chunk/IHDR/IDAT, 최소 해상도, 압축 스트림 샘플 다양성을 확인한다.
- **deep PNG mode 유지** — 기존 행 unfilter 기반 픽셀 복원 검사는 `--png-mode deep`으로 남겨 필요할 때 더 강한 검사를 실행할 수 있다.
- **검증 속도 표시** — 성공 메시지가 사용한 PNG mode를 함께 출력해 fast/deep 결과를 구분한다.
- **검증** — `/tmp/guju-feat-068-ui` 11장 기준 fast 0.18초, deep 32.67초 모두 통과. `./init.sh` 카드 22개, 단위 테스트 2983/2983 green.

## 2026-06-06 — feat-068 첫 보드 스크린샷 QA 갱신
첫 전투 배치 보드의 핵심 4상태가 durable screenshot bundle에도 남도록 QA 하네스를 보강했다.
- **첫 보드 전용 촬영** — `tools/shoot_first_board_states.gd`가 성 선택 전 `성 후보`, 성 선택 후 `손패 선택`, 계략 선택 후 `계략 버튼`, 병종 선택 후 `배치 가능` 상태를 차례로 PNG로 저장한다.
- **Bundle 연결** — `tools/shoot_ui_bundle.sh`가 군주 선택 촬영 뒤 첫 보드 4장을 함께 생성하고, `FIRST_BOARD_LORD`/`FIRST_BOARD_STAGE`로 대상 런을 바꿀 수 있게 했다.
- **stdlib PNG validator** — `tools/validate_screenshot_bundle.py`가 첫 보드 4장을 필수 파일로 요구하고, PIL 의존성 없이 PNG signature/chunk/해상도/투명도/색상 수를 검사한다.
- **검증** — `/tmp/guju-feat-068-ui` 최소 bundle 11장 검증 통과, `./init.sh` 카드 22개, 단위 테스트 2983/2983 green.

## 2026-06-06 — feat-067 첫 전투 보드 가독성 polish
첫 전투 배치 보드의 빈 칸이 현재 할 일을 직접 말하도록 label과 tooltip을 보강했다.
- **성 후보 안내** — 성 위치를 고르기 전 빈 타일은 `성 후보` label과 성 위치 선택 tooltip을 표시한다.
- **손패/계략 상태 안내** — 성 선택 후 손패 미선택 상태는 `손패 선택`, 계략 선택 상태는 `계략 버튼`으로 표시해 계략은 타일이 아니라 버튼으로 쓴다는 점을 말한다.
- **배치 가능 안내** — 유닛/건물 카드를 선택하면 빈 타일이 `배치 가능`과 카드명 포함 tooltip을 보여준다.
- **검증** — `tools/ui_feedback_smoke.gd`가 `성 후보`, `손패 선택`, `계략 버튼`, `배치 가능` 4상태를 확인한다. `./init.sh` 카드 22개, 단위 테스트 2982/2982 green.

## 2026-06-06 — feat-066 전투 유닛 접지감 보강
전투 유닛이 공중에 떠 보이는 느낌을 줄이도록 분대/호위/장수 visual의 발밑 shadow를 보강했다.
- **발밑 ground shadow** — `battle.gd`가 root shadow와 분대/호위 병사별 작은 shadow에 `ground_shadow` meta를 붙이고, 병사 발 위치 근처에 배치한다.
- **장수 본체 위치 보정** — 장수 본체의 위쪽 오프셋을 -18px에서 -10px로 낮추고 본체 발밑 shadow를 추가해 호위병 위에 떠 있는 느낌을 줄였다.
- **수치 불변** — 전투 수치, 이동, 충돌, 승패 조건은 바꾸지 않았다. 렌더 계층만 보정했다.
- **검증** — `tools/ui_feedback_smoke.gd`가 첫 수동 전투 시작 후 ground shadow meta 노드 생성을 확인한다. `./init.sh` 카드 22개, 단위 테스트 2982/2982 green.

## 2026-06-06 — feat-065 전투 화면 정보 밀도 정리
전투 화면 중앙에서 현재 전황을 한 줄로 읽을 수 있도록 top-center HUD를 보강했다.
- **BattleHudState 전황 helper** — `combat_summary()`가 phase, stage, wave, 아군/적 visible soldiers, 속도/정지/auto 상태를 `전황 — ...` 문구와 tooltip으로 순수 계산한다.
- **전투 HUD 요약 라벨** — `battle.gd`가 stage ladder 아래에 전황 라벨을 추가하고 배치/교전/결과 phase마다 최신 병력 수와 속도 상태를 동기화한다.
- **병력 기준 tooltip** — tooltip은 아군/적 숫자가 현재 화면에 살아 있는 병력 수 기준이며, 파도는 이번 교전 묶음의 진행도임을 설명한다.
- **검증** — `test_hud_state.gd`가 helper 문구를 검증하고, `tools/ui_feedback_smoke.gd`가 배치 준비와 첫 교전의 전황 요약 렌더를 확인한다. `./init.sh` 카드 22개, 단위 테스트 2982/2982 green.

## 2026-06-06 — feat-064 장기런 결과 요약 UX
최종 패배와 최종 승리 화면에서 방금 끝난 런의 성과가 보이도록 결산 블록을 추가했다.
- **RunResultSummary helper** — `scripts/run/run_result_summary.gd`가 RunState와 battle outcome으로 `런 결산 — 승리/패배`, 스테이지, 점수, 군세, 최고 Lv, 골드, 칙령/보패/손패/드로우 요약을 순수 계산한다.
- **결과 오버레이 결산** — `battle.gd`가 run_complete 결과에서만 결산 title/detail/progress를 표시한다. 일반 승리의 전리품 흐름은 그대로 유지한다.
- **결산 tooltip** — tooltip에는 군주명, 스테이지, 점수, 군세, 골드, 칙령/보패/손패/드로우 상태가 같이 남는다.
- **검증** — `test_run_result_summary.gd`가 helper 문구를 검증하고, `tools/battle_result_smoke.gd`가 패배/최종승리 결과 화면의 결산 문구와 tooltip을 확인한다. `./init.sh` 카드 22개, 단위 테스트 2972/2972 green.

## 2026-06-06 — feat-063 상점 구매 피드백
상점에서 구매 가능한 카드와 자금 부족 카드를 더 분명하게 구분하고, 구매 뒤 남은 자금과 다음 전투 손패 정리를 visible text로 남겼다.
- **ShopPurchaseFeedback helper** — `scripts/run/shop_purchase_feedback.gd`가 구매 가능/자금 부족 상태, 구매 성공, 구매 실패 문구와 tooltip을 순수 계산한다.
- **상점 카드 상태 줄** — `run_map.gd` 상점 카드가 `구매 가능 — N금, 구매 후 M금` 또는 `자금 부족 — N금 필요, 현재 M금`을 표시한다. tooltip도 현재 자금, 비용, 부족 금액 또는 남은 자금을 설명한다.
- **구매 후 피드백** — 구매 성공 메시지는 `구매 완료`, 사용한 금액, 남은 자금, 다음 전투 후보 3장 정리를 함께 말한다.
- **검증** — `test_shop_purchase_feedback.gd`가 helper 문구를 검증하고, `tools/ui_feedback_smoke.gd`가 고자금 상점, 저자금 상점, 구매 완료 문구를 확인한다. `./init.sh` 카드 22개, 단위 테스트 2946/2946 green.

## 2026-06-06 — feat-062 런맵 진행 리듬 안내
런맵에서 현재 스테이지가 어떤 행동을 요구하고, 앞으로 어떤 노드가 이어지는지 바로 읽히도록 진행 리듬 안내를 추가했다.
- **RunFlowSummary helper** — `scripts/run/run_flow_summary.gd`가 현재 stage의 준비 행동과 앞으로 3스테이지의 전투/칙령/상점/보스 리듬을 순수 계산한다.
- **런맵 공통 안내** — `run_map.gd`가 전투, 칙령, 상점, 사건 화면 모두에서 `진행 리듬 — 현재 ...`, `현재 행동`, `다음 흐름: ...`을 표시한다.
- **검증** — `test_run_flow_summary.gd`가 전투/상점/최종 보스/비정상 stage 보정 문구를 검증하고, `tools/ui_feedback_smoke.gd`가 첫 전투와 상점 화면의 진행 리듬 및 tooltip을 확인한다. `./init.sh` 카드 22개, 단위 테스트 2920/2920 green.

## 2026-06-06 — feat-061 전투 결과 복귀 안내
전투 결과 화면에서 현재 런을 계속하는 경로와 현재 런을 끝내고 새 런으로 돌아가는 경로를 더 분명히 구분했다.
- **BattleOutcomeGuide helper** — `scripts/battle/battle_outcome_guide.gd`가 패배, 최종 승리, 일반 승리의 `런 종료`/`런 계속` 문구와 새 런/다음 스테이지 tooltip을 순수 계산한다.
- **결과 오버레이 안내** — `battle.gd`가 결과 패널에 `런 종료 — 성이 함락되었습니다`, `런 종료 — 구주 정복 완료`, `런 계속 — 전리품을 고르고 런맵으로 복귀` 안내를 표시한다.
- **버튼 경로 명시** — `다음 스테이지로` tooltip은 현재 런을 유지한다고 말하고, `군주 선택으로 새 런` tooltip은 완료 기록 보존 또는 현재 런 포기를 명시한다.
- **검증** — `test_battle_outcome_guide.gd`, `tools/battle_result_smoke.gd`, `tools/ui_feedback_smoke.gd`가 결과 안내와 tooltip을 검증한다. `./init.sh` 카드 22개, 단위 테스트 2890/2890 green.

## 2026-06-06 — feat-060 상점 손패 정리 안내
상점에서 카드를 산 뒤 현재 손패가 늘어나도 다음 전투는 다시 3장 후보 중 1장을 쓰는 구조가 보이도록 상점 안내를 보강했다.
- **ShopHandSummary helper** — `scripts/run/shop_hand_summary.gd`가 현재 상점 손패 수, 다음 전투 후보 수, refresh pending 여부를 받아 `다음 전투 손패 — 후보 3장 중 1장`과 `상점 손패 4장 → 전투 후보 3장` 같은 문구를 순수 계산한다.
- **상점 패널 안내** — `run_map.gd` 상점 화면이 기존 손패 초과 안내를 교체해 다음 전투 후보 요약과 드로우 더미 tooltip을 항상 표시한다. 구매 직후에는 현재 손패가 늘어난 상태와 다음 배치 후보 3장 규칙을 바로 보여준다.
- **검증** — `test_shop_hand_summary.gd`가 helper 문구를 검증하고, `tools/ui_feedback_smoke.gd`가 상점 화면과 구매 직후 정리 문구를 확인한다. `./init.sh` 카드 22개, 단위 테스트 2868/2868 green.

## 2026-06-06 — feat-059 자동저장 슬롯 삭제 UX
군주 선택 화면에서 이어갈 수 있는 저장과 손상된 저장을 플레이어가 직접 지울 수 있도록 자동저장 슬롯 삭제 UX를 추가했다.
- **저장 삭제 액션** — `lord_select.gd`가 유효한 저장의 `저장된 런 이어하기` 아래, 손상 저장의 복구 안내 아래에 `저장된 런 삭제` 버튼을 표시한다.
- **프로필 보존 안내** — 삭제 버튼 tooltip은 현재 autosave 슬롯만 지우며 군주 해금과 프로필 기록은 유지된다는 점을 명시한다.
- **삭제 후 복구 상태** — 버튼 핸들러는 `RunManager.reset_run()`으로 런 저장과 현재 런 state를 초기화하고 화면을 다시 렌더해 이어하기/삭제 버튼이 사라진 군주 선택 상태로 돌아간다.
- **검증** — `test_lord_select.gd`가 유효 저장/손상 저장의 삭제 버튼과 tooltip을 검증한다. `tools/resume_ux_smoke.gd`는 저장 런 삭제 후 파일 제거, state 초기화, 버튼 제거, 군주 선택 렌더를 확인한다. `./init.sh` 카드 22개, 단위 테스트 2847/2847 green.

## 2026-06-06 — feat-058 다음 배치 손패 미리보기
상점이나 전리품 뒤 손패 수가 늘어도 다음 전투는 다시 3장 후보 중 1장 선택이라는 규칙이 흐려지지 않도록 preview와 안내 문구를 추가했다.
- **Deploy hand preview** — `RunState.deploy_hand_preview()`가 다음 `prepare_deploy_hand()` 결과를 비파괴적으로 계산한다. `RunManager.get_deploy_hand_preview()`와 `deploy_hand_refresh_pending()`이 UI에서 이 상태를 읽게 한다.
- **런맵 준비 요약 보정** — `run_map.gd`의 전투 준비 패널이 현재 손패가 아니라 다음 배치 preview 손패를 기준으로 증원/배치/계략 후보를 계산한다. 현재 손패 수와 preview 수가 다르면 `다음 손패 X→3` 정리 문구를 보여준다.
- **결과 오버레이 안내** — `battle.gd`의 다음 준비 안내와 다음 스테이지 버튼 tooltip에 `다음 배치 손패 — 후보 3장 중 1장`, `드로우 더미로 돌아가고` 문구를 추가했다.
- **검증** — `test_deploy_hand_preview.gd`가 preview가 상태를 변형하지 않고 실제 prepare 결과와 일치하는지 검증한다. `test_run_prep_summary.gd`는 손패 정리 문구를, `tools/ui_feedback_smoke.gd`는 보상 후 다음 배치 손패 안내를 확인한다. `./init.sh` 카드 22개, 단위 테스트 2839/2839 green.

## 2026-06-06 — feat-057 런맵 전투 준비 패널 강화
전투 시작 전 런맵에서 이번 교전의 선택 구조를 읽을 수 있도록 준비 요약을 추가했다.
- **Run prep helper** — `RunPrepSummary.for_run()`이 현재 보드, 보드 레벨, 손패, 성 위치, 보드 용량, 카드 catalog를 받아 성 선택 여부, 군세 수, 손패 크기, 증원/배치/계략 후보 수를 순수 계산한다.
- **전투 준비 요약 UI** — `run_map.gd`가 combat, elite, boss 스테이지에서 전투 시작 버튼 위에 `전투 준비 — 손패 3장 중 1장`과 `성 위치: 미선택 · 군세 0/9 · 증원 후보 ...` 형태의 상세 문구를 표시한다.
- **전투 시작 tooltip 보강** — 전투 버튼과 준비 요약 tooltip이 성 위치를 고른 뒤 손패 한 장만 배치, 증원, 계략, 우물 중 하나로 쓰고 즉시 교전한다는 루프를 설명한다.
- **검증** — `test_run_prep_summary.gd`가 첫 손패와 기존 부대 증원 후보를 검증하고, `tools/ui_feedback_smoke.gd`가 첫 런맵 전투 화면의 준비 요약과 tooltip을 확인한다. `./init.sh` 카드 22개, 단위 테스트 2829/2829 green.

## 2026-06-06 — feat-056 보상 후 다음 스테이지 준비 안내
전리품 선택 뒤 런 흐름이 끊기지 않도록, 다음 스테이지 종류와 준비 행동을 결과 오버레이에 표시했다.
- **Stage prep helper** — `StageCadence.stage_prep_label()`과 `stage_prep_tooltip()`이 전투, 보스, 칙령, 상점, 정예, 사건, 확장 stage의 준비 행동을 순수 문자열로 반환한다.
- **결과 오버레이 안내** — `battle.gd`가 보상 선택 후 `다음 준비 — 스테이지 2 — 전투`과 `전투 화면에서 손패 3장 중 1장을 배치합니다.` 같은 안내를 다음 스테이지 버튼 위에 표시한다.
- **다음 스테이지 버튼 강화** — 버튼 text에 실제 stage label을 붙이고 tooltip에 다음 화면에서 할 일을 적는다. 보상 후보가 없는 승리 경로도 같은 안내를 사용한다.
- **검증** — `test_stage_cadence.gd`가 stage prep 문구를 검증하고, `tools/ui_feedback_smoke.gd`가 보상 선택 후 다음 준비 안내와 다음 스테이지 버튼을 확인한다. `./init.sh` 카드 22개, 단위 테스트 2802/2802 green.

## 2026-06-06 — feat-055 보상 선택 비교 UX
전투 승리 뒤 보상 후보가 현재 판과 비교해 무엇을 바꾸는지 바로 읽히도록 전리품 UX를 보강했다.
- **비교 helper** — `CardChoiceAdvisor`가 후보 카드별 선택 전후 변화를 `비교 — 기존 부대 Lv.2 -> Lv.3`, `장수 0 -> 1`, `건물 0 -> 1`, `손패 0 -> 1`, `보패 즉시 장착` 같은 player-facing 문구로 계산한다.
- **전리품 버튼 비교 문구** — `battle.gd` 보상 버튼이 기존 `추천 — ...` 아래에 `비교 — ...`를 함께 표시하고, tooltip에도 자세한 비교 설명을 붙인다.
- **버튼 높이 보정** — 전리품 버튼이 세 줄 설명을 담을 수 있도록 `_make_button()`이 텍스트 줄 수에 맞춰 최소 높이를 계산한다.
- **검증** — `test_card_choice_advisor.gd`가 비교 helper 주요 분기를 검증하고, `tools/ui_feedback_smoke.gd`가 보상 화면에서 비교 문구와 tooltip이 렌더되는지 확인한다. `./init.sh` 카드 22개, 단위 테스트 2797/2797 green.

## 2026-06-06 — feat-054 손상 저장 이어하기 보호
저장 파일이 존재해도 실제로 이어갈 수 있는 런인지 확인한 뒤 UX에 노출하도록 저장 재시작 경계를 보강했다.
- **Resumeable save status** — `RunManager.run_save_status()`와 `has_resumeable_run_save()`가 ConfigFile 로드, run section, RunState payload 호환성, started 여부를 확인한다. 조회는 현재 런 상태를 변경하지 않는다.
- **군주 선택 복구 안내** — `lord_select.gd`는 로드 가능한 저장일 때만 `저장된 런 이어하기`를 표시한다. 손상/호환 불가 저장이 있으면 비활성 `저장된 런을 불러올 수 없음` 안내와 새 군주 선택 복구 tooltip을 보여준다.
- **자동 로드 guard** — `run_map.gd`는 재개 가능한 저장만 자동 로드한다. 손상 저장은 새 기본 런 시작으로 복구된다.
- **검증** — `tools/resume_ux_smoke.gd`가 no-save, corrupt-save, valid-save 세 케이스를 검증한다. `./init.sh` 카드 22개, 단위 테스트 2790/2790 green.

## 2026-06-06 — feat-053 충돌 중 타격감 VFX 반복
전투 중 데미지 이벤트가 숫자만 뜨는 느낌을 줄이고, 실제 충돌이 반복해서 보이도록 피격 VFX를 추가했다.
- **BattleHitFeedback helper** — `scripts/battle/battle_hit_feedback.gd`가 데미지 이벤트를 VFX 프로필로 바꾼다. 일반 피해는 spark, 치명타는 crit ring, 스킬/계략은 burst를 추가한다.
- **전투 화면 피격 VFX** — `battle.gd`가 `_play_damage_events()`마다 `hit_impact_vfx` meta가 있는 `Polygon2D`를 VFX layer에 띄운다. BattleSim의 피해 계산과 밸런스 수치는 바꾸지 않는다.
- **UI smoke 고정** — `tools/ui_feedback_smoke.gd`가 첫 수동 전투에서 데미지 이벤트를 주입하고 spark/crit/burst가 실제 씬에 생성되는지 검증한다.
- **검증** — `test_battle_hit_feedback.gd` 추가. `./init.sh` 카드 22개, 단위 테스트 2769/2769 green.

## 2026-06-06 — feat-052 병력 밀도/함성 체감 패스
삼국지 전투가 더 많은 군세의 충돌로 읽히도록 렌더 밀도와 시작 연출을 보강했다.
- **분대 밀도 cap 상향** — `BattleFeel`과 `FormationRenderer`의 병종 분대 렌더/visible cap을 18명으로 올렸다. Lv.3 병종 18명 성장 체감이 화면과 metric에 그대로 남는다.
- **장수 호위 cap 상향** — 장수 호위는 10명까지 렌더/visible metric에 반영한다. 장수 본체만 떠 있는 느낌을 줄이고 주변 병사감을 강화한다.
- **함성 cue 분리** — `AudioManager`에 `rally` SFX id를 추가했다. 새 파일을 만들지 않고 기존 `battle_start.wav`를 재사용해 전투 시작 사운드의 의미를 분리했다.
- **시작 충돌 VFX** — battle 화면 시작 순간 `RallyBanner`, `ChargeLine`, `ClashPulse`를 meta 태그가 있는 VFX로 띄운다. UI smoke가 첫 수동 플레이에서 이 VFX가 실제 생성되는지 검증한다.
- **검증** — `tools/ui_feedback_smoke.gd`, `test_battle_feel.gd`, `test_formation_renderer.gd`, `test_audio_manager.gd` 갱신. `./init.sh` 카드 22개, 단위 테스트 2746/2746 green.

## 2026-06-06 — feat-051 저장/이어하기 UX 스모크
군주 선택 화면에서 저장된 런을 이어가는 UX 경로를 자동 smoke로 고정했다.
- **Resume UX smoke** — `tools/resume_ux_smoke.gd`가 기본 저장 파일 없음/저장 런 있음 두 케이스를 독립적으로 검증한다.
- **이어하기 노출 계약** — 저장 파일이 없으면 `저장된 런 이어하기` 버튼이 보이지 않고, autosave 런이 있으면 버튼과 현재 스테이지 재개 tooltip이 보인다.
- **복원 경로 검증** — 버튼 핸들러를 실행해 run_map scene route가 발생하고, `RunManager.load_run()` 이후 stage, 성 위치, 보드, 손패, 골드가 저장 직전과 일치하는지 확인한다.
- **검증 연결** — `init.sh`에 저장/이어하기 UX 스모크를 연결했다. `./init.sh` 카드 22개, 단위 테스트 2740/2740 green.

## 2026-06-06 — feat-050 카드 선택 추천순 정렬
상점과 전리품 선택지가 현재 런 맥락에서 더 좋은 카드부터 보이도록 정렬했다.
- **추천순 helper** — `CardChoiceAdvisor.ranked_ids()`가 기존 후보 id 배열을 추천 점수순으로 stable sort한다. 동일 점수는 원래 후보 순서를 유지한다.
- **상점 정렬** — `run_map.gd` 상점 카드가 추천순으로 렌더된다. 골드가 부족한 카드는 `자금 부족` 점수로 뒤로 밀린다.
- **전리품 정렬** — `battle.gd` 전리품 버튼도 같은 추천순을 사용한다. 후보 생성과 보상 확률은 바꾸지 않는다.
- **검증** — `test_card_choice_advisor.gd`가 증원 후보 우선, 경제 카드 우선, 구매 불가 카드 후순위를 검증한다. `tools/ui_feedback_smoke.gd`가 상점 첫 추천 카드가 `증원 후보`인지 확인한다. `./init.sh` 카드 22개, 단위 테스트 2740/2740 green.

## 2026-06-06 — feat-049 전투 템포 예산
첫 플레이 전투가 느리게 끌리는 회귀를 줄이도록 기본 속도와 자동 검증 예산을 조정했다.
- **기본 x3 전투** — `battle.gd`의 전투 기본 속도를 x3으로 올렸다. 플레이어가 첫 교전에 들어가면 별도 클릭 없이 빠른 전투 속도로 시작한다.
- **속도 UI smoke** — `tools/ui_feedback_smoke.gd`가 battle 씬의 기본 `_speed`와 x3 버튼 선택 표시를 확인한다.
- **초반 시간 예산** — `PlaytestMetrics.first_five_ok()`가 첫 5스테이지 전투의 개별 최대 시간을 24초, 평균 시간을 20초로 검증한다.
- **검증** — `tools/playtest_loop_smoke.gd`에서 stage 1/2/5가 21.1s/18.3s/14.6s로 통과했다. `./init.sh` 카드 22개, 단위 테스트 2734/2734 green.

## 2026-06-06 — feat-048 수동 플레이 QA 자동화
첫 전투의 실제 수동 조작 경로를 UI smoke에 묶어, 배치가 다시 깨지는 회귀를 빠르게 잡도록 했다.
- **Manual first play smoke** — `tools/ui_feedback_smoke.gd`가 유비 새 런을 시작하고 첫 손패를 계략/보병/건물로 고정한다.
- **배치 경로 검증** — smoke가 성 위치를 먼저 선택하고, 계략 카드를 타일에 놓으려 하면 거부되는지 확인한 뒤, 보병 카드를 빈 타일에 배치한다.
- **전투 시작 계약** — 보병 배치 후 즉시 전투 phase로 넘어가며 성 위치, 보드 배치, 손패 감소, 교전당 1장 제한, 성/아군/적 생성, `전군 돌격!` hint를 검증한다.
- **검증** — `godot --headless --path . --script res://tools/ui_feedback_smoke.gd` 통과. `./init.sh` 카드 22개, 단위 테스트 2731/2731 green.

## 2026-06-06 — feat-047 현세 3군주 장기런 스모크
최종 보스까지의 자동 장기런 검증을 유비 단일 루트에서 현세 3군주 전체로 확장했다.
- **3군주 장기런** — `tools/long_run_smoke.gd`가 유비·조조·손권을 각각 새 `RunState`로 시작해 stage 1~15 전투, 칙령, 상점, 사건, 보드 확장, 최종 보스를 결정적으로 진행한다.
- **실제 카드 타입 반영** — 장기런 선택기가 유닛 배치/증원뿐 아니라 건물 배치, 망루 오라, 계략 battle/run 효과, 병법서 보패 공격 보정을 시뮬레이션에 적용한다.
- **첫 정예 템포 보정** — 조조 정상 루트를 막던 stage 7 명궁 원거리 스파이크를 좁게 낮췄다. `test_wave_factory.gd`가 stage 7 encounter의 정예 기병과 명궁 수치를 검증한다.
- **군주별 선택 지능** — 조조는 하후돈·망루 루트, 손권은 주유 우선 루트로 각 진영의 전략 축을 검증한다. 조조 전략 덱은 첫 정예 전에 망루가 다시 잡히도록 순서를 조정했다.
- **검증** — `godot --headless --path . --script res://tools/long_run_smoke.gd`에서 유비·조조·손권 모두 wins=8, board=5, rows=6으로 stage 15 최종 보스를 통과했다. `./init.sh` 카드 22개, 단위 테스트 2731/2731 green.

## 2026-06-06 — feat-046 카드 선택 전략 안내
상점과 전리품 선택이 현재 런 맥락에서 왜 좋은 선택인지 읽히도록 추천 문구를 추가했다.
- **CardChoiceAdvisor helper** — `scripts/run/card_choice_advisor.gd`가 보드, 보드 레벨, 손패, 골드, 카드 타입만 읽어 `증원 후보`, `전열 보강`, `지휘 핵심`, `경제 확장`, `화력 거점`, `즉시 한 수`, `지속 화력`, `자금 부족` 같은 player-facing 선택 이유를 순수 계산한다.
- **상점 전략 라벨** — `run_map.gd` 상점 카드가 추천 한 줄을 visible text로 표시하고 tooltip에도 같은 판단을 붙인다. 골드가 부족한 카드는 부족 금액을 말한다.
- **전리품 추천 버튼** — `battle.gd` 전투 승리 보상 버튼이 카드 brief 아래 추천 문구를 함께 표시한다.
- **검증** — `test_card_choice_advisor.gd`가 주요 추천 분기를 검증하고, `tools/ui_feedback_smoke.gd`가 상점과 보상 화면에서 추천 문구가 실제 렌더되는지 확인한다. `./init.sh` 카드 22개, 단위 테스트 2726/2726 green.

## 2026-06-06 — feat-045 집중표적 체감 피드백
전투 중 표적 지정이 실제 지휘처럼 읽히도록 화면 피드백과 회귀 검증을 보강했다.
- **BattleCommandFeedback helper** — `scripts/battle/battle_command_feedback.gd`가 집중표적 선택 반경, 현재 표적/장수 수 tooltip, 성공/실패/자동복귀 문구, 표적 마커 문자열을 순수 계산한다.
- **전투 화면 피드백** — `battle.gd`가 집중표적 버튼 tooltip을 전투 상태에 맞춰 갱신하고, 적 클릭 성공 시 `집중 표적 — <적> · 장수 N명 집중` 힌트, 표적 위 `집중` 라벨, 장수→표적 지휘선, 짧은 명령 배너를 띄운다. 빈 곳 클릭과 표적 사망은 자동 표적 복귀 문구를 남긴다.
- **UI smoke 보강** — `tools/ui_feedback_smoke.gd`가 실제 battle.tscn을 전투 단계까지 진행한 뒤 집중표적 지정, 현재 표적 tooltip, 마커/라벨 표시, 빈 곳 클릭 해제를 검증한다.
- **검증** — `./init.sh` 카드 22개, UI 피드백 스모크에 전투 집중표적 피드백 OK 추가, 단위 테스트 2701/2701 green.

## 2026-06-05 — feat-044 장기런 자동 스모크
첫 5스테이지 MVP 스모크에 더해 최종 보스까지 런이 끊기지 않는지 검증하는 자동 장기런 축을 추가했다.
- **LongRunSmoke** — `tools/long_run_smoke.gd`가 유비 기준 stage 1~15를 결정적 선택으로 진행한다. 전투·보스·칙령·상점·사건·보드 확장 노드를 모두 통과하고 각 전투의 compact metric을 출력한다.
- **성장 축 반영** — 장기런 선택기는 보드 유닛이 갖춰진 뒤 병법서 보패를 획득하고, 시뮬레이션에 `TreasureCatalog` battle attack 보정을 적용한다. 이로써 stage 15 최종 보스가 자동 루프에서 승리 가능한지 확인한다.
- **init 연결** — `init.sh`가 플레이테스트 루프 스모크 뒤 장기런 스모크를 실행한다. stage 15는 result=1, 20.5s 승리, wins=8, board=4, rows=6으로 통과한다.
- **검증** — `./init.sh` 카드 22개, 장기런 스모크 포함, 단위 테스트 2677/2677 green.

## 2026-06-05 — feat-043 배치 전술 미리보기
전술 보너스를 배치 전 읽을 수 있게 했다. “수치가 존재한다”에서 “놓기 전에 전략으로 보인다”로 한 걸음 당겼다.
- **미리보기 helper** — `FormationTactics.preview_for_unit()`과 `preview_label()`이 전술 태그와 공격 보너스를 `엄호 +15%` 같은 reader-facing 문자열로 바꾼다. 보너스 없는 칸은 빈 preview를 반환해 화면을 과도하게 채우지 않는다.
- **빈 타일 preview** — `battle.gd`가 손패 유닛 선택 중 빈 타일마다 임시 보드를 만들고, 해당 칸에 배치될 유닛의 전술 보너스가 있으면 타일 라벨과 tooltip에 표시한다.
- **UI 스모크 보강** — `tools/ui_feedback_smoke.gd`가 성+보병 전열+궁병 손패 상황에서 `1:1` 빈 타일에 `엄호 +15%`와 `궁병 배치` tooltip이 뜨는지 검증한다.
- **검증** — `./init.sh` 카드 22개, UI 피드백 스모크에 전투 전술 미리보기 OK 추가, 단위 테스트 2677/2677 green.

## 2026-06-05 — feat-042 진형 전술 시너지
MVP 루프의 배치 격자를 실제 공격 보너스와 읽히는 전술 태그로 연결했다. 새 카드 Resource 필드는 추가하지 않고 기존 장수·병종·행/열 정보만 사용한다.
- **FormationTactics helper** — `scripts/run/formation_tactics.gd`가 지휘(+10%), 엄호(+15%), 측면(+10%) 보너스와 태그를 순수 계산한다. 전술 재계산은 `formation_base_attack` 메타를 기준으로 하므로 배치 중 재계산해도 중첩 곱셈하지 않는다.
- **군세 변환 연결** — `CardCatalog.build_board_army()`가 terrain perk 적용 뒤 `FormationTactics.apply_to_army()`를 호출해 실제 전투 유닛 공격력에 반영한다.
- **전투 UI 태그** — `battle.gd`가 배치/증원 후 현 군세 기준으로 전술을 재계산하고, 타일 라벨에 `지휘/엄호/측면` 태그를 붙인다.
- **검증** — `test_formation_tactics.gd`가 장수 인접 보병, 전열 뒤 궁병, 가장자리 기병, 비적용, idempotent 재계산을 검증한다. `./init.sh` 카드 22개, 단위 테스트 2671/2671 green.

## 2026-06-05 — feat-041 전투 체감 패스
MVP 루프의 첫 교전을 "군세 충돌"로 읽히게 하는 뷰·파도 체감 패스. BattleSim 결정성은 보존하고, stage 1 encounter와 시작 VFX만 좁게 조정했다.
- **BattleFeel helper** — `scripts/battle/battle_feel.gd`가 visible soldiers, lane coverage, enemy front 계약, rally text를 순수 계산한다. `test_battle_feel.gd`가 첫 encounter enemy front와 병력 밀도 집계를 검증한다.
- **첫 적 전열** — `WaveFactory.stage_encounter_waves(1)`이 단일 적 대신 중앙 전선 근처 3개 저체력 분대를 낸다. enemy visible 25명으로 보이되, stage 1 자동 교전은 21.1s에 끝나도록 HP/공격/y 간격을 낮췄다.
- **전투 시작 피드백** — `battle.gd`가 전투 시작 순간 "전군 돌격!" banner, 양 진영 charge line, 짧은 camera shake를 VFX layer에 표시한다. 시뮬레이션·저장·카드 데이터는 바꾸지 않는다.
- **메트릭 확장** — `PlaytestMetrics`가 아군/적/전체 visible soldiers를 출력한다. `tools/playtest_loop_smoke.gd`는 stage 1 total 35명, stage 2 total 32명, stage 5 total 36명을 확인한다.
- **검증** — `./init.sh` 카드 22개, 단위 테스트 2645/2645 green. 플레이테스트 루프 stage 1/2/5 전투 21.1s/18.3s/14.6s green.

## 2026-06-04 — feat-037 Phase 7 밸런스·릴리스 준비 (G078~G084)
제품 루프가 끝까지 도는 현재 baseline을 릴리스 준비 상태로 정리했다. 천계·마계 nation id는 승인 전 그대로 보류하고, 승인 없이 가능한 밸런스·export·문서 경계를 먼저 닫았다.
- **G078 밸런스 계약** — `StageCadence.DIFFICULTY_STEP=0.10`으로 stage 1/5/15 배율을 1.00/1.40/2.40에 고정했다. 칙령은 군세 +10%, 재정 +20%, 축성 +15%. 둔전은 cost 3·gold/sec 1, 망루는 cost 4·오라 +10%, 징발은 cost 4·gold +6. 보패 기본값은 병법서 +10%/2중첩, 금인 +20%, 천리안 +1 선택지 유지. `test_balance.gd`가 수치 계약을 한곳에서 검증한다.
- **G079 macOS export preset** — `export_presets.cfg`에 민감정보 없는 `macOS Desktop` preset을 추가했다. `export_presets.cfg`는 추적하고, signing/notarization credential은 비워 두며, Godot credential 경계는 `.godot/export_credentials.cfg`로 둔다. `test_export_preset.gd`가 preset 이름, platform, export path, resource filter, `docs/reports/**`·`test/**`·`tools/**` 제외, bundle id, credential-free 필드를 검증한다.
- **pack export 증거** — `godot --headless --path . --export-pack "macOS Desktop" build/macos/guju-jaengpae.pck` 성공. 산출물은 33MB이고 `.gitignore`의 `build/` 경계에 남긴다. G083에서 playable `.app`/`.zip` full export와 첫 전투 smoke까지 닫았다.
- **문서 동기화** — README, roadmap, worldview, asset manifest, session-handoff, progress, feature_list를 Phase 7 릴리스 준비 기준으로 맞췄다. `docs/worldview.md`는 천계·마계 명칭을 여전히 “제안/승인 대기”로 유지한다.
- **G081 릴리스 체크리스트** — `docs/release-checklist.md`를 추가하고 앱 버전 `0.7.0`, 태그 후보 `v0.7.0-rc1`/`v0.7.0`, 사용자 확인 전 tag/push 금지, preflight 명령, G082~G084 선행 조건을 문서화했다.
- **G082 fresh clone 검증** — 로컬 임시 클론에서 `./init.sh`를 실행했고, 카드 22개와 단위 테스트 2349/2349 green을 확인했다.
- **G083 full app export 검증** — Godot 4.6.3 export templates로 `build/macos/guju-jaengpae.zip`를 생성했고, release 앱을 `GUJU_EXPORT_SMOKE=first_battle`로 실행해 lord_select → run_map → battle → stage 1 첫 전투 marker를 확인했다. export 앱에서 `.tres.remap` 디렉터리 항목이 보이는 문제를 `CardCatalog.resource_path_for_dir_entry()`로 정규화해 시작 덱이 비지 않게 했다.
- **G084 리스크 문서화** — `docs/release-risks.md`에 지원 기준, 미지원·보류 범위, 운영 리스크, 태그 전 stop condition을 고정했다. `docs/release-checklist.md`는 이 문서를 릴리스 노트 기준으로 링크한다.
- **검증** — `./init.sh` 카드 22개, 단위 테스트 2375/2375 green. `jq empty feature_list.json`, `git diff --check`, `progress.md` 120줄 제한 유지.

## 2026-06-04 — feat-028 유닛 애니메이션 (스프라이트 시트 · agy→Codex · architect APPROVED)
정적 Sprite2D 빌보드 → 프레임 애니메이션. agy 가로 4프레임 walk 시트 → AnimatedSprite2D/SpriteFrames. **순수 뷰(결정성 불변)**.
- **시트 규약** — `<unit>_walk.png` 가로 4프레임 균등(프레임폭=시트폭÷4), 마젠타 키아웃. agy 생성(품질 우수·캐릭터 일관)→Claude 시트 키잉(autocrop 없이 프레임 구조 유지).
- **렌더 분기** — battle.gd `_create_unit_body`(_walk.png 있으면 AnimatedSprite2D, 없으면 Sprite2D 현행)·`_apply_unit_body_visuals`(flip/modulate/scale/발밑앵커 공통)·`_build_walk_sprite_frames`(4 AtlasTexture region·8fps loop)·`_sync_unit_walk_animation`(이동 delta 시 play, 정지 frame0). 시트 없는 유닛 정적 유지.
- **결정성** — 애니는 뷰 캐시(last_px/py 델타)로만 판정, BattleSim 무오염(architect 3중 확인). 스킬/데미지 modulate 트윈은 CanvasItem 캐스트로 양 노드 공통.
- **검증** — test_unit_walk_visuals 21단언(시트→AnimatedSprite·무시트→Sprite2D·적 flip_h). `./init.sh` 935 green(914→+21), 부팅 무에러. 시범 1종(촉 보병). agy 자율-쓰기 함정 — `--add-dir` 디렉토리에 이미지 직접 저장.
- **잔여** — 나머지 유닛 walk + idle/attack 애니는 agy 점진 생성(시스템 구축 완료, 시트만 추가하면 자동 적용).

## 2026-06-04 — feat-021 왕의 칙령 (전역 perk · Codex · architect THOROUGH APPROVED)
3스테이지마다 칙령 드래프트 — 전역 perk 3중1을 골라 런 전체에 누적 적용. EdictCatalog 코드 레지스트리(skill_system 패턴).
- **EdictCatalog** — 군세(edict_might, 전 아군 공격력 +12%)·재정(economy, 골드 +25%)·축성(fortify, 성HP +20%), pct 합산 헬퍼·고정 all_ids(결정성).
- **캐이던스** — EDICT_INTERVAL=3, node_kind 우선순위 boss>edict>shop>expand>combat. stage 12=칙령(상점 위), 15=보스(칙령 스킵).
- **전역 수정자** — card_catalog.build_player_unit edicts 파라미터(trait 후 곱셈 체인, 누적 합산), battle.gd 둔전 골드 +25%·성HP +20%. 우물 골드는 제외(설계 명문화). RunState.edicts 누적, RunManager is_edict_stage/add_edict/get_edicts.
- **드래프트 UI** — run_map `_build_edict_panel`(상점 패턴, 3택 무료).
- **검증** — test_stage_cadence(캐이던스 충돌 12·15)·test_run_board(trait×edict 곱셈 47·스택 +24%·immutability) substantive. `./init.sh` 914 단언 green(876→+38). architect — 곱셈 순서·결정성·회귀 없음 코드 확인.

## 2026-06-04 — feat-020 땅 확장 (board 3→6행 · Codex · architect THOROUGH APPROVED)
보스 격파 보상으로 보드를 3행→최대 6행(18칸) 확장. Claude 스펙(BattleSim static 유지 제약) → Codex 구현 → architect 검증.
- **RunState** — `board_rows`(3..6) 동적, `block_keys()` static→instance(`block_keys_for(rows)` static + 인스턴스 래퍼), 용량/`board_full` 동적, `expand_board()`.
- **BattleSim static 유지** — `ROW_COUNT` 3→6 const, `ROW_X` 6행 고정 `[360,240,120,480,600,720]`. 실제 사용 행은 RunState.board_rows가 제어(인스턴스화 안 함). 새 행(3~5)은 전방(적 쪽) 배치 — 성 공간(x40~120) 부족으로 후방 증설 불가, 확장=전열 전진(공세) 의도.
- **호출부 정합** — card_catalog.build_board_army(board_rows 순회), RunManager(expand_board/get_board_rows), battle.gd(타일 board_rows 렌더 + 보스 보상 자동 +1행), board_economy(block_keys 의존 끊고 board.keys() 결정적 정렬 — 확장 행 건물 누락 방지).
- **검증** — test_run_board(상한·동적 칸수·행밖 제외)·test_board_army·test_grid 확장. `./init.sh` 876 단언 green(795→+81), 결정성·feat-029·촉/위/오 회귀 없음.

## 2026-06-04 — feat-029 위·오 진영 깊이 (trait + 장수 스킬 · Codex · architect APPROVED)
위(호패)·오(수전) 군주 trait 실효과 + 위·오 장수 4종 고유 스킬. 촉 인덕·5스킬 패턴 확장.
- **trait** — card_catalog.build_player_unit에서 호패(조조)=아군 기병 공격력 ×1.25, 수전(손권)=궁병·수군 ×1.20(from_card 후 attack 패치, 시그니처 불변).
- **스킬 4종** — 조조 위압(반경 180px 45피해+약화)·하후돈 발돌(전방 240×130 75피해)·손권 결단(max_hp 최고 적 130피해, int tie-break)·주유 화공(최근접 중심 반경 200px 65피해). skill_system const+COOLDOWNS+cast 등록, general 4종 .tres skill_id/skill_text.
- **검증** — test_skills/test_factions 확장(경계·수치 substantive). `./init.sh` 795 green. architect — 결정성 보존(tie-break 결정적)·촉 5스킬·인덕 회귀 없음. 커밋 ca6b816.

## 2026-06-04 — feat-027 마감: 촉 12종 + 주유 강화 (플레이 3진영 완료)
agy 할당량 리셋 후 잔여 마감. 촉(shu) 12종 + 주유(`wu/general_zhouyu`) 1종 강화 → **촉·위·오 30종 전부 강화 완료**. 마계 등 적 진영은 원본 유지(QA상 대비 충분).
- **촉 프롬프트** — 위·오와 달리 단일 진영색이 없어(유비 녹/금·조운 은백·장비 흑·제갈량 백) "기존 색 유지 + 채도·대비·림라이트, 단일 리컬러 금지"로. 각 캐릭터 원색 보존하며 강화됨.
- **검증** — `./init.sh` 723 green(텍스처 재import·회귀 없음). 촉 강화 전/후 인게임 스크린샷 확인. 커밋 c526f78.
- **agy 운영 함정 2건(추가)** — ① 백그라운드 detached 셸은 PATH 축소로 `python3` 미발견(키잉 실패·agy 생성은 성공, exit 127) → 키잉은 `/usr/bin/python3` 절대경로. ② `--add-dir`를 입력 디렉토리로 좁히고 "이미지만 생성" 명시로 agy 자율편집 방지 검증됨. 메모리 `agy-image-pipeline` 반영.

## 2026-06-03 — 렌더 스케일업 (유닛 가독성 · Claude 직접 튜닝)
feat-027 강화 스프라이트가 작은 스케일에서 묻히던 문제 해소. `battle.gd` 뷰 상수만 상향(BattleSim·전투 로직 불변) — UNIT_W 108→140·UNIT_H 100→130·GENERAL 124→162·132→172·BOSS 182→204·218→244·CASTLE 124→150·154→188·BUILDING 92→108·88→104. 유닛 modulate는 WHITE 유지(색 안 죽임). before/after 스크린샷 — 한산함 해소·유닛 존재감↑·겹침은 난전 허용 범위. `./init.sh` 723 green·부팅 무에러. 시각 반복 튜닝이라 편집장 직접 조정(원래 Codex 위임 제안), 타일 간격/밀도 정교화는 Codex 여지.

## 2026-06-03 — feat-027 agy 그래픽 보정 (위·오 진영 강화 · Claude QA→agy→Claude)
마누스 페인터리 풀세트 중 **위·오 진영 17종**을 agy image-to-image로 강화 — 포즈·실루엣·장비·화풍을 유지하고 채도·대비·진영톤·림라이트만 보강(리컬러 아님). "부족분만 보정" 결정의 실행.
- **약점 식별** — 인게임 QA 4장(촉·위·오·보스) + 진영 콘택트시트. 결론 — 마누스 원본 자체는 양호. 인게임에서 약해 보이는 **주원인은 렌더 스케일**(유닛은 `modulate=WHITE`로 색 안 죽임, `_unit_size`로 축소). agy로 안전하게 얻는 이득은 진영 색·대비 일관성.
- **보정** — `ImagePaths`로 원본 + "강철청(위)/주홍(오)·림라이트 강화, 순마젠타 배경, 모양 유지" 프롬프트. 위=강철청+금·cyan 림, 오=주홍+청동·warm 림. agy 출력(마젠타 PNG) → PIL 키아웃→autocrop→다운스케일(`/tmp/agy_keyout.py`) → `assets/sprites/units/{wei,wu}/` 배치.
- **물량** — 위 9(infantry·archer·cavalry·crossbow·general 5) + 오 8(infantry·archer·cavalry·navy·general 4). **주유(general_zhouyu) 1종은 agy 할당량 초과로 미완**(리셋 후 보정). 촉·마계 등은 원본 유지.
- **검증** — `./init.sh` 723 단언 green(텍스처 재import·회귀 없음). 위·오 인게임 before/after 스크린샷 — 진영색 분리·채도 개선 확인(작은 스케일이라 체감은 온건).
- **후속(Codex)** — 강화가 빛나려면 렌더 스케일업 동반 권장 — `battle.gd UNIT_W 108→~140`·`GENERAL_W 124→~160` + 유닛 밀도. 작은 스케일에선 1px 림라이트 체감이 제한적.
- **파이프라인 함정** — godot용 `export HOME=.godot/home`과 PIL python을 한 셸에서 섞으면 `ModuleNotFoundError: PIL`(user-site 의존). 키잉은 원 HOME, godot만 서브셸 격리.

## 2026-06-02 — 방향 결정: 마누스 아트 유지 + agy 보정/애니메이션 (v0.6 backlog)
- **결정** — 마누스 페인터리 풀세트를 현 상태로 두고 부족분만 후속 보정. 전체 아트 방향 재변경 안 함.
- **agy 역량 조사** — `generate_image`로 image-to-image 그래픽 수정 가능(`ImagePaths` 최대 3장 + 프롬프트, 리컬러·인페인트·보정·배경제거), 멀티프레임 **스프라이트 시트** 생성 가능(GIF/MP4 **영상은 불가**). → 그래픽 보정·애니메이션화를 agy에 배정.
- **v0.6 backlog 확정** — feat-027 agy 그래픽 보정, feat-028 유닛 애니메이션(agy 시트→Godot AnimatedSprite2D), feat-029 위·오 trait 실효과·장수 스킬. + 평원 배경 사용자 미드저니 교체, feat-020 확장·021 칙령.
- 다음 세션 핸드오프·시작 프롬프트 → `session-handoff.md`.

## 2026-06-02 — 위·오 진영 활성화 + 군주 선택 (서브에이전트 구현 · ⓐ)
- **faction-aware 렌더링** — `battle.gd` 유닛 텍스처 faction을 플레이어 군주 nation으로(`RunManager.player_faction()`). 병종은 기존 카드 재사용 — 군주 nation이 art만 바꾼다(촉 옥록·위 강철·오 주홍).
- **군주 선택 화면** — `scenes/screens/lord_select.tscn` 신설, `main_scene` 지정. 촉(유비)·위(조조)·오(손권) 선택 → `ensure_started`(멱등) → `run_map`.
- **위·오 데이터** — 장수 4종(`general_caocao`·`xiahoudun`·`sunquan`·`zhouyu`, 스킬 없는 1차 컷) + 군주 2종(`lord_caocao`·`lord_sunquan`, trait는 플레이버 no-op). `card_data` fantasy_tier에 "heroic" 추가.
- **검증** — `test/test_factions.gd`(18단언) 신설. `./init.sh` 723 단언 green. 스크린샷 — 군주 선택 화면·위·오 전투 아트 렌더 확인. battle_sim/skill_system 등 전투 로직 불변.
- **주의(후속)** — 위·오 trait 효과 미구현(no-op), 장수 스킬 없음. v0.6 진영 데이터화 때 보강. 신규 장수가 보상 풀에 들어가 reward 픽스처 갱신됨.

## 2026-06-02 — 전투·상점 폴리시 (서브에이전트 ⓑⓒⓓ)
- **ⓑ 상점 UI** — `run_map` 상점을 카드 프레임(general/troop/building) 그리드로(골드 아이콘·비용·설명, 부족 시 비활성). **ⓒ 유닛 스케일** 상향(배경 대비 가시성). **ⓓ 기병 우향** — 7진영 cavalry.png 수평 반전. `./init.sh` 701 green.

## 2026-06-02 — feat-015d 상점 이벤트 (done · Codex 구현)
- **상점 = 독립 스테이지** — `StageCadence.is_shop`(4·8·12…) 스테이지에서 `run_map`이 전투 대신 상점 모드를 렌더. "상점 떠나기"로 `advance_stage`.
- **구매 경로** — `CardCatalog.purchasable_ids`(유닛+건물 합집합, 비용 오름차순), `RunManager.shop_purchase(id)`(골드 충분 시 `spend_gold`+`hand_add`, 부족 시 false·상태 불변), `is_shop_stage`. 골드로 카드를 사 손패에 넣는다.
- **건물 실획득** — 보상풀(유닛 전용) 밖에서 건물 카드(둔전·망루)를 처음으로 획득 가능해졌다. 손패 초과는 다음 전투 배치 단계에서 보드로 해소.
- **검증** — `test/test_shop.gd` 신설(구매 성공·골드부족 불변·캐이던스 4/8/12). `./init.sh` 701 단언 green, run_map/battle 부팅 무에러. 상점 화면 캡처 확인.
- **스코프** — 전투 로직·`RewardPool` 불변. `run_map` 모드 분기만 추가.

## 2026-06-02 — 마누스 풀세트 아트 통합 (Manus 외주 · 픽셀→페인터리 전환)
agy 임시 픽셀 애셋을 외부 에이전트(Manus) 납품 풀세트로 교체. **아트 방향 픽셀아트 → 디테일 페인터리/일러스트**(브리프 허용 대안, 전 애셋 단일 통일).
- **외주 브리프** — `docs/asset-production-brief.md` 정본화(자족 발주서 — 9세력·치수·네이밍·팔레트·Phase0 승인 게이트). 마누스가 이 계약대로 93종 납품(T0-T2).
- **통합 파이프라인** — 고해상 투명 PNG(유닛 1056×1408·배경 2560×1440 등) → 오토크롭 + LANCZOS 다운스케일(`tools/`/임시 스크립트)로 게임 경로 배치. sprites 총 30M.
- **물량** — 배경 7테마·아이소 타일·건물 9·UI 22·현세 3국(촉·위·오)·마계 3국(황천·낙양·만요)의 병종·장수·보스. 천계(T3) 미포함.
- **진영 매핑** — 엔진이 쓰는 `units/demon/`은 보스 동탁 소속 낙양마궁(`luoyang`)에서 채워 보스·잡병 비주얼 통일. 미사용 진영(wei·wu·huangtian·wanyao)은 향후 카드 추가 시 활성.
- **타일 폴리시** — 페인터리 배경 대비 밝은 잔디 타일 불투명도 0.72→0.5.
- **검증** — `./init.sh` 684 단언 green·임포트 무에러. 스크린샷 — 평원 배경·촉 군세·마왕 동탁 보스·"+24" 데미지 숫자 렌더 확인.
- **주의** — 평원 배경은 사용자 미드저니 결과로 교체 예정(현재 마누스판 임시). 유닛↔배경 스케일 미세조정은 배경 확정 후.

## 2026-06-02 — v0.5 "구주 비주얼 전장" (done · 멀티 CLI: Claude 스펙 · Codex 구현 · agy 애셋)
Nine Kings 풍 리치 픽셀 전투 화면 + 건물 경제 + 교체형 배경 테마. **BattleSim(순수 전투 로직)은 불변**, 뷰 레이어만 오버홀. 정본 `docs/render-architecture.md`·`assets/MANIFEST.md`.
- **멀티 CLI 오케스트레이션** — Claude(편집장)가 스펙·매니페스트·정본 작성, Codex(gpt-5.5 medium, workspace-write 샌드박스)가 GDScript 구현, agy(Antigravity)가 `generate_image`로 픽셀 애셋 생성. agy 출력(1024² JPEG 무알파, brain 디렉토리)을 Claude가 PIL 크로마키·다운스케일(`tools/asset_pipeline.py`)로 투명 PNG 변환·배치. 각 피처 후 Claude 독립 `./init.sh` 재검증 + `tools/shoot_battle.gd` 스크린샷 QA.
- **feat-022 아이소 전장 렌더** — `battle.tscn`을 Control-only에서 Node2D 월드(`Camera2D`·`BackgroundLayer`·`IsoBaseLayer`·`UnitsLayer`[y_sort]·`VfxLayer`) + `CanvasLayer` HUD로 재구성. 단일 투영 `field_to_screen`, 아이소 다이아몬드 보드 타일, ColorRect→`Sprite2D` 빌보드 유닛(매니페스트 경로 + `ResourceLoader.exists` 폴백).
- **feat-023 전투 HUD** — 하단 3중 진행바(성 HP·보스 HP·적 군세 잔존), 상단 스테이지 사다리(`StageCadence.node_kind` + N년 플레이버), 좌상 자원 카운터, 우상 속도 컨트롤(pause + ×1/×2/×3 델타 배율), 좌측 능력 버튼(우물·집중표적). 표시 계산은 순수 `hud_state.gd`로 분리(테스트 가능).
- **feat-024 전투 연출** — `BattleSim`·`SkillSystem`에 `last_damage_events` **가법 노출**(결정성 보존, `last_skill_casts` 패턴). `VfxLayer` 플로팅 픽셀 데미지 숫자(일반/크리/스킬 색 구분)·타격 플래시. BATTLE 단계 DeployPanel 숨김.
- **feat-025 픽셀 애셋 + 배경 테마** — `battlefield_theme.gd`(plain 슬롯, 스테이지/모드 키 선택, **모드-레디**). `field.png` 평원 배경 배선, 소형 잔디 타일(전투 시 페이드), 성채/유닛/보스 스케일, 반투명 배치 패널. agy 생성 애셋 — 평원 배경·성채·보스(마왕 동탁)·촉 5병종·촉 장수 5종·마계 3병종·건물 2종·아이소 타일.
- **feat-016 건물 경제** — `BuildingCardData`(card_type=building) + 둔전(屯田, 골드/초)·망루(望樓, 인접 아군 공격 오라). 순수 `BoardEconomy`(`gold_per_sec`·`apply_auras`)로 BattleSim 불변. 건물은 진군 안 하고 보드 타일에 정적, 전투 종료 시 골드 적립. 건물 **획득(상점)은 feat-015d 후속**.
- **게임 모드 메타(구상)** — 시나리오·자유·멀티 3모드 개념을 `design-loop.md`에 기록. 배경 테마·스테이지를 모드 키로 분기 가능하게 설계. 현재 런 = 자유모드. 모드 선택 UI·시나리오 데이터·멀티는 후속.
- **검증** — `./init.sh` 618→**684 단언**(누적 +66) green, 카드 12·군주 1, run_map/battle 부팅 무에러. 스크린샷 QA로 배경·HUD·아이소 기지·스프라이트 군세·보스·데미지 숫자·건물 렌더 확인. 순수 전투 로직 파일은 feat-024의 가법 이벤트 노출 외 불변.
- **스코프 경계(후속)** — 마계 노병/수군 스프라이트 미생성, 건물 획득 정책(feat-015d), 타일 텍스처 미세 튜닝, feat-020 확장·feat-021 칙령.

## 2026-05-31 — feat-015 경제·보드 상태 모델 1단계 (done · Codex 구현)
- **RunState 보드 모델** — 기존 `deck` 중심 상태를 `board`(3×3 블록키 `col:row` → 카드 id), `hand`(3장 기준), `gold`로 전환했다. `start_run()`은 군주 시작 카드를 보드에 순서대로 채우고 손패·골드를 비운다.
- **경제 API** — `place_from_hand`, `discard_from_hand`(+10골드), `hand_over_limit`, `board_card_ids`, `owned_card_ids`, `add_gold`, `spend_gold`를 순수·결정적으로 추가했다.
- **브리지 유지** — `RunManager.get_deck()`은 보드 카드만 반환해 기존 battle/run_map의 배치 소스를 유지한다. `RunManager.add_card()`는 빈 보드 블록에 우선 배치하고, 보드가 가득 차면 손패로 보낸다.
- **보상 기준** — `RewardPool.eligible/roll`은 `owned(board+hand)`를 받아 후보에서 제외한다. 보상 스모크도 owned 기준으로 갱신했다.
- **검증** — `test/test_run_board.gd` 신설(122단언), 기존 run 보상/맵 테스트 owned 기준 갱신. `./init.sh` 전체 green: 카드검증(10·1), sim 성 방어 승리 25.5s·성 노출 패배 29.0s, reward owned 7장·후보 3장, run_map/battle 부팅, 단위 16파일 541단언.
- **스코프** — 전투/씬/리소스(`scripts/battle/*`, `scripts/screens/*`, `scenes/*`, `resources/.tres`) 미수정. 전투 보드 스폰·UI·상점은 feat-015b/015c로 남긴다.

## 2026-05-31 — feat-018 타겟 AI 시스템 (done · Codex 구현)
- **TargetRules** — `scripts/battle/target_rules.gd`를 추가해 `nearest`·`backline`·`strongest_ranged`·`lowest_hp`·`highest_hp`를 순수 static 규칙으로 선택한다. 죽은 적은 제외하고, 동률은 2D 최근접으로 결정한다.
- **BattleSim** — `_nearest_enemy`를 `_pick_target`으로 일반화했다. 표적 우선순위는 장수 commanded_target > 도발 > `target_rule`이며, EventBus·렌더 호출 없이 결정적으로 유지한다.
- **데이터화** — `UnitCardData.target_rule`와 `CardVocab.TARGET_RULES`를 추가하고, 10개 카드 `.tres`와 `WaveFactory` 적 생성에 스펙 기본값을 지정했다. `validate_cards.gd`가 target_rule 허용값을 검증한다.
- **검증** — `test/test_target_rules.gd` 신설(17단언). `./init.sh` 전체 green: 카드검증(10·1), sim 성 방어 승리 25.5s(성HP 1200, 아군잔존 6)·성 노출 패배 29.0s, reward, run_map/battle 부팅, 단위 15파일 412단언.
- **스코프** — 전투 외 시스템(`scripts/run/*`, RunMap/RunManager, scenes/screens/*, RewardPool, TypeChart 규칙, SkillSystem 효과 규칙, battle.gd) 미수정.

## 2026-05-30 — feat-014 성(城) 방어 목표 (done · Codex 구현)
- **성 모델** — `BattleSim.add_castle()`가 플레이어 진영 맨 안쪽 `CASTLE_X=40`, 중앙 `FIELD_H/2`에 `BattleUnit` 성을 생성한다. 성은 `is_castle=true`, HP 1200, 공격 0, 이동속도 0, 병종 infantry로 둔다.
- **승패** — 성이 있는 전투는 성 파괴=PLAYER_LOSE, 적 군세 전멸(+대기 파도 없음)=PLAYER_WIN으로 판정한다. 성이 없는 시뮬레이션은 기존 아군 전멸 패배 동작을 유지한다.
- **타겟팅/행동** — 성은 `player_units`에 포함되어 적의 2D 최근접 표적이 된다. 성 자신은 step에서 이동·공격·스킬 처리를 하지 않는다.
- **전투 UI** — `battle.gd`가 standalone 부팅 시에도 성을 자동 배치하고 성 HP바를 표시한다. 기존 3×3 유닛 배치와 오픈필드 유닛 이동은 유지한다.
- **검증** — `test/test_castle.gd` 신설(27단언). `tools/sim_smoke.gd`를 성 방어 승리/성 노출 패배로 갱신. `./init.sh` 전체 green: 카드검증(10·1), sim 성 방어 승리 28.7s·성 노출 패배 29.0s, reward, run_map/battle 부팅, 단위 13파일 383단언.
- **스코프** — 전투 외 시스템(`scripts/run/*`, RunMap/RunManager, resources/.tres, scenes/screens/*, RewardPool, TypeChart 규칙, SkillSystem 효과 규칙) 미수정.

## 2026-05-30 — feat-013 오픈필드 난전 (done · Codex 구현)
- **방향 보정** — Nine Kings 실측 반영으로 feat-012의 컬럼 정적 방어를 폐기. 3×3은 전투 보드가 아니라 시작 진형으로 재해석한다.
- **BattleSim** — `FIELD_W=1000`, `FIELD_H=600`, `ROW_X=[360,240,120]`, `COL_Y=[150,300,450]`. `BattleUnit`에 `px/py`를 추가하고 호환 `x`는 `px`를 따른다. 양쪽 군세가 2D 최근접 적에게 이동·수렴하고, 사거리 안에서 교전한다.
- **승패** — 기지 도달/돌파 판정을 제거하고 군세 전멸 판정으로 전환. 적 전멸과 대기 파도 없음은 PLAYER_WIN, 아군 전멸은 PLAYER_LOSE. King HP는 feat-014로 남긴다.
- **스킬/상태/상성** — 상성표와 상태 효과 규칙은 유지. 타겟 질의만 2D화했다. 관우=최근접 2기, 황충=최원거리, 제갈량=대상 반경, 장비=주변 반경 도발·약화, 조운=전방 2D 경로 피해.
- **전투 UI** — `battle.gd`는 3×3 시작 진형 타일을 유지하되, 필드를 좌우 2D 공간으로 그려 유닛이 실제 `px/py`에 맞춰 이동한다. `battle.tscn` standalone 부팅 유지.
- **검증** — `test/test_openfield.gd` 신설, 기존 전투 테스트를 2D 오픈필드 기대값으로 갱신. `./init.sh` 전체 green: 카드검증(10·1), sim default_waves 승리 28.7s·무배치 패배 0.1s, reward, run_map/battle 부팅, 단위 12파일 356단언.
- **스코프** — 전투 외 시스템(`scripts/run/*`, RunMap/RunManager, resources/.tres, scenes/screens/*, RewardPool, TypeChart 규칙) 미수정.

## 2026-05-30 — 🔀 방향 전환: 레인 → 그리드 (Nine Kings 정합)
- **지적(사용자)** — 벤치마크 Nine Kings는 3×3 그리드에 유닛/건물을 배치해 파도를 막는 진형 방어인데, 현 빌드는 레인 tug-of-war(Kingdom Rush 결)로 이탈했다.
- **근본 원인(편집장 책임)** — 1주차 전투형태 질문이 "그리드↔수동", "자동↔레인"으로 잘못 묶어 NK의 "그리드+자동"을 깔끔히 제시 못함. 자동전투 선택은 맞았으나 공간 모델을 레인으로 잡은 게 이탈. NK를 미검증으로 "레인식"이라 단정한 게 뿌리.
- **결정** — 전장 모델을 그리드 배치로 전환(feat-012). 전투 모델/표현(BattleSim·battle.gd)만 재설계, 메타·카드·스킬·상성·상태 등 전투 외 전부 재사용. 롤백 체크포인트 `5b61aa1`(레인 모델 마지막).
- **구현(Codex)** — `BattleSim`을 3×3 컬럼/depth 모델로 전환. 기존 `lane`은 `col`, `x`는 `depth`로 재해석하고 `row` 필드를 추가했다. 아군은 배치 depth에 고정, 적만 컬럼을 따라 전진하며 빈 컬럼 돌파 시 패배한다.
- **전투 UI** — `battle.gd`는 카드 선택 → 3×3 타일 클릭 배치로 변경. `battle.tscn`은 노드 추가 없이 standalone 부팅을 유지한다.
- **스킬/상태/상성** — 5스킬·도발/약화·상성 배수는 유지하고 타겟 공간만 같은 컬럼 기준으로 갱신했다. 조운 돌진은 타일 고정 불변식을 지키기 위해 virtual path 피해로 처리한다.
- **검증** — `test/test_grid.gd` 신설, 기존 전투 테스트를 그리드 기대치로 갱신. `./init.sh` 전체 green: 카드검증(10·1), sim default_waves 승리·무배치 돌파 패배, reward, run_map/battle 부팅, 단위 11파일 275단언.
- **건물 카드** — NK 핵심 요소. feat-013에서 `card_type "building"` 추가 예정.
- feat-010 병종 상성·feat-011 상태이상(도발·약화)은 그 전에 done(259단언). 6국 캔온은 docs/worldview.md.

## 2026-05-29 — 하네스 구성
- `harness-start` 스킬로 5 서브시스템 하네스 구성 — CLAUDE.md·AGENTS.md·feature_list.json·progress.md·session-handoff.md·init.sh.
- v0.1 결정 확정 — 엔진 **Godot 4.x(GDScript)**, 전투 **오토배틀러**, **풀 판타지**, 제목 **삼국지: 구주쟁패**.
- 세계관 정본화 — `docs/worldview.md`. 三界(현세·천계·마계) × 3국 = 九州(9세력). 현세는 위·촉·오, 천계·마계 각 3국(명칭 잠정).
- `init.sh`를 Godot 검증(헤드리스 import + gdUnit4/GUT 테스트)으로 작성. Godot 4.6.3 설치 확인.
- v0.1 피처 5종 정의 — 프로젝트 셋업 → 카드 스키마 → 레인 오토배틀 코어 → 전리 보상 → 검증 커버리지.

## 2026-05-29 — feat-001 Godot 셋업 + feat-002 카드 스키마 (done)
- **feat-001** — Godot 4.x 프로젝트 골격. `project.godot`(이름·디스플레이 1920×1080·gl_compatibility), split 디렉토리 구조(assets/scenes/scripts/resources/tools/addons), `.gitattributes`, 오토로드 `GameManager`·`EventBus`. `./init.sh`에 헤드리스 데이터 검증 스텝 추가. Godot 4.6.3로 import 통과.
- **feat-002** — 카드 데이터 스키마. `CardData`(공통) → `UnitCardData`(전투 스탯) 상속, `LordData`(군주·시작 덱), `CardVocab`(허용 값 사전). 데이터는 `@export_enum` 문자열 + `PackedStringArray`로 .tres 가독성 확보. 촉(蜀) 샘플 — 군주 유비, 장수 관우·장비·제갈량, 병종 보병·궁병·기병.
- **검증 도구** — `tools/validate_cards.gd`(헤드리스 SceneTree). 모든 카드/군주 .tres를 로드해 필드·허용값·v0.1 덱 형태(장수3·병종3)를 검사. init.sh에서 자동 실행.
- 스코프 조정 — 테스트 애드온(gdUnit4/GUT) 설치를 feat-001 → feat-005로 이동(첫 테스트 작성 시점에 설치, 리포 비대 방지).
- 가정 — 시작 군주를 촉/유비로 선택(컨셉 예시가 모두 촉). 위/오 전환 가능.

## 2026-05-29 — feat-003 레인 + 오토배틀 코어 (done)
- **전투 로직/표현 분리** — `BattleSim`(RefCounted, 순수·결정적 step(delta))을 `battle.gd`(Control)가 _process로 구동. 로직을 헤드리스로 테스트 가능.
- `BattleUnit`(런타임 유닛), `WaveFactory`(적 파도 — 황건적 사령/요사를 BattleUnit으로 직접 생성, 카드 아님), `CardCatalog`(id→Resource 조회·유닛 빌드) 추가. `CardLibrary` 오토로드가 카탈로그를 감싸 게임에 제공.
- **승패 규칙** — 승=적 전멸, 패=적이 플레이어 기지(x≤0) 도달 또는 아군 전멸. 근접/원거리 사거리 분리(MELEE 36 / RANGED 280).
- **battle.tscn** = main_scene 지정. 배치 단계(카드별 1·2·3 레인 버튼 + 지휘력 12) → "전투 시작" → 오토배틀 시각화(유닛 ColorRect + HP바) → 승/패 표시.
- **LordData.trait_id 추가** — 유비 `trait_rende`(병종 시작 hp +15%)를 `CardCatalog.build_player_unit`에서 적용. 군주가 기계적으로 의미를 갖게 됨.
- **검증** — `tools/sim_smoke.gd`(헤드리스): 풀 덱이 파도1을 승리(19.2s 전원 생존), 무배치는 패배. init.sh에 시뮬 검증 + 메인 씬 부팅 스모크(--quit-after 30, 스크립트 에러 grep) 추가.
- 한계 — 클릭 배치 UI의 시각 동작은 헤드리스로 미검증(사용자 `godot .` 실행 필요). 보상은 feat-004.

## 2026-05-29 — feat-004 전리(보상) + v0.1 루프 완성 (done)
- **런 상태 도입** — `RunState`(덱·군주·파도, 순수) + `RewardPool`(후보 = 유닛카드 − 현재덱, eligible 결정적/roll 무작위) + `RunManager` 오토로드(씬 reload 넘어 덱 영속).
- **battle.gd 보상 루프** — 승리 시 후보 3장 제시 → 선택 시 덱 편입 → "다음 전투"(reload, RunManager가 덱 유지 → 보상 반영). 패배 시 "다시 시도"(런 리셋+reload). EventBus(battle_won/lost·card_rewarded) emit.
- **배치 소스 변경** — battle 패널이 LordData 시작덱 대신 `RunManager.get_deck()`(시작덱+보상)을 읽음.
- **신규 카드 4종(보상 풀)** — 조운(기병)·황충(궁병)·노병(crossbow)·수군(navy). cavalry/archer/crossbow/navy troop_type를 실데이터로 처음 사용. 카탈로그 6→10장.
- **검증** — `tools/reward_smoke.gd`: 시작덱 6 → 후보 4 → 1장 획득 → 덱 7·후보 3, 획득카드 후보 제외. init.sh에 보상 검증 추가. 전체 green.

## 2026-05-29 — 분업: 구현 Codex 외주 시작
- 사용자 지시로 구현을 Codex(5.5 xhigh)에 외주. Claude는 스펙·정본·검증, Codex는 샌드박스(workspace-write) 구현.
- **feat-005는 GUT 대신 리포 내장 테스트 하네스로 선회** — 외부 레포 반입(`--dangerously-bypass...`, GUT git clone→addons)이 안전 게이트에 차단됨. 기존 `*_smoke.gd` 패턴을 정식 하네스(TestCase+runner)로 일반화. 스펙은 `docs/specs/feat-005.md`.

## 2026-05-29 — feat-005 검증 커버리지 (done · Codex 구현)
- **내장 테스트 하네스** — `test/test_case.gd`(TestCase 단언 베이스 — eq/ne/truthy/falsy/is_null/not_null/almost) + `test/runner.gd`(`test_*.gd` 자동 수집·실행, 실패 시 `quit(1)`).
- **단위 테스트 4파일 60 단언** — battle_unit(20)·battle_sim(11)·card_catalog(15)·run_reward(14). BattleUnit/BattleSim/CardCatalog/RunState/RewardPool 순수 로직 커버.
- **init.sh** — 내장 러너 분기 추가. Godot HOME/로그 경로를 `.godot/` 아래로 고정(샌드박스 `user://` 쓰기 경고 회피). 실패 전파 확인(임시 실패 테스트 → INIT_STATUS=1, 이후 제거).
- **편집장 독립 검증** — `./init.sh` 전체 green 재현, 프로덕션 코드(scripts/resources/scenes/project.godot) 미수정 확인(mtime 검사).
- 외주 — Codex `gpt-5.5` xhigh, 샌드박스 `workspace-write`. 네트워크·서드파티 0.

## 2026-05-30 — feat-006 다중 파도 (done · Codex 구현, v0.2 시작)
- **BattleSim 파도 큐** — `pending_waves`·`wave_index`·`wave_total`·`set_waves()`·`_spawn_next_wave()`. 현재 파도 전멸 시 대기 파도 즉시 스폰, **마지막 파도 이후에만 PLAYER_WIN**. 단일 파도(add_unit) 경로 보존.
- **wave_factory** — `default_waves()` 3파도(증원·요사 궁수·정예 "마군 정예"로 점증). `wave_one()` 유지.
- **battle.gd** — `set_waves(default_waves())`, 새 파도 유닛 자동 시각화(`_sync_visuals` active-set 방식), `파도 N / M` 표시. 생존 유닛 HP 이어짐(회복 없음).
- **검증** — Codex TDD(RED→GREEN). `test/test_multiwave.gd` 16단언. `./init.sh` 76단언(60+16) green, 회귀 0. 편집장 독립 재검증 + git diff 스코프 확인(battle 3파일+테스트만).
- 외주 — Codex `gpt-5.5` xhigh 샌드박스. 밸런스는 임시.

## 2026-05-30 — feat-007 로그라이크 맵 (done · Codex 구현)
- **RunMap 도입** — `scripts/run/run_map.gd`(RefCounted)로 BATTLE/ELITE/BOSS 노드, 결정적 seed 생성, choose/complete/finished API를 구현. 3개 선택 막(각 2노드) + 보스 막(1노드).
- **런 통합** — `RunState.map`과 `RunManager` 위임 API(`available_nodes`, `choose_node`, `complete_node`, `active_node_type`, `map_finished`, `reset_run`) 추가. 이미 시작한 런은 맵을 재생성하지 않는다.
- **전투 흐름 변경** — `WaveFactory.waves_for_node()`로 일반/정예/보스 파도를 선택. battle 승리 후 보상 선택 → 노드 완료 → 지도 복귀 또는 "구주 정복!", 패배는 런 리셋 후 지도 복귀.
- **메인 씬 변경** — `run_map.tscn`이 main_scene. 맵 화면은 현재 막만 클릭 가능하고 덱 크기·현재 막을 표시한다. `battle.tscn`은 노드 없이 standalone 부팅 시 기본 파도를 사용한다.
- **검증** — TDD RED 확인 후 `test/test_run_map.gd` 20단언 추가. `./init.sh` 전체 green: 카드/군주·sim·reward 스모크, run_map/battle 각각 30프레임 부팅, 6파일 96단언 통과.

## 2026-05-30 — feat-010 병종 상성 + 九州 6국 캔온 (done · Codex 구현)
- **TypeChart** — 상성 삼각(보병>기병>궁병/노병>보병), STRONG 1.5 / WEAK 0.75 / NEUTRAL 1.0. 수군·판타지 중립.
- **BattleUnit.troop_type** + from_card 운반, WaveFactory 적 병종 지정(사령병 infantry·요사 궁수 archer·마군 정예 cavalry), BattleSim 일반공격에만 배수 적용(스킬 피해 평면 유지).
- **WaveFactory 확장** — waves_for_node(BATTLE/ELITE/BOSS), elite_waves(스케일링), boss_waves(마왕 동탁 2300hp + 호위). (feat-007 이후 노드별 파도 정착.)
- **검증** — Codex TDD. test_type_chart 60단언. ./init.sh 236단언(176+60) green, 회귀 0. 승리 스모크 14.2→13.1s. 편집장 독립 재검증 + git diff 스코프.
- **세계관 캔온(편집장)** — `docs/worldview.md`에 九州 6국 제안 정본화. 천계(곤륜선맹·봉래방사·자미성궁/남화노선·우길·좌자)·마계(황천교·낙양마궁·만요동천/장각·동탁·구려요왕). 현재 적 사령병=황천교. nation id는 v0.6에서 CardVocab 추가. (사용자 승인 대기.)

## 2026-05-30 — feat-009 장수 스킬 발동 (done · Codex 구현, v0.3 시작)
- **SkillSystem** — 코드 레지스트리(class_name). 5장수 결정적 스킬 — 관우 일섬(가까운 2적 80)·황충 백보천양(먼 적 110)·제갈량 팔진도(레인 전체 45)·조운 단기필마(220 돌진+경로 60)·장비 호통(전체 25+자가회복 80), 쿨다운 표대로.
- **BattleUnit** — skill_id·skill_cooldown 보유, from_card가 .tres skill_id 운반. 데이터 스키마·카드 .tres 불변(skill_id를 코드에서 해석).
- **BattleSim** — add_unit 첫 쿨다운, step 발동, `last_skill_casts` 기록(순수 유지 — EventBus·렌더 호출 없음). battle.gd가 기록 읽어 시전자 0.15s 플래시.
- **검증** — Codex TDD. test_skills 51단언. ./init.sh 176단언(125+51) green, 회귀 0. 승리 스모크 19.2→14.2s(스킬 실발동 신호). 편집장 독립 재검증 + git diff 스코프.
- 임시 — 장비 호통은 데미지+자가회복 placeholder, 진짜 도발은 feat-011 상태 시스템에서 교체.

## 2026-05-30 — feat-008 맵 노드 다양화 (done · Codex 구현, v0.2 완성)
- **RunMap NodeType 5종** — BATTLE/ELITE/REWARD/SUPPLY/BOSS, 가중 생성(전투 우세), `is_battle()` 헬퍼. 전투 노드만 battle.tscn으로.
- **런 지휘력** — `RunState.command_points`(기본 12) + `RunManager` 위임. `battle.gd`가 const 대신 런 지휘력을 배치 한도로 사용(standalone 12 안전).
- **비전투 노드** — REWARD(전투 없이 카드 +1, RewardPool 재사용)·SUPPLY(지휘력 영구 +3)를 맵 화면 오버레이로 해결 후 막 진행. 덱 압축은 배치 모델상 효과가 약해 제외.
- **검증** — Codex TDD. `test/test_map_nodes.gd` 29단언. `./init.sh` 125단언(96+29) green, 회귀 0. 편집장 독립 재검증 + git diff 스코프 확인.
- v0.2(다중 파도 + 로그라이크 맵 + 노드 다양화) 골격 완성. 로드맵 정본화 — `docs/roadmap.md`.

## 2026-05-29 — v0.1 코드 완성
- v0.1 5피처(셋업·카드 스키마·오토배틀 코어·전리 보상·검증 커버리지) 전부 done. `./init.sh` 한 방으로 import + 데이터/전투/보상 스모크 + 씬 부팅 + 60 단언 단위 테스트가 모두 통과.
- 잔여 — 시각 플레이 QA(클릭 배치→전투→보상→다음 전투)는 화면 실행으로 사람/agy 확인 필요. 아직 커밋 0(체크포인트 권장).
