# 애셋 매니페스트 — v0.5 "구주 비주얼 전장"

agy(생성)와 Codex(참조)가 공유하는 단일 계약이다. Codex는 이 경로를 코드에서 참조하고(없으면 placeholder 색으로 폴백), agy 생성물은 Claude가 후처리해 이 경로에 채운다. 자세한 생성 절차는 메모리 `agy-image-pipeline` 참조.

## 스타일
- **리치 픽셀아트** — Nine Kings 톤, 더 정교한 픽셀. 손그림 픽셀 느낌, 굵은 외곽선 지양, 제한 팔레트.
- **진영 팔레트**
  - 촉(蜀, 현세·아군) — 옥록(jade green) 기조 + 청동·금 악센트. 군기 녹색.
  - 마계(魔界·적·보스) — 자주·심홍 기조 + 흑요 그림자, 병적 보라 발광.
  - 중립·UI — 양피지(parchment), 먹(ink), 금(gold).
- **배경** — 자유모드 기본 테마 = 삼국지 평원 진영. 스테이지/시나리오별 교체형(아래 테마 슬롯).

## 생성 파이프라인 (요약)
1. agy `generate_image` → 1024² JPEG(알파 없음) → brain 디렉토리.
2. **스프라이트류는 순마젠타 `#FF00FF` 단색 배경에 생성**하도록 프롬프트 → Claude가 PIL로 키 아웃→알파→오토크롭→다운스케일→투명 PNG.
3. **배경류는 키잉 없이** 리사이즈/크롭만.
4. Claude가 아래 경로로 배치 → `godot --headless --import`.

## 우선순위 티어
- **T1 (필수, 비주얼 임팩트 최대)** — 평원 배경, 보스(마왕 동탁), 아이소 지면 타일, 성(城).
- **T2 (핵심)** — 건물 2종, 잡병 스프라이트(아군·적 각 1~2종), 자원·속도·사다리 UI 아이콘.
- **T3 (충실도)** — 장수 4종 개별 스프라이트, 진영별 전 병종, 데코·파티클, 능력 버튼 아이콘.
T1이 비면 화면이 안 산다. T2까지면 첨부 수준. T3는 점진 채움. 누락분은 Codex placeholder가 덮는다.

## 애셋 목록

### 배경 (alpha 불필요, 직접 사용) — `assets/sprites/bg/<theme>/`
| 파일 | 크기 | 용도 | 티어 |
|---|---|---|---|
| `bg/plain/sky.png` | 1920×640 | 평원 하늘·원경 산 | T1 |
| `bg/plain/ground.png` | 1920×760 | 풀밭 지면(가로 타일 가능) | T1 |
| `bg/plain/decor.png` | 1920×400 | 목책·군기·막사·나무 중경(투명 PNG, 크로마키) | T2 |
> 테마 추가 시 `bg/<theme>/` 폴더에 같은 3파일. 테마 등록은 `BattlefieldTheme`(feat-025).

### 아이소 기지 — `assets/sprites/iso/`, 건물 — `assets/sprites/buildings/`
| 파일 | 크기(투명) | 앵커 | 용도 | 티어 |
|---|---|---|---|---|
| `iso/tile_grass.png` | 128×64 | center | 아이소 다이아몬드 지면 타일(2:1) | T1 |
| `iso/tile_grass_hl.png` | 128×64 | center | 배치 가능 하이라이트 타일 | T2 |
| `buildings/castle.png` | 128×160 | bottom-center | 성채 탑(아군 본진, HP 목표) | T1 |
| `buildings/farm.png` | 96×96 | bottom-center | 둔전(屯田) — 골드 생산 | T2 |
| `buildings/tower.png` | 96×128 | bottom-center | 망루(望樓) — 인접 오라 | T2 |

### 유닛 — `assets/sprites/units/<faction>/`  (faction = shu | demon)
사이드뷰, **오른쪽 보기**(적은 엔진에서 flip_h). 발밑 앵커. 다운스케일 후 픽셀.
| 파일 | 크기(투명) | 용도 | 티어 |
|---|---|---|---|
| `units/shu/infantry.png` | 48×56 | 보병 | T2 |
| `units/shu/archer.png` | 48×56 | 궁병 | T2 |
| `units/shu/cavalry.png` | 64×56 | 기병 | T3 |
| `units/shu/crossbow.png` | 48×56 | 노병 | T3 |
| `units/shu/navy.png` | 48×56 | 수군 | T3 |
| `units/shu/general_zhaoyun.png` | 56×64 | 조운(장수) | T3 |
| `units/shu/general_huangzhong.png` | 56×64 | 황충 | T3 |
| `units/shu/general_zhugeliang.png` | 56×64 | 제갈량 | T3 |
| `units/shu/general_zhangfei.png` | 56×64 | 장비 | T3 |
| `units/demon/infantry.png` | 48×56 | 사령병 | T2 |
| `units/demon/archer.png` | 48×56 | 요사 궁수 | T2 |
| `units/demon/cavalry.png` | 64×56 | 마군 정예 | T3 |
| `units/demon/boss_dongzhuo.png` | 160×192 | 마왕 동탁(대형 보스) | T1 |
> 진영별 전 병종이 안 차면, 같은 faction의 `infantry.png`를 `modulate`로 임시 대체(Codex 폴백).

#### 유닛 애니메이션 시트
`<unit>_walk.png`는 같은 폴더의 `<unit>.png` 옆에 둔다. 가로 4프레임 균등 스트립이며 프레임 폭은 `sheet_width / 4`, 높이는 시트 전체 높이다. 예: `units/shu/infantry_walk.png`는 1024×512 투명 PNG이고 256×512 프레임 4개(x=0/256/512/768)를 `walk` 애니메이션으로 재생한다. 누락된 유닛은 정적 `<unit>.png` 렌더링을 유지한다.

### UI — `assets/sprites/ui/`  (alpha 필요, 크로마키 또는 Codex 테마)
| 파일 | 크기 | 용도 | 티어 |
|---|---|---|---|
| `ui/icon_gold.png` | 32×32 | 자원 카운터 아이콘 | T2 |
| `ui/spd_pause.png` `spd_play.png` `spd_x2.png` `spd_x3.png` `spd_auto.png` | 32×32 | 속도 컨트롤 | T2 |
| `ui/node_combat.png` `node_shop.png` `node_boss.png` `node_expand.png` | 32×32 | 스테이지 사다리 노드 | T2 |
| `ui/ability_well.png` `ability_focus.png` | 48×48 | 능력 버튼 | T3 |
| `ui/panel_frame.png` | 9-slice | 패널·바 프레임(양피지) | T3 |
> UI는 생성 신뢰도가 낮다. **Codex가 GDScript Theme로 기본 룩을 잡고**, 위 아이콘만 생성 이미지로 교체. 누락 시 텍스트/도형 폴백.

### 폰트 — `assets/fonts/`
| 파일 | 용도 | 티어 |
|---|---|---|
| `fonts/pixel.ttf` | 데미지 숫자·HUD 픽셀 폰트(무료 픽셀 폰트 반입 또는 기존 폰트) | T2 |

## 네이밍·규칙
- 소문자 snake_case, 위 경로 고정. PNG(투명) 기본, 배경은 PNG 무알파 허용.
- 유닛은 **발밑 앵커**(Y정렬용). 건물·성도 bottom-center. 아이소 타일은 center.
- Codex는 텍스처 로드 실패를 **반드시 폴백 처리**(placeholder 색) — 애셋 0/부분 상태에서도 `./init.sh`·씬 부팅 통과.
