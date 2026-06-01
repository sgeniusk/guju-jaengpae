# 전투 화면 렌더 아키텍처 — v0.5 "구주 비주얼 전장"

Codex가 이 문서를 구현 기준으로 삼는다. 핵심 불변식 — **`BattleSim`(순수 2D 로직)은 절대 수정하지 않는다.** 좌표·승패·스킬·상성은 그대로 두고, 시각화는 전적으로 뷰 레이어가 한다. 뷰는 매 프레임 sim 상태를 읽어 스프라이트를 배치한다(현 `battle.gd` `_sync_visuals` 패턴 계승).

## 논리 좌표 (BattleSim — 불변)
- 전장 = `FIELD_W=1000`(가로·깊이) × `FIELD_H=600`(세로·레인). [scripts/battle/battle_sim.gd](../scripts/battle/battle_sim.gd):10-16.
- 성(城) `(40, 300)` 좌측 고정. 아군 시작 `px≈120~360`(좌중). 적 스폰 `px=1000`(우). 즉 **px 작을수록 좌(아군·성), 클수록 우(적·보스)** — 첨부 화면 구도와 일치.
- 레인 3개 `COL_Y=[150,300,450]`, 배치 깊이 `ROW_X=[360,240,120]`.
- 유닛은 연속 `px,py`로 이동·수렴해 난전. 성·건물 오라는 sim 밖(아래 feat-016).

## 단일 투영 계약 (모든 배치의 기준)
좌표 변환은 **딱 하나의 함수**로 통일한다. 유닛·타일·건물·성·VFX 전부 이 함수를 거친다.

```gdscript
# 논리 (px:0..1000 깊이, py:0..600 레인) → 월드 화면 좌표
func field_to_screen(px: float, py: float) -> Vector2:
    return VIEW_ORIGIN + Vector2(px * VIEW_SCALE_X, py * VIEW_SCALE_Y)
```
- `VIEW_ORIGIN`·`VIEW_SCALE_X`·`VIEW_SCALE_Y`는 1920×1080 뷰포트를 채우도록 Codex가 튜닝(세로는 압축해 지면 원근감).
- **깊이 정렬(Y-sort)** — 키 = `py`(그 다음 `px`). py 큰(앞쪽 레인) 유닛이 앞에 그려진다. `UnitsLayer.y_sort_enabled = true` + 스프라이트 `position.y`를 py에 비례시켜 자동 정렬.
- 스프라이트 앵커 = **발밑(bottom-center)**. 즉 `field_to_screen`이 유닛의 발 위치, 스프라이트는 그 위로 솟음.

## 노드 트리 (battle.tscn 재구성)
현 `battle.gd`는 전부 `Control`. 카메라·Y정렬·픽셀 스프라이트를 위해 **Node2D 월드 + CanvasLayer HUD**로 가른다.

```
Battle (Control 루트 — 씬 진입점 유지, _ready/_process/_input 골격 계승)
├─ WorldRoot (Node2D)                  # 카메라가 비추는 게임 월드
│  ├─ Camera2D                         # 전장 프레이밍, pixel-snap, 약한 줌
│  ├─ BackgroundLayer (Node2D/Parallax)# 교체형 배경 테마(feat-025). 하늘·지면·데코 레이어
│  ├─ IsoBaseLayer (Node2D)            # 좌측 기지 — 3×3 아이소 다이아몬드 타일 + 성 + 건물
│  ├─ UnitsLayer (Node2D, y_sort)      # 빌보드 픽셀 스프라이트(아군·적·보스). py로 깊이 정렬
│  └─ VfxLayer (Node2D)                # 데미지 숫자·타격 플래시·스킬 이펙트(feat-024)
└─ HUD (CanvasLayer)                   # 스크린 고정 UI
   ├─ TopLeft   — 자원 카운터(골드 + 아이콘)
   ├─ TopCenter — 스테이지 사다리(StageCadence 주도, N년)
   ├─ TopRight  — 속도 컨트롤(auto·pause·×1/×2/×3)
   ├─ LeftBar   — 능력 버튼 4개(우물·집중표적·예약2)
   ├─ BottomBars— 3중 진행바(성 HP·보스 HP·적 군세 잔존)
   └─ DeployPanel — 기존 손패·보드·배치·결과 UI(테마 적용, 현 _build_panel 이식)
```

