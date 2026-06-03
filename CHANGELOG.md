# CHANGELOG — 삼국지: 구주쟁패 (九州爭霸)

구조 변경(새 씬·새 시스템·개념 개명·정본 결정)을 기록한다. 일상 진행은 `progress.md`.

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
