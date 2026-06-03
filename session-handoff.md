# 세션 핸드오프

작업이 끊겼거나 `progress.md`에 담기 너무 클 때 쓴다. 큰 증거는 링크.

## 현재 상태 (2026-06-03)
- **v0.5 "구주 비주얼 전장" 완료** — 아이소 렌더·HUD·데미지·배경테마·건물경제. `./init.sh` **723 단언 green**.
- **마누스 페인터리 풀세트** — 9세력 T0-T2, 93종. 아트 픽셀→페인터리. 발주서 `docs/asset-production-brief.md`.
- **상점(015d)·3진영(촉/위/오, 026)** 플레이. 군주 선택(lord_select=main_scene), faction-aware 렌더.
- **feat-027 agy 그래픽 보정 done (이번 세션)** — 위·오 **17종** agy 강화(모양 유지·채도·대비·진영톤·림라이트). 인게임 QA 약점 식별→agy 보정→PIL 키아웃→배치.
- **렌더 스케일업 done (이번 세션)** — `battle.gd` 뷰 상수 상향(UNIT_W 108→140·GENERAL 124→162·BOSS 182→204·성·건물), 한산함 해소·유닛 존재감↑. BattleSim 불변. `./init.sh` 723 green·회귀 없음.
- **GitHub** — `sgeniusk/guju-jaengpae`(public), main 추적. **커밋됨** — e858d95(위·오 강화)·6cdffaf(렌더 스케일). 푸시는 사용자 확인 전(미푸시).

## 사용자 결정
- 마누스 아트는 현 상태 유지, **부족분만 agy 보정**(feat-027에서 위·오 색·대비 강화 실행).
- 부족분 보정·애니메이션화는 agy 배정.

## 잔여 (agy 할당량 대기 — ~3시간)
agy 이미지 모델이 `429 RESOURCE_EXHAUSTED`(이번 세션 소진, ~3시간 후 리셋). 할당량 회복 후:
1. **주유 강화** — `wu/general_zhouyu` 1종(위·오 중 유일 미강화). 오=주홍+청동·warm 림 프롬프트로 강화→키잉(`/tmp/agy_keyout.py`, h=256)→`assets/sprites/units/wu/general_zhouyu.png` 배치. 그러면 위·오 18종 완전 강화.
2. **촉 진영 강화 (선택)** — 촉 12종(infantry·archer·cavalry·crossbow·navy·general 7)을 같은 방식으로. 촉=옥록 기조. QA상 촉은 방향 OK라 우선순위 낮음.
패턴 — `/tmp/agy_enhance_batch.sh` 구조(진영톤 변수+agy 순차+경로 grep+키잉). **렌더 스케일업은 done**(커밋 6cdffaf).

## ⚠️ agy 자율편집 함정 (이번 세션 발견)
`agy -p '...' --add-dir <repo> --dangerously-skip-permissions` 호출 시 agy가 이미지 생성만 하지 않고 **repo 파일(`feature_list.json`·`progress.md`)을 에이전트로서 자율 편집**한다(이번에 evidence·진행중 줄을 임의로 씀, 원복함). cache/ 부산물도 생김(.gitignore 추가됨). 다음 배치는 프롬프트에 "generate the image only, do NOT modify any repo files" 명시하거나 --add-dir 범위를 입력 이미지로 좁힌다. **검증됨** — 주유 재시도 시 `--add-dir <repo>/assets/sprites/units`로 좁히고 프롬프트 명시 → agy가 "no other files were modified" 보고(방지 성공).

## 다음 후보 (feat-027 잔여 후)
- feat-028 유닛 애니메이션 (agy 스프라이트 시트→Godot AnimatedSprite2D)
- feat-029 위·오 trait 실효과 + 장수 스킬 (편집장 설계→Codex)
- 평원 배경 사용자 미드저니 교체 (`assets/sprites/bg/plain/field.png` 1920×1080)
- feat-020 땅 확장 / feat-021 왕의 칙령

## 멀티 CLI 워크플로
Claude(편집장·스펙/정본/QA) → Codex(GDScript 구현) → agy(애셋 생성/보정/시트) → Claude(수거·정본·커밋). 시각 QA — `tools/shoot_battle.gd`(LORD·SHOOT_STAGE 환경변수)·shoot_shop·shoot_scene. 비헤드리스 `godot --path . res://tools/<X>.tscn`, 결과 /tmp/shot_*.png. agy 수거 — 마젠타 키아웃→autocrop→다운스케일(`asset_pipeline.py` chroma 로직). **HOME 함정** — godot용 `export HOME=.godot/home`과 PIL python을 한 셸에서 섞으면 `ModuleNotFoundError: PIL`(user-site). 키잉은 원 HOME, godot만 서브셸 격리. 푸시는 사용자 확인 후.

## 다음 세션 시작 프롬프트 (복사)
> 구주쟁패 이어서 작업한다. 상태 — v0.5+마누스 풀세트+상점+3진영, feat-027 agy 그래픽 보정 done(위·오 17종 강화), ./init.sh 723 green. 미커밋 — feat-027 강화 17종+상태파일. `session-handoff.md`·`feature_list.json`·`progress.md` 읽고 ./init.sh 확인 후, 다음 중 — ① feat-027 잔여(주유 1종 agy 할당량 리셋 후 강화) ② 렌더 스케일업 Codex 위임(UNIT_W↑) ③ feat-028 애니메이션 ④ feat-029 위·오 trait/스킬 ⑤ 평원 배경 미드저니 교체 ⑥ feat-020/021. ⚠️ agy는 --add-dir+skip-permissions 시 repo 파일 자율편집하니 "이미지만 생성" 명시. 멀티 CLI 분업 유지.

## 알려진 사소 이슈
- `init.sh` 부팅 스모크 라벨이 "run_map.tscn" 고정인데 실제 main_scene은 lord_select. 혼동만, 무관.
- 위·오 trait(호패·수전) 플레이버 no-op, 위·오 장수 스킬 없음(feat-029).
- docs/reports/v0.5-screens/*.png.import — godot import 부산물(미추적). 무해.
