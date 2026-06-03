# 세션 핸드오프

작업이 끊겼거나 `progress.md`에 담기 너무 클 때 쓴다. 큰 증거는 링크.

## 현재 상태 (2026-06-03)
- **v0.5 "구주 비주얼 전장" 완료** — 아이소 렌더·HUD·데미지·배경테마·건물경제. `./init.sh` **723 단언 green**.
- **마누스 페인터리 풀세트** — 9세력 T0-T2, 93종. 아트 픽셀→페인터리. 발주서 `docs/asset-production-brief.md`.
- **상점(015d)·3진영(촉/위/오, 026)** 플레이. 군주 선택(lord_select=main_scene), faction-aware 렌더.
- **feat-027 agy 그래픽 보정 done (이번 세션)** — 위·오 **17종**을 agy image-to-image로 강화(모양 유지·채도·대비·진영톤·림라이트, 리컬러 아님). 인게임 QA 약점 식별→agy 보정→PIL 키아웃→배치. ./init.sh 723 green·회귀 없음. CHANGELOG 2026-06-03.
- **GitHub** — `sgeniusk/guju-jaengpae`(public), main 추적. **feat-027 강화 17종 + 상태파일 미커밋**(working tree M 상태).

## 사용자 결정
- 마누스 아트는 현 상태 유지, **부족분만 agy 보정**(feat-027에서 위·오 색·대비 강화 실행).
- 부족분 보정·애니메이션화는 agy 배정.

## feat-027 잔여 (다음 세션 우선)
1. **주유 강화** — `wu/general_zhouyu` 1종이 agy 할당량 초과로 미완. 리셋(~4시간+) 후 나머지와 동일 프롬프트(오=주홍+청동·warm 림)로 강화→키잉→배치. 패턴은 CHANGELOG 2026-06-03·메모리 `agy-image-pipeline` 참조.
2. **렌더 스케일업 (Codex 위임)** — 강화 스프라이트가 작은 스케일에서 빛나려면 `battle.gd UNIT_W 108→~140·GENERAL_W 124→~160` + 유닛 밀도. 유닛은 modulate WHITE라 색 안 죽임 — 작아서 한산한 게 핵심 약점. 편집장 스펙→Codex.

## ⚠️ agy 자율편집 함정 (이번 세션 발견)
`agy -p '...' --add-dir <repo> --dangerously-skip-permissions` 호출 시 agy가 이미지 생성만 하지 않고 **repo 파일(`feature_list.json`·`progress.md`)을 에이전트로서 자율 편집**한다(이번에 evidence·진행중 줄을 임의로 씀, 원복함). cache/ 부산물도 생김(.gitignore 추가됨). 다음 배치는 프롬프트에 "generate the image only, do NOT modify any repo files" 명시하거나 --add-dir 범위를 입력 이미지로 좁힌다.

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