## 아이소 기지 (IsoBaseLayer)
- 3×3 보드 타일을 **아이소 다이아몬드**로 그린다. 다이아몬드 = `field_to_screen(타일중심)` 주위 4점(2:1, 반폭 64·반높이 32). 타일 텍스처는 매니페스트 `iso_tile_*`.
- 성은 맨 좌측(px=40) 다이아몬드 위, 건물(feat-016)·배치 유닛은 각 타일 위에 발밑 앵커로 안착.
- **배치 단계** — 유닛 스프라이트가 아이소 타일 위에 정렬. **전투 시작** — 유닛은 sim의 `px,py`를 따라 우측 개활지로 진군(UnitsLayer가 매 프레임 따라감), 건물·성은 기지에 잔류. 첨부 화면 구도 그대로.

## 유닛 렌더 (UnitsLayer)
- 현 `_spawn_visual`(ColorRect)를 **Sprite2D 기반 노드**로 교체. 노드 = `Sprite2D`(몸체) + 작은 HP바(ColorRect 유지 가능) + 표적 마커 + 선택적 이름.
- 텍스처 = 매니페스트 경로(`assets/sprites/units/...`). **애셋 없으면 폴백** — 단색 사각(현 색 규칙) 또는 `modulate`로 진영색. 헤드리스/애셋 0 상태에서도 부팅·테스트 통과해야 함.
- 진영색 — 아군(촉) 옥록, 적(마계) 자주. 팔레트 스왑은 진영별 파일 또는 `modulate`.
- 적 스프라이트는 `flip_h`로 좌향. 보스(마왕 동탁)는 **대형 스프라이트**로 구분.
- 공격·피격·스킬 시 트윈/플래시(feat-024).

## HUD (CanvasLayer) — feat-023
- **3중 진행바(하단)** — ① 아군 성 HP(`sim.castle.hp_ratio`) ② 보스/챔피언 HP(보스 유닛 존재 시, 없으면 숨김/비활성) ③ 적 군세 잔존(남은 적 수 / 그 파도 최대, 또는 파도 진행). 첨부의 `무의 왕 / 무의 챔피언 / 무의 반란`에 대응.
- **스테이지 사다리(상단중앙)** — `StageCadence`로 현재~+N 스테이지 노드 렌더. 아이콘 = 전투/상점(is_shop)/보스왕관(is_boss)/확장(is_expand). 현재 위치 하이라이트, "N년" 플레이버(stage→년 매핑, 예 시작 33년 + stage).
- **자원 카운터(좌상)** — 골드 + 코인 아이콘. `RunManager.get_gold()`.
- **속도 컨트롤(우상)** — pause 토글 + 배속 ×1/×2/×3(델타 곱). "auto"는 토글 라벨(최소; 자동 다음-스테이지 등 후속). `_process`의 `_sim.step(delta)`를 `_sim.step(delta * _speed)` + pause 가드로.
- **능력 버튼(좌세로 4개)** — 우물(+10골드, 현 `_on_well_pressed` 이식)·집중표적 토글(현 마우스 홀드 로직 래핑)·예약2(비활성 슬롯). 원형 아이콘.
- **배치 패널** — 현 `_build_panel`/손패/보드/결과 오버레이를 HUD 하위로 이식, 테마 적용.

## 배경 테마 시스템 (feat-025) — 모드-레디
- `BattlefieldTheme`(Resource 또는 dict) — `{ id, sky, ground, decor, ambient_color }`. `BackgroundLayer`가 테마를 받아 레이어 텍스처를 세팅.
- 선택 = 스테이지/모드 키. 현재(자유모드) 기본 = `plain`(삼국지 평원 진영). 시나리오 모드(향후)는 시나리오별 테마.
- 단일 고정 배경 아님 — **슬롯**이다. 테마 추가 = 매니페스트에 텍스처 + 테마 등록만.

## 게임 모드 (향후 메타 — 이번 미구현, 설계만 대비)
사용자 구상 — **시나리오·자유·멀티** 3모드. 현재 런 = 사실상 자유모드(선형 스테이지 사다리). 배경 테마·스테이지 시스템을 모드 키로 분기 가능하게 두되, 모드 선택 UI·시나리오 데이터·멀티는 이번 범위 밖. [docs/design-loop.md](design-loop.md) 메타 노트 참조.

## 검증
- 각 단계 후 `./init.sh` green(기존 단언 유지 + 신규). 애셋 0/placeholder 상태에서도 씬 부팅 무에러.
- `BattleSim`·기존 전투 테스트 회귀 없음(뷰만 변경했으므로 당연).
- 시각 QA(feat-025 후) — `godot --path .` 실행 스크린샷을 첨부 레퍼런스와 비교.
